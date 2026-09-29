import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { requireUser } from "../../middleware/auth.middleware.js";
import * as controller from "./setup.controller.js";

export const setupRouter = Router();
setupRouter.use(requireUser);
setupRouter.get("/setup", asyncHandler(controller.getSetup));
setupRouter.get("/menus", asyncHandler(controller.getMenus));
