import { Router } from "express";
import { requireUser } from "../../middleware/auth.middleware.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import * as controller from "./attendance.controller.js";

export const attendanceRouter = Router();
attendanceRouter.use(requireUser);
attendanceRouter.post("/check-in", asyncHandler(controller.checkIn));
attendanceRouter.post("/check-out", asyncHandler(controller.checkOut));
attendanceRouter.get("/today", asyncHandler(controller.todayStatus));
attendanceRouter.post("/locations", asyncHandler(controller.submitLocations));
