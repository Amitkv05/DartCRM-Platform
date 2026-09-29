import { randomUUID } from "node:crypto";

export function requestContext(req, res, next) {
  const requestId = String(req.header("x-request-id") || randomUUID());
  req.requestId = requestId;
  res.setHeader("x-request-id", requestId);
  next();
}
