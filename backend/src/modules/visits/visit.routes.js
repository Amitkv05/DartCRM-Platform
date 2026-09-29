import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./visit.controller.js";

export const visitRouter = Router();
visitRouter.use(requireUser);
visitRouter.get("/dsr-entry", asyncHandler(controller.dsrEntryData));
visitRouter.get("/follow-up-executives", asyncHandler(controller.followUpExecutives));
visitRouter.get("/backdate-requests", asyncHandler(controller.listMyBackdateRequests));
visitRouter.post("/backdate-requests", asyncHandler(controller.requestBackdate));
visitRouter.post("/", asyncHandler(controller.createVisit));
visitRouter.get("/details", asyncHandler(controller.visitDetails));
