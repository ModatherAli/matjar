import { asyncHandler } from "../../utils/asyncHandler.js";
import * as cartService from "./cart.service.js";

export const get = asyncHandler(async (req, res) => {
  const cart = await cartService.getCart(req.user.id);
  res.json({ success: true, data: cart });
});

export const addItem = asyncHandler(async (req, res) => {
  const cart = await cartService.addItem(req.user.id, req.body);
  res.status(201).json({ success: true, data: cart });
});

export const updateItem = asyncHandler(async (req, res) => {
  const cart = await cartService.updateItem(
    req.user.id,
    req.params.id,
    req.body.quantity
  );
  res.json({ success: true, data: cart });
});

export const removeItem = asyncHandler(async (req, res) => {
  const cart = await cartService.removeItem(req.user.id, req.params.id);
  res.json({ success: true, data: cart });
});

export const clear = asyncHandler(async (req, res) => {
  const cart = await cartService.clearCart(req.user.id);
  res.json({ success: true, data: cart });
});

