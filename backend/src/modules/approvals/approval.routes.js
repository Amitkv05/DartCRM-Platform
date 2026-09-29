import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./approval.controller.js";

export const approvalRouter = Router();
approvalRouter.use(requireUser);
approvalRouter.get("/", asyncHandler(controller.listApprovals));
approvalRouter.get("/mine/history", asyncHandler(controller.listMyRequests));
approvalRouter.post("/bulk-action", asyncHandler(controller.bulkAction));
approvalRouter.get("/:id", asyncHandler(controller.approvalDetails));
approvalRouter.post("/:id/action", asyncHandler(controller.action));
