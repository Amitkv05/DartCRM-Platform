import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { requireUser } from "../../middleware/auth.middleware.js";
import { requireAdmin } from "../../middleware/admin.middleware.js";
import * as controller from "./admin.controller.js";

export const adminRouter = Router();
adminRouter.use(requireUser, requireAdmin);

// V4 full user / role management.
adminRouter.get("/role-management/meta", asyncHandler(controller.roleManagementMeta));
adminRouter.get("/users", asyncHandler(controller.listUsers));
adminRouter.post("/users", asyncHandler(controller.createUser));
adminRouter.get("/users/:id", asyncHandler(controller.getUser));
adminRouter.patch("/users/:id", asyncHandler(controller.updateUser));
adminRouter.delete("/users/:id", asyncHandler(controller.deactivateUser));
adminRouter.post("/users/:id/reactivate", asyncHandler(controller.reactivateUser));

// V4 central request / approval audit history.
adminRouter.get("/request-history", asyncHandler(controller.listRequestHistory));
adminRouter.post("/request-history/bulk-delete", asyncHandler(controller.bulkDeleteRequestHistory));
adminRouter.get("/request-history/:id", asyncHandler(controller.requestHistoryDetails));
adminRouter.delete("/request-history/:id", asyncHandler(controller.deleteRequestHistory));

// Backward-compatible V3 approval-role endpoints.
adminRouter.get("/executives/approval-roles", asyncHandler(controller.listApprovalRoles));
adminRouter.patch("/executives/:id/approval-role", asyncHandler(controller.updateApprovalRole));
