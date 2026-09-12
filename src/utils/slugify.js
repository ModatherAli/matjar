import { randomBytes } from "node:crypto";

export function slugify(text, maxLength = 120) {
  const base = (text ?? "")
    .toString()
    .normalize("NFKD")
    .replace(/[^a-zA-Z0-9]+/g, "-")
    .toLowerCase()
    .replace(/^-+|-+$/g, "")
    .slice(0, maxLength)
    .replace(/-+$/g, "");
  if (!base) {
    return `item-${randomBytes(4).toString("hex")}`;
  }
  return base;
}

export async function uniqueSlug(model, base) {
  let slug = base;
  let attempt = 1;
  while (await model.findUnique({ where: { slug }, select: { id: true } })) {
    attempt += 1;
    slug = `${base}-${attempt}`;
  }
  return slug;
}

