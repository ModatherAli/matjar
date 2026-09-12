import { Router } from "express";
import { auth } from "../../middlewares/auth.js";
import { requireAdmin } from "../../middlewares/requireRole.js";
import { validate } from "../../middlewares/validate.js";
import * as usersController from "./users.controller.js";
import {
  changePasswordSchema,
  setActiveSchema,
  updateMeSchema,
  updateRoleSchema,
  userListQuerySchema,
} from "./users.validation.js";

export const userRoutes = Router();

userRoutes.get("/me", auth, usersController.getMe);
userRoutes.put("/me", auth, validate(updateMeSchema), usersController.updateMe);
userRoutes.put(
  "/me/password",
  auth,
  validate(changePasswordSchema),
  usersController.changePassword
);

export const adminUserRoutes = Router();

adminUserRoutes.use(auth, requireAdmin);
adminUserRoutes.get(
  "/",
  validate(userListQuerySchema, "query"),
  usersController.adminList
);
adminUserRoutes.get("/:id", usersController.adminGetById);
adminUserRoutes.patch(
  "/:id/role",
  validate(updateRoleSchema),
  usersController.adminUpdateRole
);
adminUserRoutes.patch(
  "/:id/status",
  validate(setActiveSchema),
  usersController.adminSetActive
);

