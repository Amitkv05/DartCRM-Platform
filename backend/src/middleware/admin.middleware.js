import { db } from "../config/db.js";
import { AppError } from "../utils/AppError.js";

export async function requireAdmin(req, _res, next) {
  try {
    const [rows] = await db.execute(
      `SELECT p.is_admin
       FROM executives e JOIN profiles p ON p.id = e.profile_id
       WHERE e.id = ? AND e.status = 'ACTIVE' LIMIT 1`,
      [req.user.executiveId]
    );
    if (Number(rows[0]?.is_admin || 0) !== 1) {
      return next(new AppError("Admin access is required", 403));
    }
    next();
  } catch (error) {
    next(error);
  }
}
