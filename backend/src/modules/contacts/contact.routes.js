import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./contact.controller.js";

export const contactRouter = Router();
contactRouter.use(requireUser);
contactRouter.get("/customer/:customerId", asyncHandler(controller.listContacts));
contactRouter.post("/", asyncHandler(controller.createContact));
contactRouter.get("/:id", asyncHandler(controller.getContact));
contactRouter.put("/:id", asyncHandler(controller.updateContact));
contactRouter.delete("/:id", asyncHandler(controller.deleteContact));
