import { db, withTransaction } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { normalizeAction } from "../../utils/validation.js";
import { actOnApproval, getApprovalForUpdate } from "../../services/approval.service.js";
import { finalizeApproval } from "../../services/approval-finalizer.service.js";
import { getNextEligibleApprover } from "../../services/hierarchy.service.js";

const QUANTITY_MODULES = new Set(["CUSTOMER_SAMPLING", "SELF_STOCK"]);

function boolValue(value, fallback = false) {
  if (value === undefined || value === null) return fallback;
  if (typeof value === "boolean") return value;
  return ["1", "true", "yes", "y"].includes(String(value).trim().toLowerCase());
}

async function applyItemQuantities(approval, actorExecutiveId, items, executor, allowDefault = false) {
  const table = approval.module_name === "CUSTOMER_SAMPLING"
    ? "customer_sampling_request_items"
    : approval.module_name === "SELF_STOCK"
      ? "self_stock_request_items"
      : null;
  if (!table) return;

  if ((!Array.isArray(items) || items.length === 0) && allowDefault) {
    const [defaults] = await executor.execute(
      `SELECT id AS itemId, COALESCE(approved_qty, requested_qty) AS approvedQty
       FROM ${table} WHERE request_id = ?`,
      [approval.entity_id]
    );
    items = defaults;
  }
  if (!Array.isArray(items) || items.length === 0) {
    throw new AppError("items with approvedQty are required for approval", 400);
  }

  for (const input of items) {
    const itemId = Number(input.itemId);
    const approvedQty = Number(input.approvedQty);
    if (!Number.isInteger(itemId) || !Number.isFinite(approvedQty) || approvedQty < 0) {
      throw new AppError("Each approval item requires valid itemId and approvedQty", 400);
    }
    const [rows] = await executor.execute(
      `SELECT id, book_id, requested_qty, previous_approved_qty, approved_qty
       FROM ${table} WHERE id = ? AND request_id = ? FOR UPDATE`,
      [itemId, approval.entity_id]
    );
    const item = rows[0];
    if (!item) throw new AppError(`Approval item ${itemId} not found`, 404);

    // Every approval level may increase or decrease the previous level quantity,
    // but it may never exceed the quantity originally requested by the junior.
    const maxAllowed = Number(item.requested_qty);
    if (approvedQty > maxAllowed) {
      throw new AppError(`approvedQty for item ${itemId} cannot exceed requestedQty ${maxAllowed}`, 409);
    }

    await executor.execute(
      `INSERT INTO approval_item_history
       (approval_request_id, module_name, entity_item_id, book_id, approval_level, requested_qty,
        previous_approved_qty, approved_qty, approved_by_executive_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [approval.id, approval.module_name, item.id, item.book_id, approval.current_level,
       item.requested_qty, item.approved_qty ?? 0, approvedQty, actorExecutiveId]
    );
    await executor.execute(
      `UPDATE ${table}
       SET previous_approved_qty = COALESCE(approved_qty, 0), approved_qty = ?
       WHERE id = ?`,
      [approvedQty, item.id]
    );
  }
}

async function updateModulePendingStatus(moduleName, entityId, nextLevel, executor) {
  const status = `PENDING_LEVEL_${nextLevel}`;
  if (moduleName === "CUSTOMER_SAMPLING") {
    await executor.execute(
      "UPDATE customer_sampling_requests SET request_status = ?, approval_status = 'PENDING' WHERE id = ?",
      [status, entityId]
    );
  } else if (moduleName === "SELF_STOCK") {
    await executor.execute(
      "UPDATE self_stock_requests SET request_status = ?, approval_status = 'PENDING' WHERE id = ?",
      [status, entityId]
    );
  }
}

async function loadRequestData(approval, executor = db) {
  const entityId = approval.entity_id;

  if (["CUSTOMER_CREATE", "CUSTOMER_DELETE"].includes(approval.module_name)) {
    const [customerRows] = await executor.execute(
      `SELECT c.*, ci.name AS city
       FROM customers c LEFT JOIN cities ci ON ci.id = c.city_id
       WHERE c.id = ? LIMIT 1`,
      [entityId]
    );
    const [schoolRows] = await executor.execute(
      `SELECT csd.*, b.name AS board_name, sc.name AS start_class, ec.name AS end_class
       FROM customer_school_details csd
       LEFT JOIN boards b ON b.id = csd.board_id
       LEFT JOIN classes sc ON sc.id = csd.start_class_id
       LEFT JOIN classes ec ON ec.id = csd.end_class_id
       WHERE csd.customer_id = ? LIMIT 1`,
      [entityId]
    );
    const [contacts] = await executor.execute(
      `SELECT cc.*, cd.name AS designation
       FROM customer_contacts cc
       LEFT JOIN contact_designations cd ON cd.id = cc.designation_id
       WHERE cc.customer_id = ? ORDER BY cc.primary_contact DESC, cc.id`,
      [entityId]
    );
    return { customer: customerRows[0] || null, school: schoolRows[0] || null, contacts };
  }

  if (approval.module_name === "CUSTOMER_UPDATE") {
    const [changeRows] = await executor.execute(
      `SELECT ccr.*, c.customer_code, c.customer_name, c.customer_type
       FROM customer_change_requests ccr
       JOIN customers c ON c.id = ccr.customer_id
       WHERE ccr.id = ? LIMIT 1`,
      [entityId]
    );
    const change = changeRows[0] || null;
    if (change) {
      change.proposed_payload = typeof change.proposed_payload === "string"
        ? JSON.parse(change.proposed_payload)
        : change.proposed_payload;
      change.original_snapshot = typeof change.original_snapshot === "string"
        ? JSON.parse(change.original_snapshot)
        : change.original_snapshot;
    }
    return { changeRequest: change };
  }

  if (approval.module_name === "CONTACT_CREATE") {
    const [rows] = await executor.execute(
      `SELECT cc.*, cd.name AS designation, c.customer_name, c.customer_code, c.customer_type
       FROM customer_contacts cc
       JOIN customers c ON c.id = cc.customer_id
       LEFT JOIN contact_designations cd ON cd.id = cc.designation_id
       WHERE cc.id = ? LIMIT 1`,
      [entityId]
    );
    return { contact: rows[0] || null };
  }

  if (approval.module_name === "VISIT_BACKDATE") {
    const [rows] = await executor.execute(
      `SELECT br.*, e.executive_name, e.executive_code
       FROM backdate_requests br JOIN executives e ON e.id = br.executive_id
       WHERE br.id = ? LIMIT 1`,
      [entityId]
    );
    return { backdateRequest: rows[0] || null };
  }

  if (approval.module_name === "CUSTOMER_SAMPLING") {
    const [requestRows] = await executor.execute(
      `SELECT csr.*, c.customer_name, c.customer_code, e.executive_name, e.executive_code,
              sm.name AS shipment_mode
       FROM customer_sampling_requests csr
       JOIN customers c ON c.id = csr.customer_id
       JOIN executives e ON e.id = csr.executive_id
       LEFT JOIN shipment_modes sm ON sm.id = csr.shipment_mode_id
       WHERE csr.id = ? LIMIT 1`,
      [entityId]
    );
    const [items] = await executor.execute(
      `SELECT i.id AS item_id, i.book_id, b.title, b.isbn, b.author,
              i.requested_qty, i.previous_approved_qty, i.approved_qty, i.shipped_qty,
              i.unit_price, i.ship_to, i.shipping_address, i.sample_given,
              st.name AS sampling_type, s.name AS series_name,
              CONCAT_WS(' ', cc.first_name, cc.last_name) AS sample_to_name
       FROM customer_sampling_request_items i
       JOIN books b ON b.id = i.book_id
       LEFT JOIN series s ON s.id = i.series_id
       LEFT JOIN sampling_types st ON st.id = i.sampling_type_id
       LEFT JOIN customer_contacts cc ON cc.id = i.sample_to_contact_id
       WHERE i.request_id = ? ORDER BY i.id`,
      [entityId]
    );
    return { request: requestRows[0] || null, items };
  }

  if (approval.module_name === "SELF_STOCK") {
    const [requestRows] = await executor.execute(
      `SELECT ss.*, e.executive_name, e.executive_code, sm.name AS shipment_mode,
              tc.customer_name AS trade_customer_name
       FROM self_stock_requests ss
       JOIN executives e ON e.id = ss.executive_id
       LEFT JOIN shipment_modes sm ON sm.id = ss.shipment_mode_id
       LEFT JOIN customers tc ON tc.id = ss.trade_customer_id
       WHERE ss.id = ? LIMIT 1`,
      [entityId]
    );
    const [items] = await executor.execute(
      `SELECT i.id AS item_id, i.book_id, b.title, b.isbn, b.author,
              i.requested_qty, i.previous_approved_qty, i.approved_qty, i.shipped_qty,
              i.unit_price, s.name AS series_name, sub.name AS subject_name
       FROM self_stock_request_items i
       JOIN books b ON b.id = i.book_id
       LEFT JOIN series s ON s.id = i.series_id
       LEFT JOIN subjects sub ON sub.id = i.subject_id
       WHERE i.request_id = ? ORDER BY i.id`,
      [entityId]
    );
    return { request: requestRows[0] || null, items };
  }

  return {};
}

export async function listApprovals(req, res) {
  const params = [req.user.executiveId];
  let moduleFilter = "";
  if (req.query.module) {
    moduleFilter = " AND ar.module_name = ?";
    params.push(String(req.query.module).toUpperCase());
  }
  const [rows] = await db.execute(
    `SELECT ar.id AS approval_id, ar.module_name, ar.entity_id, ar.request_number, ar.current_level,
            ar.status, ar.created_at, e.executive_name AS requested_by, e.executive_code AS requested_by_code
     FROM approval_requests ar
     JOIN executives e ON e.id = ar.requested_by_executive_id
     WHERE ar.current_approver_executive_id = ? AND ar.status = 'PENDING' ${moduleFilter}
     ORDER BY ar.created_at DESC`, params
  );
  res.json({ status: "success", approvals: rows });
}

export async function listMyRequests(req, res) {
  const params = [req.user.executiveId];
  const where = ["ar.requested_by_executive_id = ?"];
  if (req.query.status) { where.push("ar.status = ?"); params.push(String(req.query.status).toUpperCase()); }
  if (req.query.module) { where.push("ar.module_name = ?"); params.push(String(req.query.module).toUpperCase()); }
  const [rows] = await db.execute(
    `SELECT ar.id AS approval_id, ar.module_name, ar.entity_id, ar.request_number, ar.status,
            ar.current_level, ar.created_at, ar.updated_at, ar.completed_at,
            current.executive_name AS current_approver_name,
            cp.code AS current_approver_profile_code,
            (SELECT ah.action FROM approval_history ah WHERE ah.approval_request_id=ar.id ORDER BY ah.id DESC LIMIT 1) AS last_action,
            (SELECT e.executive_name FROM approval_history ah JOIN executives e ON e.id=ah.action_by_executive_id WHERE ah.approval_request_id=ar.id ORDER BY ah.id DESC LIMIT 1) AS last_action_by,
            (SELECT p.code FROM approval_history ah JOIN executives e ON e.id=ah.action_by_executive_id JOIN profiles p ON p.id=e.profile_id WHERE ah.approval_request_id=ar.id ORDER BY ah.id DESC LIMIT 1) AS last_action_profile_code,
            (SELECT ah.remarks FROM approval_history ah WHERE ah.approval_request_id=ar.id ORDER BY ah.id DESC LIMIT 1) AS last_remarks
     FROM approval_requests ar
     LEFT JOIN executives current ON current.id=ar.current_approver_executive_id
     LEFT JOIN profiles cp ON cp.id=current.profile_id
     WHERE ${where.join(" AND ")}
     ORDER BY ar.created_at DESC, ar.id DESC`, params
  );
  res.json({ status: "success", requests: rows });
}

export async function approvalDetails(req, res) {
  const [rows] = await db.execute(
    `SELECT ar.*, requester.executive_name AS requested_by_name,
            requester.executive_code AS requested_by_code,
            approver.executive_name AS current_approver_name
     FROM approval_requests ar
     JOIN executives requester ON requester.id = ar.requested_by_executive_id
     LEFT JOIN executives approver ON approver.id = ar.current_approver_executive_id
     WHERE ar.id = ? LIMIT 1`,
    [req.params.id]
  );
  const approval = rows[0];
  if (!approval) throw new AppError("Approval request not found", 404);
  const [viewerRows] = await db.execute(
    `SELECT p.is_admin FROM executives e JOIN profiles p ON p.id=e.profile_id WHERE e.id=? LIMIT 1`,
    [req.user.executiveId]
  );
  const isAdminViewer = Number(viewerRows[0]?.is_admin || 0) === 1;
  if (!isAdminViewer &&
      Number(approval.current_approver_executive_id) !== req.user.executiveId &&
      Number(approval.requested_by_executive_id) !== req.user.executiveId) {
    throw new AppError("You cannot view this approval", 403);
  }

  const [history] = await db.execute(
    `SELECT ah.*, e.executive_name AS action_by_name, e.executive_code AS action_by_code
     FROM approval_history ah
     JOIN executives e ON e.id = ah.action_by_executive_id
     WHERE ah.approval_request_id = ? ORDER BY ah.created_at, ah.id`,
    [approval.id]
  );
  const [itemHistory] = await db.execute(
    `SELECT aih.*, e.executive_name AS approved_by_name
     FROM approval_item_history aih
     JOIN executives e ON e.id = aih.approved_by_executive_id
     WHERE aih.approval_request_id = ? ORDER BY aih.approval_level, aih.id`,
    [approval.id]
  );
  const requestData = await loadRequestData(approval);
  const nextEligibleApprover = Number(approval.current_approver_executive_id) === req.user.executiveId
    ? await getNextEligibleApprover(req.user.executiveId)
    : null;

  res.json({
    status: "success",
    approval,
    requestData,
    history,
    itemHistory,
    capabilities: {
      canAct: Number(approval.current_approver_executive_id) === req.user.executiveId && approval.status === "PENDING",
      supportsEditableQuantities: QUANTITY_MODULES.has(approval.module_name),
      canSendToNextLevel: Boolean(nextEligibleApprover),
      nextEligibleApprover,
    },
  });
}

export async function action(req, res) {
  const actionName = normalizeAction(req.body.action);
  const sendToNextLevel = req.body.sendToNextLevel === undefined
    ? true // backward compatibility for older Flutter approval screens
    : boolValue(req.body.sendToNextLevel);

  const result = await withTransaction(async (connection) => {
    const approval = await getApprovalForUpdate(req.params.id, connection);
    if (Number(approval.current_approver_executive_id) !== req.user.executiveId) {
      throw new AppError("This request is not assigned to you", 403);
    }
    if (actionName === "APPROVE") {
      await applyItemQuantities(approval, req.user.executiveId, req.body.items, connection);
    }
    const outcome = await actOnApproval({
      approvalId: approval.id,
      actorExecutiveId: req.user.executiveId,
      action: actionName,
      remarks: req.body.remarks || null,
      sendToNextLevel,
    }, connection);

    if (outcome.final) {
      await finalizeApproval(approval.module_name, approval.entity_id, outcome.status, connection);
    } else {
      await updateModulePendingStatus(approval.module_name, approval.entity_id, outcome.nextLevel, connection);
    }
    return { approval, outcome };
  });

  const message = result.outcome.final
    ? `${result.approval.module_name} ${result.outcome.status.toLowerCase()}`
    : `${result.approval.module_name} approved at this level and pending for level ${result.outcome.nextLevel}`;
  res.json({ status: "success", message, ...result.outcome });
}

async function processOneApproval({ approvalId, user, actionName, remarks, items, allowDefaultItems, sendToNextLevel }, connection) {
  const approval = await getApprovalForUpdate(approvalId, connection);
  if (Number(approval.current_approver_executive_id) !== user.executiveId) {
    throw new AppError(`Approval ${approvalId} is not assigned to you`, 403);
  }
  if (actionName === "APPROVE") {
    await applyItemQuantities(approval, user.executiveId, items, connection, allowDefaultItems);
  }
  const outcome = await actOnApproval({
    approvalId: approval.id,
    actorExecutiveId: user.executiveId,
    action: actionName,
    remarks: remarks || null,
    sendToNextLevel,
  }, connection);
  if (outcome.final) {
    await finalizeApproval(approval.module_name, approval.entity_id, outcome.status, connection);
  } else {
    await updateModulePendingStatus(approval.module_name, approval.entity_id, outcome.nextLevel, connection);
  }
  return { approvalId: approval.id, moduleName: approval.module_name, entityId: approval.entity_id, ...outcome };
}

export async function bulkAction(req, res) {
  const actionName = normalizeAction(req.body.action);
  const ids = Array.isArray(req.body.approvalIds)
    ? [...new Set(req.body.approvalIds.map(Number).filter(Number.isInteger))]
    : [];
  if (!ids.length) throw new AppError("approvalIds array is required", 400);
  if (actionName === "REJECT" && !String(req.body.remarks || "").trim()) {
    throw new AppError("remarks are required for bulk rejection", 400);
  }
  const sendToNextLevel = req.body.sendToNextLevel === undefined
    ? true
    : boolValue(req.body.sendToNextLevel);

  const results = await withTransaction(async (connection) => {
    const output = [];
    for (const approvalId of ids) {
      output.push(await processOneApproval({
        approvalId,
        user: req.user,
        actionName,
        remarks: req.body.remarks,
        items: null,
        allowDefaultItems: true,
        sendToNextLevel,
      }, connection));
    }
    return output;
  });
  res.json({ status: "success", results });
}
