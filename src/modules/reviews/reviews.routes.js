import { Router } from "express";
import { auth } from "../../middlewares/auth.js";
import { validate } from "../../middlewares/validate.js";
import * as reviewsController from "./reviews.controller.js";
import {
  createReviewSchema,
  reviewListQuerySchema,
  updateReviewSchema,
} from "./reviews.validation.js";

export const reviewRoutes = Router();

reviewRoutes.get(
  "/:id/reviews",
  validate(reviewListQuerySchema, "query"),
  reviewsController.list
);
reviewRoutes.post(
  "/:id/reviews",
  auth,
  validate(createReviewSchema),
  reviewsController.create
);
reviewRoutes.put(
  "/:id/reviews",
  auth,
  validate(updateReviewSchema),
  reviewsController.update
);
reviewRoutes.delete("/:id/reviews", auth, reviewsController.remove);

