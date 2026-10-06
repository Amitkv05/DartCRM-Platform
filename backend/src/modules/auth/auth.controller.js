import bcrypt from "bcrypt";
import { db, withTransaction } from "../../config/db.js";
import { AppError } from "../../utils/AppError.js";
import { randomToken, sha256 } from "../../utils/crypto.js";
import { signAccessToken } from "../../utils/jwt.js";
import { requireFields } from "../../utils/validation.js";
import { getDownHierarchy, getUpHierarchy } from "../../services/hierarchy.service.js";
import { getSetupMap } from "../../services/setup.service.js";

function refreshExpiryDate() {
  const days = Number(process.env.JWT_REFRESH_DAYS || 30);
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
}

async function passwordMatches(password, storedHash) {
  if (!storedHash) return false;
  if (storedHash.startsWith("sha256$")) {
    return storedHash === `sha256$${sha256(password)}`;
  }
  return bcrypt.compare(password, storedHash);
}

function assertNewPassword(password) {
  if (String(password || "").length < 8) {
    throw new AppError("New password must be at least 8 characters", 400);
  }
}

export async function createApiToken(req, res) {
  requireFields(req.body, ["email", "secret"]);
  const [rows] = await db.execute(
    "SELECT id, email, client_secret_hash, status FROM api_clients WHERE email = ? LIMIT 1",
    [req.body.email]
  );
  const client = rows[0];
  if (!client || client.status !== "ACTIVE" || sha256(req.body.secret) !== client.client_secret_hash) {
    throw new AppError("Invalid API client credentials", 401);
  }

  const token = randomToken(32);
  const tokenHash = sha256(token);
  const days = Number(process.env.API_TOKEN_DAYS || 30);
  const expiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
  await db.execute(
    "INSERT INTO api_tokens (client_id, token_hash, expires_at) VALUES (?, ?, ?)",
    [client.id, tokenHash, expiresAt]
  );

  res.status(201).json({ status: "success", apiToken: token, expiresAt });
}

