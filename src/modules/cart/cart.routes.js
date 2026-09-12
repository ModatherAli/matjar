import { Router } from "express";
import { auth } from "../../middlewares/auth.js";
import { validate } from "../../middlewares/validate.js";
import * as cartController from "./cart.controller.js";
import { addItemSchema, updateItemSchema } from "./cart.validation.js";

export const cartRoutes = Router();

cartRoutes.use(auth);
cartRoutes.get("/", cartController.get);
cartRoutes.post("/items", validate(addItemSchema), cartController.addItem);
cartRoutes.patch(
  "/items/:id",
  validate(updateItemSchema),
  cartController.updateItem
);
cartRoutes.delete("/items/:id", cartController.removeItem);
cartRoutes.delete("/", cartController.clear);

