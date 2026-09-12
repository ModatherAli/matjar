import { asyncHandler } from "../../utils/asyncHandler.js";
import * as reviewsService from "./reviews.service.js";

export const list = asyncHandler(async (req, res) => {
  const result = await reviewsService.listProductReviews(
    req.params.id,
    req.query
  );
  res.json(result);
});

export const create = asyncHandler(async (req, res) => {
  const review = await reviewsService.createReview(
    req.user.id,
    req.params.id,
    req.body
  );
  res.status(201).json({ success: true, data: review });
});

export const update = asyncHandler(async (req, res) => {
  const review = await reviewsService.updateReview(
    req.user.id,
    req.params.id,
    req.body
  );
  res.json({ success: true, data: review });
});

export const remove = asyncHandler(async (req, res) => {
  const result = await reviewsService.deleteReview(req.user.id, req.params.id);
  res.json({ success: true, data: result });
});

