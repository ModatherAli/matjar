import { prisma } from "../../lib/prisma.js";
import { ApiError } from "../../utils/ApiError.js";
import { slugify, uniqueSlug } from "../../utils/slugify.js";

const detailSelect = {
  id: true,
  name: true,
  slug: true,
  description: true,
  imageUrl: true,
  parentId: true,
  createdAt: true,
  parent: { select: { id: true, name: true, slug: true } },
  children: { select: { id: true, name: true, slug: true } },
  _count: { select: { products: true } },
};

const listSelect = {
  id: true,
  name: true,
  slug: true,
  description: true,
  imageUrl: true,
  parentId: true,
  createdAt: true,
  _count: { select: { products: true, children: true } },
};

async function ensureParentValid(categoryId, parentId) {
  if (!parentId) {
    return;
  }
  if (parentId === categoryId) {
    throw ApiError.badRequest("A category cannot be its own parent");
  }
  const parent = await prisma.category.findUnique({
    where: { id: parentId },
    select: { id: true, parentId: true },
  });
  if (!parent) {
    throw ApiError.badRequest("Parent category not found");
  }
  let current = parent;
  while (current.parentId) {
    if (current.parentId === categoryId) {
      throw ApiError.badRequest("Cannot set a descendant as parent");
    }
    current = await prisma.category.findUnique({
      where: { id: current.parentId },
      select: { id: true, parentId: true },
    });
    if (!current) {
      break;
    }
  }
}

export async function listCategories() {
  return prisma.category.findMany({
    orderBy: { name: "asc" },
    select: listSelect,
  });
}

export async function getCategoryBySlug(slug) {
  const category = await prisma.category.findUnique({
    where: { slug },
    select: detailSelect,
  });
  if (!category) {
    throw ApiError.notFound("Category not found");
  }
  return category;
}

export async function createCategory(input) {
  await ensureParentValid(null, input.parentId ?? null);
  let slug = input.slug ?? slugify(input.name);
  const taken = await prisma.category.findUnique({
    where: { slug },
    select: { id: true },
  });
  if (taken) {
    if (input.slug) {
      throw ApiError.conflict("Category slug already exists");
    }
    slug = await uniqueSlug(prisma.category, slug);
  }
  return prisma.category.create({
    data: {
      name: input.name,
      slug,
      description: input.description ?? null,
      imageUrl: input.imageUrl ?? null,
      parentId: input.parentId ?? null,
    },
    select: detailSelect,
  });
}

export async function updateCategory(id, input) {
  const existing = await prisma.category.findUnique({ where: { id } });
  if (!existing) {
    throw ApiError.notFound("Category not found");
  }
  if (input.parentId !== undefined) {
    await ensureParentValid(id, input.parentId);
  }
  if (input.slug && input.slug !== existing.slug) {
    const taken = await prisma.category.findUnique({
      where: { slug: input.slug },
      select: { id: true },
    });
    if (taken) {
      throw ApiError.conflict("Category slug already exists");
    }
  }
  return prisma.category.update({
    where: { id },
    data: {
      ...(input.name !== undefined ? { name: input.name } : {}),
      ...(input.slug !== undefined ? { slug: input.slug } : {}),
      ...(input.description !== undefined
        ? { description: input.description }
        : {}),
      ...(input.imageUrl !== undefined ? { imageUrl: input.imageUrl } : {}),
      ...(input.parentId !== undefined ? { parentId: input.parentId } : {}),
    },
    select: detailSelect,
  });
}

export async function deleteCategory(id) {
  const existing = await prisma.category.findUnique({
    where: { id },
    include: {
      _count: { select: { products: true, children: true } },
    },
  });
  if (!existing) {
    throw ApiError.notFound("Category not found");
  }
  if (existing._count.products > 0) {
    throw ApiError.conflict("Cannot delete a category that has products");
  }
  if (existing._count.children > 0) {
    throw ApiError.conflict("Cannot delete a category that has subcategories");
  }
  await prisma.category.delete({ where: { id } });
  return { message: "Category deleted" };
}


export async function getCategoryById(id) {
  const category = await prisma.category.findUnique({
    where: { id },
    select: detailSelect,
  });
  if (!category) {
    throw ApiError.notFound("Category not found");
  }
  return category;
}

