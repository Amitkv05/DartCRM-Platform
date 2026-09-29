import bcrypt from "bcrypt";
import { db, withTransaction } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { getNextEligibleApprover } from "../../services/hierarchy.service.js";
import { createNotification } from "../../services/notification.service.js";
import { reassignAdminRequestHistory } from "../../services/admin-audit.service.js";

function intList(value) {
  return Array.isArray(value)
    ? [...new Set(value.map(Number).filter(Number.isInteger))]
    : [];
}

async function loadProfile(profileId, executor = db) {
  const [rows] = await executor.execute(
    "SELECT id, code, name, level_rank, is_admin, is_active FROM profiles WHERE id=? LIMIT 1",
    [profileId]
  );
  const profile = rows[0];
  if (!profile || Number(profile.is_active) !== 1) throw new AppError("Invalid or inactive profile", 400);
  return profile;
}

async function validateManager({ targetExecutiveId = null, profile, managerExecutiveId = null }, executor = db) {
  if (Number(profile.is_admin) === 1) {
    if (managerExecutiveId != null) throw new AppError("Admin profile must not report to another executive", 400);
    return;
  }
  if (managerExecutiveId == null) throw new AppError("Reporting manager is required for non-admin executives", 400);
  if (targetExecutiveId != null && Number(targetExecutiveId) === Number(managerExecutiveId)) {
    throw new AppError("An executive cannot report to themselves", 400);
  }
  const [rows] = await executor.execute(
    `SELECT e.id, e.manager_executive_id, e.status, p.level_rank, p.is_admin
     FROM executives e JOIN profiles p ON p.id=e.profile_id WHERE e.id=? LIMIT 1`,
    [managerExecutiveId]
  );
  const manager = rows[0];
  if (!manager || manager.status !== "ACTIVE") throw new AppError("Reporting manager must be an active executive", 400);
  if (Number(manager.is_admin) !== 1 && Number(manager.level_rank) <= Number(profile.level_rank)) {
    throw new AppError("Reporting manager must be at a higher level", 400);
  }

  // Prevent manager cycles on update.
  let cursor = manager;
  const visited = new Set();
  while (cursor?.manager_executive_id != null) {
    if (targetExecutiveId != null && Number(cursor.manager_executive_id) === Number(targetExecutiveId)) {
      throw new AppError("Reporting hierarchy would create a cycle", 409);
    }
    if (visited.has(Number(cursor.manager_executive_id))) break;
    visited.add(Number(cursor.manager_executive_id));
    const [nextRows] = await executor.execute(
      "SELECT id, manager_executive_id FROM executives WHERE id=? LIMIT 1",
      [cursor.manager_executive_id]
    );
    cursor = nextRows[0];
  }
}

async function replaceMappings(connection, table, idColumn, executiveId, ids) {
  await connection.execute(`DELETE FROM ${table} WHERE executive_id=?`, [executiveId]);
  for (const id of ids) {
    await connection.execute(
      `INSERT INTO ${table} (executive_id, ${idColumn}) VALUES (?, ?)`,
      [executiveId, id]
    );
  }
}

async function applyCustomMenus(connection, executiveId, mode, menuIds) {
  const normalizedMode = String(mode || "PROFILE").toUpperCase() === "CUSTOM" ? "CUSTOM" : "PROFILE";
  await connection.execute("UPDATE executives SET menu_access_mode=? WHERE id=?", [normalizedMode, executiveId]);
  await connection.execute("DELETE FROM executive_menu_overrides WHERE executive_id=?", [executiveId]);
  if (normalizedMode === "CUSTOM") {
    for (const menuId of intList(menuIds)) {
      const [menuRows] = await connection.execute(
        "SELECT id, admin_only FROM menus WHERE id=? AND is_active=1 LIMIT 1",
        [menuId]
      );
      if (!menuRows[0]) continue;
      await connection.execute(
        "INSERT IGNORE INTO executive_menu_overrides (executive_id, menu_id) VALUES (?, ?)",
        [executiveId, menuId]
      );
    }
  }
}

