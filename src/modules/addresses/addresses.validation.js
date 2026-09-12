import { z } from "zod";

export const createAddressSchema = z.object({
  label: z.string().trim().min(1).max(40).default("home"),
  street: z.string().trim().min(1, "Street is required").max(200),
  city: z.string().trim().min(1, "City is required").max(120),
  country: z.string().trim().min(1, "Country is required").max(120),
  zip: z.string().trim().max(20).nullish(),
  isDefault: z.boolean().default(false),
});

export const updateAddressSchema = z.object({
  label: z.string().trim().min(1).max(40).optional(),
  street: z.string().trim().min(1).max(200).optional(),
  city: z.string().trim().min(1).max(120).optional(),
  country: z.string().trim().min(1).max(120).optional(),
  zip: z.string().trim().max(20).nullish(),
  isDefault: z.boolean().optional(),
});

