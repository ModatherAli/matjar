import { asyncHandler } from "../../utils/asyncHandler.js";
import * as addressesService from "./addresses.service.js";

export const list = asyncHandler(async (req, res) => {
  const items = await addressesService.listAddresses(req.user.id);
  res.json({ success: true, data: items });
});

export const getById = asyncHandler(async (req, res) => {
  const address = await addressesService.getAddress(req.user.id, req.params.id);
  res.json({ success: true, data: address });
});

export const create = asyncHandler(async (req, res) => {
  const address = await addressesService.createAddress(req.user.id, req.body);
  res.status(201).json({ success: true, data: address });
});

export const update = asyncHandler(async (req, res) => {
  const address = await addressesService.updateAddress(
    req.user.id,
    req.params.id,
    req.body
  );
  res.json({ success: true, data: address });
});

export const remove = asyncHandler(async (req, res) => {
  const result = await addressesService.deleteAddress(req.user.id, req.params.id);
  res.json({ success: true, data: result });
});

