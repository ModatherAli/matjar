import { asyncHandler } from "../../utils/asyncHandler.js";
import * as usersService from "./users.service.js";

export const getMe = asyncHandler(async (req, res) => {
  const user = await usersService.getMe(req.user.id);
  res.json({ success: true, data: user });
});

export const updateMe = asyncHandler(async (req, res) => {
  const user = await usersService.updateMe(req.user.id, req.body);
  res.json({ success: true, data: user });
});

export const changePassword = asyncHandler(async (req, res) => {
  const result = await usersService.changePassword(req.user.id, req.body);
  res.json({ success: true, data: result });
});

export const adminList = asyncHandler(async (req, res) => {
  const result = await usersService.adminList(req.query);
  res.json(result);
});

export const adminGetById = asyncHandler(async (req, res) => {
  const user = await usersService.adminGetById(req.params.id);
  res.json({ success: true, data: user });
});

export const adminUpdateRole = asyncHandler(async (req, res) => {
  const user = await usersService.adminUpdateRole(
    req.params.id,
    req.body.role,
    req.user.id
  );
  res.json({ success: true, data: user });
});

export const adminSetActive = asyncHandler(async (req, res) => {
  const user = await usersService.adminSetActive(
    req.params.id,
    req.body.isActive,
    req.user.id
  );
  res.json({ success: true, data: user });
});

