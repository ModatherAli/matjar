import { Router } from "express";
import { auth } from "../../middlewares/auth.js";
import { requireAdmin } from "../../middlewares/requireRole.js";
import { productImageUpload } from "../../middlewares/upload.js";
import { validate } from "../../middlewares/validate.js";
import * as productsController from "./products.controller.js";
import {
  adminProductListQuerySchema,
  createProductSchema,
  productListQuerySchema,
  updateProductSchema,
} from "./products.validation.js";

export const productRoutes = Router();

productRoutes.get(
  "/",
  validate(productListQuerySchema, "query"),
  productsController.list
);
productRoutes.get("/:slug", productsController.getBySlug);

export const adminProductRoutes = Router();

adminProductRoutes.use(auth, requireAdmin);
adminProductRoutes.post(
  "/",
  validate(createProductSchema),
  productsController.adminCreate
);
adminProductRoutes.get(
  "/",
  validate(adminProductListQuerySchema, "query"),
  productsController.adminList
);
adminProductRoutes.get("/:id", productsController.adminGetById);
adminProductRoutes.put(
  "/:id",
  validate(updateProductSchema),
  productsController.adminUpdate
);
adminProductRoutes.delete("/:id", productsController.adminRemove);
adminProductRoutes.post(
  "/:id/images",
  productImageUpload.array("images", 5),
  productsController.adminAddImages
);
adminProductRoutes.delete(
  "/:id/images/:imageId",
  productsController.adminRemoveImage
);

