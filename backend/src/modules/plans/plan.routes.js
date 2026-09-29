import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./plan.controller.js";

export const planRouter = Router();
planRouter.use(requireUser);
planRouter.get("/", asyncHandler(controller.getPlanList));
planRouter.post("/", asyncHandler(controller.createPlan));
