import { z } from "zod";

export const updateMeSchema = z.object({
  name: z.string().trim().min(1, "Name is required").max(120).optional(),
  phone: z.string().trim().max(40).nullish(),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, "Current password is required"),
  newPassword: z.string().min(8, "Password must be at least 8 characters").max(128),
});

export const updateRoleSchema = z.object({
  role: z.enum(["ADMIN", "CUSTOMER"]),
});

export const setActiveSchema = z.object({
  isActive: z.boolean(),
});

export const userListQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().trim().max(120).optional(),
  role: z.enum(["ADMIN", "CUSTOMER"]).optional(),
});

