import { z } from "zod";

export const addItemSchema = z.object({
  productId: z.string().trim().uuid("Invalid product"),
  quantity: z.coerce.number().int().min(1).max(999).default(1),
});

export const updateItemSchema = z.object({
  quantity: z.coerce.number().int().min(1).max(999),
});

