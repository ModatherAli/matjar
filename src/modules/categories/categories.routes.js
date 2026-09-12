import { Router } from "express";
import { auth } from "../../middlewares/auth.js";
import { requireAdmin } from "../../middlewares/requireRole.js";
import { validate } from "../../middlewares/validate.js";
import * as categoriesController from "./categories.controller.js";
import {
  createCategorySchema,
  updateCategorySchema,
} from "./categories.validation.js";

export const categoryRoutes = Router();

categoryRoutes.get("/", categoriesController.list);
categoryRoutes.get("/:slug", categoriesController.getBySlug);

export const adminCategoryRoutes = Router();

adminCategoryRoutes.use(auth, requireAdmin);
adminCategoryRoutes.post(
  "/",
  validate(createCategorySchema),
  categoriesController.create
);
adminCategoryRoutes.get("/", categoriesController.list);
adminCategoryRoutes.get("/:id", categoriesController.getById);
adminCategoryRoutes.put(
  "/:id",
  validate(updateCategorySchema),
  categoriesController.update
);
adminCategoryRoutes.delete("/:id", categoriesController.remove);

