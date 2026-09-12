import { Router } from "express";
import { auth } from "../../middlewares/auth.js";
import { requireAdmin } from "../../middlewares/requireRole.js";
import { validate } from "../../middlewares/validate.js";
import * as ordersController from "./orders.controller.js";
import {
  adminOrderListQuerySchema,
  checkoutSchema,
  orderListQuerySchema,
  updateOrderStatusSchema,
} from "./orders.validation.js";

export const orderRoutes = Router();

orderRoutes.use(auth);
orderRoutes.post(
  "/checkout",
  validate(checkoutSchema),
  ordersController.checkout
);
orderRoutes.get(
  "/",
  validate(orderListQuerySchema, "query"),
  ordersController.list
);
orderRoutes.get("/:id", ordersController.getById);
orderRoutes.post("/:id/cancel", ordersController.cancel);

export const adminOrderRoutes = Router();

adminOrderRoutes.use(auth, requireAdmin);
adminOrderRoutes.get(
  "/",
  validate(adminOrderListQuerySchema, "query"),
  ordersController.adminList
);
adminOrderRoutes.get("/:id", ordersController.adminGetById);
adminOrderRoutes.patch(
  "/:id/status",
  validate(updateOrderStatusSchema),
  ordersController.adminUpdateStatus
);

