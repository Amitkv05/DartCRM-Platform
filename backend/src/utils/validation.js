import { AppError } from "./AppError.js";

export function requireFields(source, fields) {
  const missing = fields.filter((field) => {
    const value = source?.[field];
    return value === undefined || value === null || value === "";
  });
  if (missing.length) {
    throw new AppError(`Missing required field(s): ${missing.join(", ")}`, 400);
  }
}

export function toPositiveInt(value, name) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new AppError(`${name} must be a positive integer`, 400);
  }
  return parsed;
}

export function normalizeAction(value) {
  const action = String(value || "").trim().toUpperCase();
  if (!["APPROVE", "REJECT"].includes(action)) {
    throw new AppError("action must be APPROVE or REJECT", 400);
  }
  return action;
}

export function toFlag(value, defaultValue = 0) {
  if (value === undefined || value === null || value === "") return defaultValue;
  if (typeof value === "boolean") return value ? 1 : 0;
  const v = String(value).trim().toUpperCase();
  if (["Y", "YES", "TRUE", "1"].includes(v)) return 1;
  if (["N", "NO", "FALSE", "0"].includes(v)) return 0;
  return defaultValue;
}
