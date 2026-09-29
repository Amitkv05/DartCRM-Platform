import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./catalog.controller.js";

export const catalogRouter = Router();
catalogRouter.use(requireUser);
catalogRouter.get("/series-class-levels", asyncHandler(controller.seriesAndClassLevels));
catalogRouter.get("/titles", asyncHandler(controller.titles));
catalogRouter.get("/titles/search", asyncHandler(controller.titleNotInSeries));
catalogRouter.get("/shipment-modes", asyncHandler(controller.shipmentModes));
