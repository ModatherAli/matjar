import { asyncHandler } from "../../utils/asyncHandler.js";
import * as categoriesService from "./categories.service.js";

export const list = asyncHandler(async (_req, res) => {
  const items = await categoriesService.listCategories();
  res.json({ success: true, data: items });
});

export const getBySlug = asyncHandler(async (req, res) => {
  const category = await categoriesService.getCategoryBySlug(req.params.slug);
  res.json({ success: true, data: category });
});

export const create = asyncHandler(async (req, res) => {
  const category = await categoriesService.createCategory(req.body);
  res.status(201).json({ success: true, data: category });
});

export const update = asyncHandler(async (req, res) => {
  const category = await categoriesService.updateCategory(req.params.id, req.body);
  res.json({ success: true, data: category });
});

export const remove = asyncHandler(async (req, res) => {
  const result = await categoriesService.deleteCategory(req.params.id);
  res.json({ success: true, data: result });
});


export const getById = asyncHandler(async (req, res) => {
  const category = await categoriesService.getCategoryById(req.params.id);
  res.json({ success: true, data: category });
});

