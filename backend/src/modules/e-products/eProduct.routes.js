import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./eProduct.controller.js";

export const eProductRouter = Router();
eProductRouter.use(requireUser);
eProductRouter.get("/brands/:brandId/products", asyncHandler(controller.productsByBrand));
eProductRouter.get("/:eProductId/details", asyncHandler(controller.productDetails));