async function reassignPendingApprovals(targetId, connection) {
  const [pending] = await connection.execute(
    `SELECT id, request_number, module_name, entity_id
     FROM approval_requests
     WHERE current_approver_executive_id=? AND status='PENDING' FOR UPDATE`,
    [targetId]
  );
  if (!pending.length) return 0;
  const next = await getNextEligibleApprover(targetId, connection);
  if (!next) {
    throw new AppError("This executive has pending approvals and no higher approval-enabled manager is available", 409);
  }
  for (const approval of pending) {
    await connection.execute(
      `UPDATE approval_requests SET current_approver_executive_id=?, current_level=?, updated_at=CURRENT_TIMESTAMP WHERE id=?`,
      [next.id, next.level_rank, approval.id]
    );
    await reassignAdminRequestHistory({
      approvalRequestId: approval.id,
      currentApproverExecutiveId: next.id,
      currentLevel: next.level_rank,
    }, connection);
    await createNotification({
      executiveId: next.id,
      title: `${approval.module_name} approval reassigned`,
      message: `${approval.request_number} was reassigned to you by Admin role management.`,
      module: approval.module_name,
      entityId: approval.entity_id,
    }, connection);
  }
  return pending.length;
}

// Backward-compatible approval-role page APIs.
export async function listApprovalRoles(_req, res) {
  const [rows] = await db.execute(
    `SELECT e.id AS executive_id, e.executive_code, e.executive_name, e.designation,
            e.status, e.approval_enabled, e.manager_executive_id,
            p.id AS profile_id, p.code AS profile_code, p.name AS profile_name,
            p.level_rank, p.is_admin, m.executive_name AS manager_name,
            (SELECT COUNT(*) FROM approval_requests ar
             WHERE ar.current_approver_executive_id=e.id AND ar.status='PENDING') AS pending_approvals
     FROM executives e
     JOIN profiles p ON p.id=e.profile_id
     LEFT JOIN executives m ON m.id=e.manager_executive_id
     ORDER BY p.level_rank, e.executive_name`
  );
  res.json({ status: "success", executives: rows });
}

export async function updateApprovalRole(req, res) {
  if (typeof req.body.approvalEnabled !== "boolean") throw new AppError("approvalEnabled must be true or false", 400);
  const targetId = Number(req.params.id);
  if (!Number.isInteger(targetId)) throw new AppError("Invalid executive id", 400);

  const result = await withTransaction(async (connection) => {
    const [rows] = await connection.execute(
      `SELECT e.id, e.executive_name, e.approval_enabled, e.status,
              p.code AS profile_code, p.level_rank, p.is_admin
       FROM executives e JOIN profiles p ON p.id=e.profile_id
       WHERE e.id=? FOR UPDATE`,
      [targetId]
    );
    const executive = rows[0];
    if (!executive) throw new AppError("Executive not found", 404);
    if (executive.status !== "ACTIVE") throw new AppError("Only active executives can receive approval rights", 409);
    const desired = req.body.approvalEnabled ? 1 : 0;
    if (desired === 1 && Number(executive.level_rank) <= 1 && Number(executive.is_admin || 0) !== 1) {
      throw new AppError("L1 executives are request-only and cannot be granted approval rights", 409);
    }
    let reassigned = 0;
    if (!desired && Number(executive.approval_enabled) !== desired) {
      reassigned = await reassignPendingApprovals(targetId, connection);
    }
    await connection.execute("UPDATE executives SET approval_enabled=? WHERE id=?", [desired, targetId]);
    return { executiveId: targetId, executiveName: executive.executive_name, approvalEnabled: Boolean(desired), reassigned };
  });
  res.json({ status: "success", message: "Approval role updated", ...result });
}

export async function roleManagementMeta(_req, res) {
  const [[profiles], [departments], [territories], [cities], [divisions], [menus], [managers]] = await Promise.all([
    db.execute("SELECT id, code, name, level_rank, is_admin FROM profiles WHERE is_active=1 ORDER BY level_rank"),
    db.execute("SELECT id, name FROM departments ORDER BY name"),
    db.execute("SELECT id, name FROM territories ORDER BY name"),
    db.execute("SELECT id, name FROM cities ORDER BY name"),
    db.execute("SELECT id, code, name FROM product_divisions ORDER BY name"),
    db.execute("SELECT id, menu_name, child_menu_name, route_path, requires_approval_role, admin_only FROM menus WHERE is_active=1 ORDER BY sort_order, id"),
    db.execute(`SELECT e.id, e.executive_code, e.executive_name, p.code AS profile_code, p.name AS profile_name, p.level_rank, p.is_admin
                FROM executives e JOIN profiles p ON p.id=e.profile_id WHERE e.status='ACTIVE' ORDER BY p.level_rank DESC, e.executive_name`),
  ]);
  res.json({ status: "success", profiles, departments, territories, cities, productDivisions: divisions, menus, managers });
}

