import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { uploadFile } from "./file.controller.js";

export const fileRouter = Router();
fileRouter.use(requireUser);
fileRouter.post("/upload", asyncHandler(uploadFile));
