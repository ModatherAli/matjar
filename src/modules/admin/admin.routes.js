import { Router } from "express";
import { auth } from "../../middlewares/auth.js";
import { requireAdmin } from "../../middlewares/requireRole.js";
import * as adminController from "./admin.controller.js";

export const adminRoutes = Router();

adminRoutes.use(auth, requireAdmin);
adminRoutes.get("/dashboard", adminController.dashboard);

