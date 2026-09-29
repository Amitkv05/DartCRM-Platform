import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { requireUser } from "../../middleware/auth.middleware.js";
import * as controller from "./executive.controller.js";

export const executiveRouter = Router();
executiveRouter.use(requireUser);
executiveRouter.get("/me/hierarchy", asyncHandler(controller.myHierarchy));
executiveRouter.get("/down-hierarchy", asyncHandler(controller.listDownHierarchy));
executiveRouter.get("/:id", asyncHandler(controller.getExecutive));
