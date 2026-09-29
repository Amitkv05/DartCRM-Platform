import { AppError } from "../utils/AppError.js";

export function notFound(req, res) {
  res.status(404).json({
    status: "error",
    code: "ROUTE_NOT_FOUND",
    message: `Route not found: ${req.method} ${req.originalUrl}`,
    requestId: req.requestId,
  });
}

function normalizeError(error) {
  if (error instanceof AppError) {
    return { statusCode: error.statusCode, code: "APP_ERROR", message: error.message, details: error.details };
  }

  if (error?.type === "entity.parse.failed" || (error instanceof SyntaxError && error?.status === 400)) {
    return { statusCode: 400, code: "INVALID_JSON", message: "Request body contains invalid JSON" };
  }

  const mysqlCode = error?.code;
  if (mysqlCode === "ER_DUP_ENTRY") {
    return { statusCode: 409, code: "DUPLICATE_VALUE", message: "This record already exists" };
  }
  if (["ER_NO_REFERENCED_ROW_2", "ER_ROW_IS_REFERENCED_2"].includes(mysqlCode)) {
    return { statusCode: 409, code: "RELATED_RECORD_CONFLICT", message: "This operation conflicts with related CRM data" };
  }
  if (["ER_BAD_NULL_ERROR", "ER_TRUNCATED_WRONG_VALUE", "ER_DATA_TOO_LONG", "WARN_DATA_TRUNCATED"].includes(mysqlCode)) {
    return { statusCode: 400, code: "INVALID_DATABASE_VALUE", message: "One or more submitted values are invalid" };
  }
  if (["ECONNREFUSED", "PROTOCOL_CONNECTION_LOST", "ETIMEDOUT"].includes(mysqlCode)) {
    return { statusCode: 503, code: "DATABASE_UNAVAILABLE", message: "CRM database is temporarily unavailable" };
  }

  return { statusCode: 500, code: "INTERNAL_ERROR", message: "Internal server error" };
}

export function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);

  const normalized = normalizeError(error);
  const payload = {
    status: "error",
    code: normalized.code,
    message: normalized.message,
    requestId: req.requestId,
  };

  if (normalized.details !== undefined) payload.details = normalized.details;
  if (process.env.NODE_ENV !== "production" && normalized.statusCode >= 500) {
    payload.debugMessage = error?.message || String(error);
    payload.stack = error?.stack;
  }

  if (normalized.statusCode >= 500) {
    console.error(`[${req.requestId || "no-request-id"}]`, error);
  }

  res.status(normalized.statusCode).json(payload);
}
