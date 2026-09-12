import { z } from "zod";

const orderStatus = z.enum([
  "PENDING",
  "PAID",
  "SHIPPED",
  "DELIVERED",
  "CANCELLED",
]);

export const checkoutSchema = z.object({
  addressId: z.string().trim().uuid("Invalid address"),
  shippingCost: z.coerce.number().min(0).max(999999).default(0),
});

export const orderListQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: orderStatus.optional(),
});

export const adminOrderListQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: orderStatus.optional(),
  userId: z.string().trim().uuid("Invalid user").optional(),
});

export const updateOrderStatusSchema = z.object({
  status: orderStatus,
});