export async function login(req, res) {
  requireFields(req.body, ["email", "password"]);
  const [rows] = await db.execute(
    `SELECT u.id AS user_id, u.email, u.password_hash, u.status AS user_status,
            e.id AS executive_id, e.executive_code, e.executive_name, e.mobile,
            e.designation, e.manager_executive_id, e.approval_enabled,
            p.id AS profile_id, p.code AS profile_code, p.name AS profile_name, p.level_rank, p.is_admin
     FROM users u
     JOIN executives e ON e.user_id = u.id
     JOIN profiles p ON p.id = e.profile_id
     WHERE u.email = ? LIMIT 1`,
    [req.body.email]
  );
  const record = rows[0];
  if (!record || record.user_status !== "ACTIVE") throw new AppError("Invalid email or password", 401);
  const passwordOk = await passwordMatches(req.body.password, record.password_hash);
  if (!passwordOk) throw new AppError("Invalid email or password", 401);

  const payload = {
    userId: record.user_id,
    executiveId: record.executive_id,
    profileId: record.profile_id,
    profileCode: record.profile_code,
    profileRank: record.level_rank,
  };
  const accessToken = signAccessToken(payload);
  const refreshToken = randomToken(48);
  await db.execute(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at, created_ip, user_agent)
     VALUES (?, ?, ?, ?, ?)`,
    [record.user_id, sha256(refreshToken), refreshExpiryDate(), req.ip, req.header("user-agent") || null]
  );

  const [productDivisions] = await db.execute(
    `SELECT pd.id, pd.code, pd.name FROM executive_product_divisions epd
     JOIN product_divisions pd ON pd.id = epd.product_division_id
     WHERE epd.executive_id = ?`,
    [record.executive_id]
  );
  const [territories] = await db.execute(
    `SELECT t.id, t.name FROM executive_territories et JOIN territories t ON t.id = et.territory_id
     WHERE et.executive_id = ?`, [record.executive_id]
  );
  const [cities] = await db.execute(
    `SELECT c.id, c.name FROM executive_cities ec JOIN cities c ON c.id = ec.city_id
     WHERE ec.executive_id = ?`, [record.executive_id]
  );
  const setup = await getSetupMap();
  const upHierarchy = await getUpHierarchy(record.executive_id);
  const downHierarchy = await getDownHierarchy(record.executive_id);

  res.json({
    status: "success",
    accessToken,
    refreshToken,
    user: {
      userId: record.user_id,
      executiveId: record.executive_id,
      executiveCode: record.executive_code,
      executiveName: record.executive_name,
      mobile: record.mobile,
      designation: record.designation,
      profileId: record.profile_id,
      profileCode: record.profile_code,
      profileName: record.profile_name,
      profileRank: record.level_rank,
      approvalEnabled: Boolean(record.approval_enabled),
      isAdmin: Boolean(record.is_admin),
    },
    applicationSetup: setup,
    upHierarchy,
    downHierarchy,
    territoryAccess: territories,
    cityAccess: cities,
    entryAccess: [record.executive_id],
    productDivision: productDivisions,
  });
}

export async function refresh(req, res) {
  requireFields(req.body, ["refreshToken"]);
  const hash = sha256(req.body.refreshToken);
  const [rows] = await db.execute(
    `SELECT rt.id, rt.user_id, rt.expires_at, u.status,
            e.id AS executive_id, e.profile_id, p.code AS profile_code, p.level_rank
     FROM refresh_tokens rt
     JOIN users u ON u.id = rt.user_id
     JOIN executives e ON e.user_id = u.id
     JOIN profiles p ON p.id = e.profile_id
     WHERE rt.token_hash = ? AND rt.revoked_at IS NULL LIMIT 1`,
    [hash]
  );
  const token = rows[0];
  if (!token || token.status !== "ACTIVE" || new Date(token.expires_at) <= new Date()) {
    throw new AppError("Invalid or expired refresh token", 401);
  }
  const accessToken = signAccessToken({
    userId: token.user_id,
    executiveId: token.executive_id,
    profileId: token.profile_id,
    profileCode: token.profile_code,
    profileRank: token.level_rank,
  });
  res.json({ status: "success", accessToken });
}

export async function logout(req, res) {
  requireFields(req.body, ["refreshToken"]);
  await db.execute(
    "UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = ? AND user_id = ?",
    [sha256(req.body.refreshToken), req.user.userId]
  );
  res.json({ status: "success", message: "Logged out successfully" });
}

export async function forgotPassword(req, res) {
  requireFields(req.body, ["email"]);
  const [rows] = await db.execute("SELECT id FROM users WHERE email = ? AND status = 'ACTIVE' LIMIT 1", [req.body.email]);
  const user = rows[0];
  if (user) {
    const raw = randomToken(32);
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000);
    await db.execute(
      "INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)",
      [user.id, sha256(raw), expiresAt]
    );
    return res.json({
      status: "success",
      message: "Password reset request created.",
      ...(process.env.NODE_ENV === "production" ? {} : { debugResetToken: raw }),
    });
  }
  res.json({ status: "success", message: "If the email exists, a password reset request was created." });
}

export async function resetPassword(req, res) {
  requireFields(req.body, ["resetToken", "newPassword"]);
  assertNewPassword(req.body.newPassword);
  await withTransaction(async (connection) => {
    const [rows] = await connection.execute(
      "SELECT * FROM password_reset_tokens WHERE token_hash = ? AND used_at IS NULL FOR UPDATE",
      [sha256(req.body.resetToken)]
    );
    const token = rows[0];
    if (!token || new Date(token.expires_at) <= new Date()) throw new AppError("Invalid or expired reset token", 401);
    const hash = await bcrypt.hash(req.body.newPassword, 12);
    await connection.execute("UPDATE users SET password_hash = ? WHERE id = ?", [hash, token.user_id]);
    await connection.execute("UPDATE password_reset_tokens SET used_at = CURRENT_TIMESTAMP WHERE id = ?", [token.id]);
    await connection.execute("UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE user_id = ? AND revoked_at IS NULL", [token.user_id]);
  });
  res.json({ status: "success", message: "Password changed successfully" });
}

export async function changePassword(req, res) {
  requireFields(req.body, ["currentPassword", "newPassword"]);
  assertNewPassword(req.body.newPassword);
  const [rows] = await db.execute("SELECT password_hash FROM users WHERE id = ? LIMIT 1", [req.user.userId]);
  if (!rows[0] || !(await passwordMatches(req.body.currentPassword, rows[0].password_hash))) {
    throw new AppError("Current password is incorrect", 400);
  }
  const hash = await bcrypt.hash(req.body.newPassword, 12);
  await db.execute("UPDATE users SET password_hash = ? WHERE id = ?", [hash, req.user.userId]);
  res.json({ status: "success", message: "Password changed successfully" });
}
