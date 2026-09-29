import express from "express";
import path from "node:path";
import { fileURLToPath } from "node:url";
import cors from "cors";
import { tokenRouter, authRouter } from "./modules/auth/auth.routes.js";
import { requireApiToken } from "./middleware/apiToken.middleware.js";
import { executiveRouter } from "./modules/executives/executive.routes.js";
import { setupRouter } from "./modules/setup/setup.routes.js";
import { geographyRouter } from "./modules/geography/geography.routes.js";
import { customerRouter } from "./modules/customers/customer.routes.js";
import { contactRouter } from "./modules/contacts/contact.routes.js";
import { attendanceRouter } from "./modules/attendance/attendance.routes.js";
import { planRouter } from "./modules/plans/plan.routes.js";
import { visitRouter } from "./modules/visits/visit.routes.js";
import { catalogRouter } from "./modules/catalog/catalog.routes.js";
import { samplingRouter } from "./modules/sampling/sampling.routes.js";
import { selfStockRouter } from "./modules/self-stock/selfStock.routes.js";
import { approvalRouter } from "./modules/approvals/approval.routes.js";
import { notificationRouter } from "./modules/notifications/notification.routes.js";
import { fileRouter } from "./modules/files/file.routes.js";
import { eProductRouter } from "./modules/e-products/eProduct.routes.js";
import { adminRouter } from "./modules/admin/admin.routes.js";
import { errorHandler, notFound } from "./middleware/error.middleware.js";
import { requestContext } from "./middleware/requestContext.middleware.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..");

export const app = express();
app.disable("x-powered-by");
app.use(requestContext);

const configuredOrigins = String(process.env.CORS_ORIGINS || "")
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);
app.use(cors({
  origin: configuredOrigins.length === 0 ? true : configuredOrigins,
  credentials: false,
}));
app.use(express.json({ limit: "15mb" }));
app.use("/uploads", express.static(path.join(projectRoot, "uploads")));

app.get("/health", (req, res) =>
  res.json({
    status: "success",
    service: "crm-backend-v2",
    version: "4.0-admin-audit",
    features: ["file-upload", "e-products", "sampling-name-compat", "class-range-fix", "notification-safe-read", "subject-id-catalog", "optional-person-met", "safe-api-errors", "sampling-office-fallback", "approval-role-admin", "approval-skip-disabled", "approval-final-or-forward", "customer-update-approval", "admin-user-role-management", "request-audit-history", "my-request-history", "global-approved-customer-visibility"],
  })
);

// The one service/application account creates the shared API token here.
app.use("/api", tokenRouter);

// Every other API call requires that shared application token.
app.use("/api", requireApiToken);
app.use("/api/auth", authRouter);
app.use("/api/executives", executiveRouter);
app.use("/api", setupRouter);
app.use("/api", geographyRouter);
app.use("/api/customers", customerRouter);
app.use("/api/contacts", contactRouter);
app.use("/api/attendance", attendanceRouter);
app.use("/api/plans", planRouter);
app.use("/api/visits", visitRouter);
app.use("/api/catalog", catalogRouter);
app.use("/api/sampling", samplingRouter);
app.use("/api/self-stock", selfStockRouter);
app.use("/api/approvals", approvalRouter);
app.use("/api/notifications", notificationRouter);
app.use("/api/files", fileRouter);
app.use("/api/e-products", eProductRouter);
app.use("/api/admin", adminRouter);

app.use(notFound);
app.use(errorHandler);
