import { z } from "zod";

const slugField = z
  .string()
  .trim()
  .toLowerCase()
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Invalid slug format")
  .max(220);

const priceField = z.coerce
  .number({ invalid_type_error: "Price must be a number" })
  .positive("Price must be positive")
  .max(99999999);

const productBase = z.object({
  title: z.string().trim().min(1, "Title is required").max(200),
  slug: slugField.optional(),
  description: z.string().trim().max(5000).nullish(),
  price: priceField,
  compareAtPrice: priceField.nullish(),
  sku: z.string().trim().min(1).max(60).optional(),
  stockQty: z.coerce.number().int().min(0).default(0),
  categoryId: z.string().trim().uuid("Invalid category"),
  isActive: z.boolean().default(true),
});

export const createProductSchema = productBase.superRefine((val, ctx) => {
  if (
    val.compareAtPrice != null &&
    val.price != null &&
    val.compareAtPrice <= val.price
  ) {
    ctx.addIssue({
      code: "custom",
      path: ["compareAtPrice"],
      message: "Compare-at price must be greater than price",
    });
  }
});

export const updateProductSchema = z.object({
  title: z.string().trim().min(1).max(200).optional(),
  slug: slugField.optional(),
  description: z.string().trim().max(5000).nullish(),
  price: priceField.optional(),
  compareAtPrice: priceField.nullish(),
  sku: z.string().trim().min(1).max(60).optional(),
  stockQty: z.coerce.number().int().min(0).optional(),
  categoryId: z.string().trim().uuid("Invalid category").optional(),
  isActive: z.boolean().optional(),
});

const listBase = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().trim().max(120).optional(),
  category: z.string().trim().toLowerCase().max(140).optional(),
  minPrice: z.coerce.number().min(0).optional(),
  maxPrice: z.coerce.number().min(0).optional(),
  sort: z.enum(["newest", "price_asc", "price_desc"]).default("newest"),
});

export const productListQuerySchema = listBase.superRefine((val, ctx) => {
  if (
    val.minPrice != null &&
    val.maxPrice != null &&
    val.minPrice > val.maxPrice
  ) {
    ctx.addIssue({
      code: "custom",
      path: ["maxPrice"],
      message: "maxPrice must be greater than or equal to minPrice",
    });
  }
});

export const adminProductListQuerySchema = listBase
  .extend({
    isActive: z
      .enum(["true", "false"])
      .transform((v) => v === "true")
      .optional(),
  })
  .superRefine((val, ctx) => {
    if (
      val.minPrice != null &&
      val.maxPrice != null &&
      val.minPrice > val.maxPrice
    ) {
      ctx.addIssue({
        code: "custom",
        path: ["maxPrice"],
        message: "maxPrice must be greater than or equal to minPrice",
      });
    }
  });

