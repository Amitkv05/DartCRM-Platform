import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./sampling.controller.js";

export const samplingRouter = Router();
samplingRouter.use(requireUser);
samplingRouter.get("/details", asyncHandler(controller.samplingDetails));
samplingRouter.get("/ship-to", asyncHandler(controller.shipTo));
samplingRouter.get("/requests", asyncHandler(controller.myRequests));
samplingRouter.post("/customer", asyncHandler(controller.create));
samplingRouter.get("/approvals", asyncHandler(controller.approvalList));
samplingRouter.get("/requests/:id", asyncHandler(controller.requestDetails));
