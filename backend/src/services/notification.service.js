import { db } from "../config/db.js";

export async function createNotification({ executiveId, title, message, module = null, entityId = null }, executor = db) {
  if (!executiveId) return;
  await executor.execute(
    `INSERT INTO notifications (executive_id, title, message, module_name, entity_id)
     VALUES (?, ?, ?, ?, ?)`,
    [executiveId, title, message, module, entityId]
  );
}
