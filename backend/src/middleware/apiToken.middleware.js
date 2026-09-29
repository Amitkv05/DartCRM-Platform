import { db } from "../config/db.js";
import { sha256 } from "../utils/crypto.js";
import { AppError } from "../utils/AppError.js";

export async function requireApiToken(req, res, next) {
  try {
    const token = req.header("x-api-token");
    if (!token) throw new AppError("x-api-token header is required", 401);

    const tokenHash = sha256(token);
    const [rows] = await db.execute(
      `SELECT t.id, t.client_id, t.expires_at, c.email AS client_email
       FROM api_tokens t
       JOIN api_clients c ON c.id = t.client_id
       WHERE t.token_hash = ? AND t.revoked_at IS NULL AND c.status = 'ACTIVE'
       LIMIT 1`,
      [tokenHash]
    );

    const record = rows[0];
    if (!record) throw new AppError("Invalid API token", 401);
    if (record.expires_at && new Date(record.expires_at) <= new Date()) {
      throw new AppError("API token has expired", 401);
    }

    req.apiClient = { id: record.client_id, email: record.client_email, tokenId: record.id };
    next();
  } catch (error) {
    next(error);
  }
}
