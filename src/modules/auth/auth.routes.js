import { Router } from "express";
import { validate } from "../../middlewares/validate.js";
import * as authController from "./auth.controller.js";
import {
  loginSchema,
  refreshSchema,
  registerSchema,
} from "./auth.validation.js";

export const authRoutes = Router();

authRoutes.post("/register", validate(registerSchema), authController.register);
authRoutes.post("/login", validate(loginSchema), authController.login);
authRoutes.post("/refresh", validate(refreshSchema), authController.refresh);
authRoutes.post("/logout", authController.logout);