export async function listUsers(req, res) {
  const params = [];
  const where = ["1=1"];
  if (req.query.status) { where.push("e.status=?"); params.push(String(req.query.status).toUpperCase()); }
  if (req.query.profileId) { where.push("e.profile_id=?"); params.push(Number(req.query.profileId)); }
  if (req.query.search) {
    where.push("(e.executive_name LIKE ? OR e.executive_code LIKE ? OR u.email LIKE ?)");
    const q = `%${req.query.search}%`; params.push(q, q, q);
  }
  const [rows] = await db.execute(
    `SELECT e.id AS executive_id, e.user_id, e.executive_code, e.executive_name, e.email, e.mobile,
            e.designation, e.department_id, e.profile_id, e.manager_executive_id, e.approval_enabled,
            e.menu_access_mode, e.status, u.email AS login_email, u.status AS user_status,
            p.code AS profile_code, p.name AS profile_name, p.level_rank, p.is_admin,
            d.name AS department_name, m.executive_name AS manager_name,
            (SELECT COUNT(*) FROM approval_requests ar WHERE ar.current_approver_executive_id=e.id AND ar.status='PENDING') AS pending_approvals
     FROM executives e
     JOIN users u ON u.id=e.user_id
     JOIN profiles p ON p.id=e.profile_id
     LEFT JOIN departments d ON d.id=e.department_id
     LEFT JOIN executives m ON m.id=e.manager_executive_id
     WHERE ${where.join(" AND ")}
     ORDER BY p.level_rank DESC, e.executive_name`,
    params
  );
  res.json({ status: "success", executives: rows });
}

export async function getUser(req, res) {
  const executiveId = Number(req.params.id);
  const [rows] = await db.execute(
    `SELECT e.*, u.email AS login_email, u.status AS user_status,
            p.code AS profile_code, p.name AS profile_name, p.level_rank, p.is_admin,
            m.executive_name AS manager_name
     FROM executives e JOIN users u ON u.id=e.user_id JOIN profiles p ON p.id=e.profile_id
     LEFT JOIN executives m ON m.id=e.manager_executive_id WHERE e.id=? LIMIT 1`,
    [executiveId]
  );
  const executive = rows[0];
  if (!executive) throw new AppError("Executive not found", 404);
  const [[cities], [territories], [divisions], [menus]] = await Promise.all([
    db.execute("SELECT city_id AS id FROM executive_cities WHERE executive_id=?", [executiveId]),
    db.execute("SELECT territory_id AS id FROM executive_territories WHERE executive_id=?", [executiveId]),
    db.execute("SELECT product_division_id AS id FROM executive_product_divisions WHERE executive_id=?", [executiveId]),
    db.execute("SELECT menu_id AS id FROM executive_menu_overrides WHERE executive_id=?", [executiveId]),
  ]);
  res.json({
    status: "success",
    executive: {
      ...executive,
      cityIds: cities.map((r) => r.id),
      territoryIds: territories.map((r) => r.id),
      productDivisionIds: divisions.map((r) => r.id),
      customMenuIds: menus.map((r) => r.id),
    },
  });
}

