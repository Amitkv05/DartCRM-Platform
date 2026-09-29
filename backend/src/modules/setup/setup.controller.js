import { db } from "../../config/db.js";
import { getSetupMap } from "../../services/setup.service.js";

export async function getSetup(req, res) {
  if (req.query.key) {
    const [rows] = await db.execute(
      "SELECT key_name, key_value, description FROM application_setup WHERE key_name = ? AND is_active = 1 LIMIT 1",
      [req.query.key]
    );
    return res.json({ status: "success", setup: rows[0] || null });
  }
  const map = await getSetupMap();
  res.json({ status: "success", setup: map });
}

export async function getMenus(req, res) {
  const [execRows] = await db.execute(
    `SELECT e.menu_access_mode, e.approval_enabled, p.is_admin
     FROM executives e JOIN profiles p ON p.id=e.profile_id
     WHERE e.id=? LIMIT 1`,
    [req.user.executiveId]
  );
  const executive = execRows[0];
  if (!executive) return res.json({ status: "success", menus: [] });

  let rows;
  if (executive.menu_access_mode === "CUSTOM") {
    [rows] = await db.execute(
      `SELECT m.id, m.menu_name, m.child_menu_name, m.route_path,
              m.requires_approval_role, m.admin_only
       FROM executive_menu_overrides emo
       JOIN menus m ON m.id=emo.menu_id
       WHERE emo.executive_id=? AND m.is_active=1
         AND (m.requires_approval_role=0 OR ?=1)
         AND (m.admin_only=0 OR ?=1)
       ORDER BY m.sort_order, m.id`,
      [req.user.executiveId, executive.approval_enabled, executive.is_admin]
    );
  } else {
    [rows] = await db.execute(
      `SELECT m.id, m.menu_name, m.child_menu_name, m.route_path,
              m.requires_approval_role, m.admin_only
       FROM profile_menus pm
       JOIN menus m ON m.id = pm.menu_id
       JOIN executives e ON e.id = ?
       JOIN profiles p ON p.id = e.profile_id
       WHERE pm.profile_id = ?
         AND m.is_active = 1
         AND (m.requires_approval_role = 0 OR e.approval_enabled = 1)
         AND (m.admin_only = 0 OR p.is_admin = 1)
       ORDER BY m.sort_order, m.id`,
      [req.user.executiveId, req.user.profileId]
    );
  }
  res.json({ status: "success", menus: rows });
}
