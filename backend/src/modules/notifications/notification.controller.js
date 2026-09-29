import { db } from "../../config/db.js";

export async function list(req, res) {
  const [rows] = await db.execute(
    `SELECT n.*, ar.id AS approval_id
     FROM notifications n
     LEFT JOIN approval_requests ar
       ON ar.module_name = n.module_name AND ar.entity_id = n.entity_id
     WHERE n.executive_id = ?
     ORDER BY n.created_at DESC LIMIT 100`, [req.user.executiveId]
  );
  res.json({ status: "success", notifications: rows });
}

export async function markRead(req, res) {
  await db.execute(
    "UPDATE notifications SET read_at = CURRENT_TIMESTAMP WHERE id = ? AND executive_id = ?",
    [req.params.id, req.user.executiveId]
  );
  res.json({ status: "success", message: "Notification marked as read" });
}
