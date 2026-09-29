import { AppError } from "../utils/AppError.js";
import { verifyAccessToken } from "../utils/jwt.js";

export function requireUser(req, res, next) {
  try {
    const header = req.header("authorization") || "";
    const parts = header.trim().split(/\s+/);
    const scheme = parts[0];
    const token = parts[1];

    if (scheme?.toLowerCase() !== "bearer" || !token) {
      throw new AppError("Bearer access token is required", 401);
    }

    req.user = verifyAccessToken(token.trim());
    next();
  } catch (error) {
    if (error instanceof AppError) return next(error);
    next(new AppError("Invalid or expired access token", 401));
  }
}
