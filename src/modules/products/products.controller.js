import { asyncHandler } from "../../utils/asyncHandler.js";
import * as productsService from "./products.service.js";

export const list = asyncHandler(async (req, res) => {
  const result = await productsService.listProducts(req.query, true);
  res.json(result);
});

export const getBySlug = asyncHandler(async (req, res) => {
  const product = await productsService.getProductBySlug(req.params.slug, true);
  res.json({ success: true, data: product });
});

export const adminList = asyncHandler(async (req, res) => {
  const result = await productsService.listProducts(req.query, false);
  res.json(result);
});

export const adminGetById = asyncHandler(async (req, res) => {
  const product = await productsService.getProductById(req.params.id);
  res.json({ success: true, data: product });
});

export const adminCreate = asyncHandler(async (req, res) => {
  const product = await productsService.createProduct(req.body);
  res.status(201).json({ success: true, data: product });
});

export const adminUpdate = asyncHandler(async (req, res) => {
  const product = await productsService.updateProduct(req.params.id, req.body);
  res.json({ success: true, data: product });
});

export const adminRemove = asyncHandler(async (req, res) => {
  const result = await productsService.deleteProduct(req.params.id);
  res.json({ success: true, data: result });
});

export const adminAddImages = asyncHandler(async (req, res) => {
  const images = await productsService.addProductImages(
    req.params.id,
    req.files ?? []
  );
  res.status(201).json({ success: true, data: images });
});

export const adminRemoveImage = asyncHandler(async (req, res) => {
  const result = await productsService.deleteProductImage(
    req.params.id,
    req.params.imageId
  );
  res.json({ success: true, data: result });
});

