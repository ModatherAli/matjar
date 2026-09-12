import { Router } from "express";
import { auth } from "../../middlewares/auth.js";
import { validate } from "../../middlewares/validate.js";
import * as addressesController from "./addresses.controller.js";
import {
  createAddressSchema,
  updateAddressSchema,
} from "./addresses.validation.js";

export const addressRoutes = Router();

addressRoutes.use(auth);
addressRoutes.get("/", addressesController.list);
addressRoutes.post(
  "/",
  validate(createAddressSchema),
  addressesController.create
);
addressRoutes.get("/:id", addressesController.getById);
addressRoutes.put(
  "/:id",
  validate(updateAddressSchema),
  addressesController.update
);
addressRoutes.delete("/:id", addressesController.remove);

