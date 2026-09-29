import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./selfStock.controller.js";

export const selfStockRouter = Router();
selfStockRouter.use(requireUser);
selfStockRouter.get("/master-data", asyncHandler(controller.masterData));
selfStockRouter.get("/trade-addresses", asyncHandler(controller.tradeAddresses));
selfStockRouter.get("/requests", asyncHandler(controller.myRequests));
selfStockRouter.post("/requests", asyncHandler(controller.create));
selfStockRouter.get("/approvals", asyncHandler(controller.approvalList));
selfStockRouter.get("/requests/:id", asyncHandler(controller.requestDetails));
