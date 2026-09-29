import { db } from "../config/db.js";
import { AppError } from "../utils/AppError.js";

export async function getManager(executiveId, executor = db) {
  const [rows] = await executor.execute(
    `SELECT m.id, m.executive_code, m.executive_name, m.approval_enabled,
            p.code AS profile_code, p.level_rank
     FROM executives e
     LEFT JOIN executives m ON m.id = e.manager_executive_id
     LEFT JOIN profiles p ON p.id = m.profile_id
     WHERE e.id = ? LIMIT 1`,
    [executiveId]
  );
  return rows[0]?.id ? rows[0] : null;
}

/**
 * Returns the first active manager above executiveId who is allowed to approve.
 * Managers with approval_enabled = 0 are intentionally skipped.
 */
export async function getNextEligibleApprover(executiveId, executor = db) {
  const [rows] = await executor.execute(
    `WITH RECURSIVE manager_chain AS (
       SELECT m.id, m.manager_executive_id, m.executive_code, m.executive_name,
              m.approval_enabled, m.status, p.code AS profile_code, p.level_rank, 1 AS depth
       FROM executives e
       JOIN executives m ON m.id = e.manager_executive_id
       JOIN profiles p ON p.id = m.profile_id
       WHERE e.id = ?
       UNION ALL
       SELECT m.id, m.manager_executive_id, m.executive_code, m.executive_name,
              m.approval_enabled, m.status, p.code AS profile_code, p.level_rank, mc.depth + 1
       FROM manager_chain mc
       JOIN executives m ON m.id = mc.manager_executive_id
       JOIN profiles p ON p.id = m.profile_id
     )
     SELECT id, executive_code, executive_name, profile_code, level_rank, depth
     FROM manager_chain
     WHERE approval_enabled = 1 AND status = 'ACTIVE'
     ORDER BY depth
     LIMIT 1`,
    [executiveId]
  );
  return rows[0] || null;
}

export async function getUpHierarchy(executiveId, executor = db) {
  const [rows] = await executor.execute(
    `WITH RECURSIVE up_tree AS (
       SELECT id, manager_executive_id, 0 AS depth FROM executives WHERE id = ?
       UNION ALL
       SELECT e.id, e.manager_executive_id, u.depth + 1
       FROM executives e
       JOIN up_tree u ON e.id = u.manager_executive_id
     )
     SELECT id FROM up_tree ORDER BY depth`,
    [executiveId]
  );
  return rows.map((row) => row.id);
}

export async function getDownHierarchy(executiveId, executor = db) {
  const [rows] = await executor.execute(
    `WITH RECURSIVE down_tree AS (
       SELECT id, manager_executive_id, 0 AS depth FROM executives WHERE id = ?
       UNION ALL
       SELECT e.id, e.manager_executive_id, d.depth + 1
       FROM executives e
       JOIN down_tree d ON e.manager_executive_id = d.id
     )
     SELECT id FROM down_tree ORDER BY depth, id`,
    [executiveId]
  );
  return rows.map((row) => row.id);
}

export async function assertCanViewExecutive(actorExecutiveId, targetExecutiveId, executor = db) {
  const ids = await getDownHierarchy(actorExecutiveId, executor);
  if (!ids.includes(Number(targetExecutiveId))) {
    throw new AppError("Target executive is outside your down hierarchy", 403);
  }
}
