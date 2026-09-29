import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./notification.controller.js";

export const notificationRouter = Router();
notificationRouter.use(requireUser);
notificationRouter.get("/", asyncHandler(controller.list));
notificationRouter.patch("/:id/read", asyncHandler(controller.markRead));
