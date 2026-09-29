import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { requireUser } from "../../middleware/auth.middleware.js";
import * as controller from "./auth.controller.js";

export const tokenRouter = Router();
tokenRouter.post("/token", asyncHandler(controller.createApiToken));

export const authRouter = Router();
authRouter.post("/login", asyncHandler(controller.login));
authRouter.post("/refresh", asyncHandler(controller.refresh));
authRouter.post("/forgot-password", asyncHandler(controller.forgotPassword));
authRouter.post("/reset-password", asyncHandler(controller.resetPassword));
authRouter.post("/logout", requireUser, asyncHandler(controller.logout));
authRouter.post("/change-password", requireUser, asyncHandler(controller.changePassword));
