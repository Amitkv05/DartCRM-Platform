import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { geography } from "./geography.controller.js";

export const geographyRouter = Router();
geographyRouter.use(requireUser);
geographyRouter.get("/geography", asyncHandler(geography));
