import { db } from "../../config/db.js";
import { getDownHierarchy, getUpHierarchy, assertCanViewExecutive } from "../../services/hierarchy.service.js";

export async function myHierarchy(req, res) {
  const upHierarchy = await getUpHierarchy(req.user.executiveId);
  const downHierarchy = await getDownHierarchy(req.user.executiveId);
  res.json({ status: "success", upHierarchy, downHierarchy });
}

export async function listDownHierarchy(req, res) {
  const ids = await getDownHierarchy(req.user.executiveId);
  const placeholders = ids.map(() => "?").join(",");
  const [rows] = await db.execute(
    `SELECT e.id, e.executive_code, e.executive_name, e.designation, e.manager_executive_id,
            p.code AS profile_code, p.name AS profile_name
     FROM executives e JOIN profiles p ON p.id = e.profile_id
     WHERE e.id IN (${placeholders}) ORDER BY p.level_rank, e.executive_name`, ids
  );
  res.json({ status: "success", executives: rows });
}

export async function getExecutive(req, res) {
  await assertCanViewExecutive(req.user.executiveId, req.params.id);
  const [rows] = await db.execute(
    `SELECT e.id, e.executive_code, e.executive_name, e.email, e.mobile, e.designation,
            e.manager_executive_id, p.code AS profile_code, p.name AS profile_name
     FROM executives e JOIN profiles p ON p.id = e.profile_id WHERE e.id = ? LIMIT 1`,
    [req.params.id]
  );
  res.json({ status: "success", executive: rows[0] || null });
}