export async function createUser(req, res) {
  const body = req.body || {};
  if (!String(body.loginEmail || "").trim()) throw new AppError("loginEmail is required", 400);
  if (!String(body.password || "").trim() || String(body.password).length < 8) throw new AppError("Password must contain at least 8 characters", 400);
  if (!String(body.executiveCode || "").trim()) throw new AppError("executiveCode is required", 400);
  if (!String(body.executiveName || "").trim()) throw new AppError("executiveName is required", 400);
  const profile = await loadProfile(Number(body.profileId));
  await validateManager({ profile, managerExecutiveId: body.managerExecutiveId == null ? null : Number(body.managerExecutiveId) });
  if (body.approvalEnabled === true && Number(profile.level_rank) <= 1 && Number(profile.is_admin) !== 1) {
    throw new AppError("L1 executives cannot receive approval rights", 400);
  }

  const result = await withTransaction(async (connection) => {
    const passwordHash = await bcrypt.hash(String(body.password), 12);
    const [userInsert] = await connection.execute(
      "INSERT INTO users (email, password_hash, status) VALUES (?, ?, 'ACTIVE')",
      [String(body.loginEmail).trim().toLowerCase(), passwordHash]
    );
    const approvalEnabled = Number(profile.is_admin) === 1 ? 1 : (body.approvalEnabled === true && Number(profile.level_rank) > 1 ? 1 : 0);
    const [execInsert] = await connection.execute(
      `INSERT INTO executives
       (user_id, executive_code, executive_name, email, mobile, designation, department_id, profile_id,
        manager_executive_id, approval_enabled, menu_access_mode, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE')`,
      [userInsert.insertId, String(body.executiveCode).trim(), String(body.executiveName).trim(),
       body.email || null, body.mobile || null, body.designation || null, body.departmentId || null,
       Number(body.profileId), body.managerExecutiveId == null ? null : Number(body.managerExecutiveId),
       approvalEnabled, String(body.menuAccessMode || "PROFILE").toUpperCase() === "CUSTOM" ? "CUSTOM" : "PROFILE"]
    );
    const executiveId = execInsert.insertId;
    await replaceMappings(connection, "executive_cities", "city_id", executiveId, intList(body.cityIds));
    await replaceMappings(connection, "executive_territories", "territory_id", executiveId, intList(body.territoryIds));
    await replaceMappings(connection, "executive_product_divisions", "product_division_id", executiveId, intList(body.productDivisionIds));
    await applyCustomMenus(connection, executiveId, body.menuAccessMode, body.menuIds);
    return { userId: userInsert.insertId, executiveId };
  });
  res.status(201).json({ status: "success", message: "Account created", ...result });
}

export async function updateUser(req, res) {
  const targetId = Number(req.params.id);
  const body = req.body || {};
  const result = await withTransaction(async (connection) => {
    const [rows] = await connection.execute(
      `SELECT e.*, u.email AS login_email, p.level_rank AS old_level_rank
       FROM executives e JOIN users u ON u.id=e.user_id JOIN profiles p ON p.id=e.profile_id
       WHERE e.id=? FOR UPDATE`,
      [targetId]
    );
    const current = rows[0];
    if (!current) throw new AppError("Executive not found", 404);
    const profileId = body.profileId == null ? current.profile_id : Number(body.profileId);
    const profile = await loadProfile(profileId, connection);
    const managerExecutiveId = body.managerExecutiveId === undefined
      ? current.manager_executive_id
      : (body.managerExecutiveId == null ? null : Number(body.managerExecutiveId));
    await validateManager({ targetExecutiveId: targetId, profile, managerExecutiveId }, connection);

    // New level must remain higher than every direct report.
    const [subRows] = await connection.execute(
      `SELECT MAX(p.level_rank) AS max_rank FROM executives e JOIN profiles p ON p.id=e.profile_id WHERE e.manager_executive_id=? AND e.status='ACTIVE'`,
      [targetId]
    );
    if (subRows[0]?.max_rank != null && Number(subRows[0].max_rank) >= Number(profile.level_rank) && Number(profile.is_admin) !== 1) {
      throw new AppError("Selected level is not higher than one or more direct reports", 409);
    }

    let approvalEnabled = body.approvalEnabled === undefined ? Number(current.approval_enabled) : (body.approvalEnabled ? 1 : 0);
    if (Number(profile.level_rank) <= 1 && Number(profile.is_admin) !== 1) approvalEnabled = 0;
    if (Number(profile.is_admin) === 1) approvalEnabled = 1;
    if (Number(current.approval_enabled) === 1 && approvalEnabled === 0) {
      await reassignPendingApprovals(targetId, connection);
    }

    await connection.execute(
      `UPDATE executives SET executive_code=?, executive_name=?, email=?, mobile=?, designation=?, department_id=?,
       profile_id=?, manager_executive_id=?, approval_enabled=?, status=? WHERE id=?`,
      [body.executiveCode ?? current.executive_code, body.executiveName ?? current.executive_name,
       body.email === undefined ? current.email : body.email, body.mobile === undefined ? current.mobile : body.mobile,
       body.designation === undefined ? current.designation : body.designation,
       body.departmentId === undefined ? current.department_id : body.departmentId,
       profileId, managerExecutiveId, approvalEnabled,
       body.status ?? current.status, targetId]
    );
    if (body.loginEmail != null) {
      await connection.execute("UPDATE users SET email=? WHERE id=?", [String(body.loginEmail).trim().toLowerCase(), current.user_id]);
    }
    if (body.password != null && String(body.password).trim()) {
      if (String(body.password).length < 8) throw new AppError("Password must contain at least 8 characters", 400);
      const hash = await bcrypt.hash(String(body.password), 12);
      await connection.execute("UPDATE users SET password_hash=? WHERE id=?", [hash, current.user_id]);
      await connection.execute("UPDATE refresh_tokens SET revoked_at=CURRENT_TIMESTAMP WHERE user_id=? AND revoked_at IS NULL", [current.user_id]);
    }
    if (Array.isArray(body.cityIds)) await replaceMappings(connection, "executive_cities", "city_id", targetId, intList(body.cityIds));
    if (Array.isArray(body.territoryIds)) await replaceMappings(connection, "executive_territories", "territory_id", targetId, intList(body.territoryIds));
    if (Array.isArray(body.productDivisionIds)) await replaceMappings(connection, "executive_product_divisions", "product_division_id", targetId, intList(body.productDivisionIds));
    if (body.menuAccessMode != null || Array.isArray(body.menuIds)) {
      await applyCustomMenus(connection, targetId, body.menuAccessMode ?? current.menu_access_mode, body.menuIds ?? []);
    }
    return { executiveId: targetId };
  });
  res.json({ status: "success", message: "Account and role updated", ...result });
}

