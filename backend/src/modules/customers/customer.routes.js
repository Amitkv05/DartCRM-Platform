import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./customer.controller.js";

export const customerRouter = Router();
customerRouter.use(requireUser);
customerRouter.get("/master-data", asyncHandler(controller.masterData));
customerRouter.get("/search-cities", asyncHandler(controller.searchCities));
customerRouter.get("/search", asyncHandler(controller.searchCustomers));
customerRouter.get("/book-sellers", asyncHandler(controller.searchBookSellers));
customerRouter.get("/", asyncHandler(controller.listCustomers));
customerRouter.post("/", asyncHandler(controller.createCustomer));
customerRouter.get("/:id", asyncHandler(controller.getCustomer));
customerRouter.put("/:id", asyncHandler(controller.updateCustomer));
customerRouter.post("/:id/delete-request", asyncHandler(controller.requestDelete));
