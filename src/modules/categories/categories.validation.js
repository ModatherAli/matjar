import { z } from "zod";

export const createCategorySchema = z.object({
  name: z.string().trim().min(1, "Name is required").max(120),
  slug: z
    .string()
    .trim()
    .toLowerCase()
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Invalid slug format")
    .max(140)
    .optional(),
  description: z.string().trim().max(2000).nullish(),
  imageUrl: z.string().trim().url("Invalid image URL").max(500).nullish(),
  parentId: z.string().trim().uuid("Invalid parent category").nullish(),
});

export const updateCategorySchema = z.object({
  name: z.string().trim().min(1, "Name is required").max(120).optional(),
  slug: z
    .string()
    .trim()
    .toLowerCase()
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Invalid slug format")
    .max(140)
    .optional(),
  description: z.string().trim().max(2000).nullish(),
  imageUrl: z.string().trim().url("Invalid image URL").max(500).nullish(),
  parentId: z.string().trim().uuid("Invalid parent category").nullish(),
});

