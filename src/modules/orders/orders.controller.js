import { asyncHandler } from "../../utils/asyncHandler.js";
import * as ordersService from "./orders.service.js";

export const checkout = asyncHandler(async (req, res) => {
  const order = await ordersService.checkout(req.user.id, req.body);
  res.status(201).json({ success: true, data: order });
});

export const list = asyncHandler(async (req, res) => {
  const result = await ordersService.listOrders(req.user.id, req.query);
  res.json(result);
});

export const getById = asyncHandler(async (req, res) => {
  const order = await ordersService.getOrder(req.user.id, req.params.id, false);
  res.json({ success: true, data: order });
});

export const cancel = asyncHandler(async (req, res) => {
  const order = await ordersService.cancelOrder(req.user.id, req.params.id);
  res.json({ success: true, data: order });
});

export const adminList = asyncHandler(async (req, res) => {
  const result = await ordersService.adminListOrders(req.query);
  res.json(result);
});

export const adminGetById = asyncHandler(async (req, res) => {
  const order = await ordersService.getOrder(req.user.id, req.params.id, true);
  res.json({ success: true, data: order });
});

export const adminUpdateStatus = asyncHandler(async (req, res) => {
  const order = await ordersService.adminUpdateStatus(
    req.params.id,
    req.body.status
  );
  res.json({ success: true, data: order });
});

