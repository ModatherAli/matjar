import { asyncHandler } from "../../utils/asyncHandler.js";
import * as adminService from "./admin.service.js";

export const dashboard = asyncHandler(async (_req, res) => {
  const stats = await adminService.getDashboard();
  res.json({ success: true, data: stats });
});