export async function deactivateUser(req, res) {
  const targetId = Number(req.params.id);
  if (targetId === Number(req.user.executiveId)) throw new AppError("Admin cannot deactivate their own active session account", 409);
  const result = await withTransaction(async (connection) => {
    const [rows] = await connection.execute("SELECT id, user_id, status FROM executives WHERE id=? FOR UPDATE", [targetId]);
    const current = rows[0];
    if (!current) throw new AppError("Executive not found", 404);
    if (current.status === "INACTIVE") return { executiveId: targetId, reassigned: 0 };
    const reassigned = await reassignPendingApprovals(targetId, connection);
    await connection.execute("UPDATE executives SET status='INACTIVE', approval_enabled=0 WHERE id=?", [targetId]);
    await connection.execute("UPDATE users SET status='INACTIVE' WHERE id=?", [current.user_id]);
    await connection.execute("UPDATE refresh_tokens SET revoked_at=CURRENT_TIMESTAMP WHERE user_id=? AND revoked_at IS NULL", [current.user_id]);
    return { executiveId: targetId, reassigned };
  });
  res.json({ status: "success", message: "Account deactivated", ...result });
}

export async function reactivateUser(req, res) {
  const targetId = Number(req.params.id);
  const [rows] = await db.execute("SELECT user_id FROM executives WHERE id=? LIMIT 1", [targetId]);
  if (!rows[0]) throw new AppError("Executive not found", 404);
  await withTransaction(async (connection) => {
    await connection.execute("UPDATE executives SET status='ACTIVE' WHERE id=?", [targetId]);
    await connection.execute("UPDATE users SET status='ACTIVE' WHERE id=?", [rows[0].user_id]);
  });
  res.json({ status: "success", message: "Account reactivated", executiveId: targetId });
}

export async function listRequestHistory(req, res) {
  const params = [];
  const where = ["1=1"];
  if (req.query.status) { where.push("h.status=?"); params.push(String(req.query.status).toUpperCase()); }
  if (req.query.module) { where.push("h.module_name=?"); params.push(String(req.query.module).toUpperCase()); }
  if (req.query.search) {
    where.push("(h.request_number LIKE ? OR requester.executive_name LIKE ? OR requester.executive_code LIKE ?)");
    const q = `%${req.query.search}%`; params.push(q, q, q);
  }
  const [rows] = await db.execute(
    `SELECT h.id AS history_id, h.approval_request_id, h.module_name, h.entity_id, h.request_number,
            h.status, h.current_level, h.last_action, h.last_action_level, h.last_remarks,
            h.created_at, h.updated_at, h.completed_at,
            requester.id AS requested_by_executive_id, requester.executive_name AS requested_by,
            requester.executive_code AS requested_by_code, requester_profile.code AS requester_profile_code,
            requester_profile.name AS requester_profile_name, requester_profile.level_rank AS requester_level,
            current.executive_name AS current_approver, current_profile.code AS current_approver_profile_code,
            actor.executive_name AS last_action_by, actor.executive_code AS last_action_by_code,
            actor_profile.code AS last_actor_profile_code, actor_profile.name AS last_actor_profile_name
     FROM admin_request_history h
     JOIN executives requester ON requester.id=h.requested_by_executive_id
     JOIN profiles requester_profile ON requester_profile.id=requester.profile_id
     LEFT JOIN executives current ON current.id=h.current_approver_executive_id
     LEFT JOIN profiles current_profile ON current_profile.id=current.profile_id
     LEFT JOIN executives actor ON actor.id=h.last_action_by_executive_id
     LEFT JOIN profiles actor_profile ON actor_profile.id=actor.profile_id
     WHERE ${where.join(" AND ")}
     ORDER BY h.created_at DESC, h.id DESC`,
    params
  );
  res.json({ status: "success", history: rows });
}

export async function requestHistoryDetails(req, res) {
  const historyId = Number(req.params.id);
  const [rows] = await db.execute(
    `SELECT h.*, ar.status AS approval_status, ar.current_approver_executive_id,
            requester.executive_name AS requested_by, requester.executive_code AS requested_by_code,
            rp.code AS requester_profile_code, rp.name AS requester_profile_name
     FROM admin_request_history h
     JOIN approval_requests ar ON ar.id=h.approval_request_id
     JOIN executives requester ON requester.id=h.requested_by_executive_id
     JOIN profiles rp ON rp.id=requester.profile_id
     WHERE h.id=? LIMIT 1`, [historyId]
  );
  const item = rows[0];
  if (!item) throw new AppError("Admin history record not found", 404);
  const [actions] = await db.execute(
    `SELECT ah.id, ah.approval_level, ah.action, ah.remarks, ah.created_at,
            e.id AS executive_id, e.executive_name, e.executive_code,
            p.code AS profile_code, p.name AS profile_name, p.level_rank
     FROM approval_history ah
     JOIN executives e ON e.id=ah.action_by_executive_id
     JOIN profiles p ON p.id=e.profile_id
     WHERE ah.approval_request_id=? ORDER BY ah.id`, [item.approval_request_id]
  );
  const [quantityHistory] = await db.execute(
    `SELECT aih.*, b.title, e.executive_name AS approved_by_name, p.code AS profile_code, p.level_rank
     FROM approval_item_history aih
     JOIN books b ON b.id=aih.book_id
     JOIN executives e ON e.id=aih.approved_by_executive_id
     JOIN profiles p ON p.id=e.profile_id
     WHERE aih.approval_request_id=? ORDER BY aih.id`, [item.approval_request_id]
  );
  res.json({ status: "success", history: item, actions, quantityHistory });
}

export async function deleteRequestHistory(req, res) {
  const id = Number(req.params.id);
  const [rows] = await db.execute("SELECT status FROM admin_request_history WHERE id=? LIMIT 1", [id]);
  if (!rows[0]) throw new AppError("History record not found", 404);
  if (rows[0].status === "PENDING") throw new AppError("Pending request history cannot be removed", 409);
  await db.execute("DELETE FROM admin_request_history WHERE id=?", [id]);
  res.json({ status: "success", message: "Admin history record removed" });
}

export async function bulkDeleteRequestHistory(req, res) {
  const ids = intList(req.body?.historyIds);
  if (!ids.length) throw new AppError("historyIds array is required", 400);
  const placeholders = ids.map(() => "?").join(",");
  const [pending] = await db.execute(
    `SELECT id FROM admin_request_history WHERE id IN (${placeholders}) AND status='PENDING'`, ids
  );
  if (pending.length) throw new AppError("Pending request history cannot be removed", 409);
  const [result] = await db.execute(`DELETE FROM admin_request_history WHERE id IN (${placeholders})`, ids);
  res.json({ status: "success", message: "Selected admin history records removed", deleted: result.affectedRows });
}
