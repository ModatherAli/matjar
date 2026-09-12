import fs from "node:fs/promises";
import path from "node:path";
import { randomBytes } from "node:crypto";
import { prisma } from "../../lib/prisma.js";
import { ApiError } from "../../utils/ApiError.js";
import { getPagination, buildPaginatedResponse } from "../../utils/pagination.js";
import { slugify, uniqueSlug } from "../../utils/slugify.js";

const productSelect = {
  id: true,
  title: true,
  slug: true,
  description: true,
  price: true,
  compareAtPrice: true,
  sku: true,
  stockQty: true,
  isActive: true,
  categoryId: true,
  createdAt: true,
  updatedAt: true,
  category: { select: { id: true, name: true, slug: true } },
  images: {
    select: { id: true, url: true, position: true },
    orderBy: { position: "asc" },
  },
};

async function ratingSummary(productId) {
  const agg = await prisma.review.aggregate({
    where: { productId },
    _avg: { rating: true },
    _count: { rating: true },
  });
  return {
    average: agg._avg.rating ?? 0,
    count: agg._count.rating,
  };
}

async function resolveCategoryIds(slug) {
  const root = await prisma.category.findUnique({
    where: { slug },
    select: { id: true },
  });
  if (!root) {
    return [];
  }
  const ids = [root.id];
  const queue = [root.id];
  while (queue.length > 0) {
    const children = await prisma.category.findMany({
      where: { parentId: { in: queue } },
      select: { id: true },
    });
    queue.length = 0;
    for (const child of children) {
      ids.push(child.id);
      queue.push(child.id);
    }
  }
  return ids;
}

function buildWhere(query, onlyActive) {
  const where = {};
  if (onlyActive) {
    where.isActive = true;
  } else if (query.isActive !== undefined) {
    where.isActive = query.isActive;
  }
  if (query.search) {
    where.OR = [
      { title: { contains: query.search, mode: "insensitive" } },
      { description: { contains: query.search, mode: "insensitive" } },
      { sku: { contains: query.search, mode: "insensitive" } },
    ];
  }
  if (query.minPrice != null || query.maxPrice != null) {
    where.price = {};
    if (query.minPrice != null) {
      where.price.gte = query.minPrice;
    }
    if (query.maxPrice != null) {
      where.price.lte = query.maxPrice;
    }
  }
  return where;
}

function sortOrder(sort) {
  if (sort === "price_asc") {
    return { price: "asc" };
  }
  if (sort === "price_desc") {
    return { price: "desc" };
  }
  return { createdAt: "desc" };
}

export async function listProducts(query, onlyActive = true) {
  const { page, limit, skip } = getPagination(query);
  const where = buildWhere(query, onlyActive);
  if (query.category) {
    const ids = await resolveCategoryIds(query.category);
    if (ids.length === 0) {
      return buildPaginatedResponse([], 0, page, limit);
    }
    where.categoryId = { in: ids };
  }
  const [items, total] = await Promise.all([
    prisma.product.findMany({
      where,
      select: productSelect,
      orderBy: sortOrder(query.sort),
      skip,
      take: limit,
    }),
    prisma.product.count({ where }),
  ]);
  return buildPaginatedResponse(items, total, page, limit);
}

export async function getProductBySlug(slug, onlyActive = true) {
  const product = await prisma.product.findUnique({
    where: { slug },
    select: productSelect,
  });
  if (!product || (onlyActive && !product.isActive)) {
    throw ApiError.notFound("Product not found");
  }
  return { ...product, rating: await ratingSummary(product.id) };
}

export async function getProductById(id) {
  const product = await prisma.product.findUnique({
    where: { id },
    select: productSelect,
  });
  if (!product) {
    throw ApiError.notFound("Product not found");
  }
  return { ...product, rating: await ratingSummary(product.id) };
}

async function generateSku(title) {
  const prefix = slugify(title).slice(0, 12).toUpperCase().replace(/-/g, "") || "ITEM";
  for (let i = 0; i < 10; i += 1) {
    const sku = `${prefix}-${randomBytes(3).toString("hex").toUpperCase()}`;
    const taken = await prisma.product.findUnique({
      where: { sku },
      select: { id: true },
    });
    if (!taken) {
      return sku;
    }
  }
  return `${prefix}-${Date.now().toString(36).toUpperCase()}`;
}

export async function createProduct(input) {
  const category = await prisma.category.findUnique({
    where: { id: input.categoryId },
    select: { id: true },
  });
  if (!category) {
    throw ApiError.badRequest("Category not found");
  }
  let slug = input.slug ?? slugify(input.title);
  const slugTaken = await prisma.product.findUnique({
    where: { slug },
    select: { id: true },
  });
  if (slugTaken) {
    if (input.slug) {
      throw ApiError.conflict("Product slug already exists");
    }
    slug = await uniqueSlug(prisma.product, slug);
  }
  let sku = input.sku ?? (await generateSku(input.title));
  if (input.sku) {
    const skuTaken = await prisma.product.findUnique({
      where: { sku },
      select: { id: true },
    });
    if (skuTaken) {
      throw ApiError.conflict("Product SKU already exists");
    }
  }
  try {
    return await prisma.product.create({
      data: {
        title: input.title,
        slug,
        description: input.description ?? null,
        price: input.price,
        compareAtPrice: input.compareAtPrice ?? null,
        sku,
        stockQty: input.stockQty ?? 0,
        categoryId: input.categoryId,
        isActive: input.isActive ?? true,
      },
      select: productSelect,
    });
  } catch (err) {
    if (err && err.code === "P2002") {
      throw ApiError.conflict("Product slug or SKU already exists");
    }
    throw err;
  }
}

export async function updateProduct(id, input) {
  const existing = await prisma.product.findUnique({ where: { id } });
  if (!existing) {
    throw ApiError.notFound("Product not found");
  }
  if (input.categoryId && input.categoryId !== existing.categoryId) {
    const category = await prisma.category.findUnique({
      where: { id: input.categoryId },
      select: { id: true },
    });
    if (!category) {
      throw ApiError.badRequest("Category not found");
    }
  }
  if (input.slug && input.slug !== existing.slug) {
    const taken = await prisma.product.findUnique({
      where: { slug: input.slug },
      select: { id: true },
    });
    if (taken) {
      throw ApiError.conflict("Product slug already exists");
    }
  }
  if (input.sku && input.sku !== existing.sku) {
    const taken = await prisma.product.findUnique({
      where: { sku: input.sku },
      select: { id: true },
    });
    if (taken) {
      throw ApiError.conflict("Product SKU already exists");
    }
  }
  try {
    return await prisma.product.update({
      where: { id },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.slug !== undefined ? { slug: input.slug } : {}),
        ...(input.description !== undefined
          ? { description: input.description }
          : {}),
        ...(input.price !== undefined ? { price: input.price } : {}),
        ...(input.compareAtPrice !== undefined
          ? { compareAtPrice: input.compareAtPrice }
          : {}),
        ...(input.sku !== undefined ? { sku: input.sku } : {}),
        ...(input.stockQty !== undefined ? { stockQty: input.stockQty } : {}),
        ...(input.categoryId !== undefined
          ? { categoryId: input.categoryId }
          : {}),
        ...(input.isActive !== undefined ? { isActive: input.isActive } : {}),
      },
      select: productSelect,
    });
  } catch (err) {
    if (err && err.code === "P2002") {
      throw ApiError.conflict("Product slug or SKU already exists");
    }
    throw err;
  }
}

export async function deleteProduct(id) {
  const existing = await prisma.product.findUnique({
    where: { id },
    select: { id: true, images: { select: { url: true } } },
  });
  if (!existing) {
    throw ApiError.notFound("Product not found");
  }
  const orderCount = await prisma.orderItem.count({
    where: { productId: id },
  });
  if (orderCount > 0) {
    const product = await prisma.product.update({
      where: { id },
      data: { isActive: false },
      select: productSelect,
    });
    return { softDeleted: true, product };
  }
  for (const image of existing.images) {
    try {
      await fs.unlink(path.join(process.cwd(), image.url.replace(/^\//, "")));
    } catch {
      // Best effort file cleanup
    }
  }
  await prisma.product.delete({ where: { id } });
  return { softDeleted: false, message: "Product deleted" };
}

export async function addProductImages(id, files) {
  const existing = await prisma.product.findUnique({
    where: { id },
    select: { id: true, _count: { select: { images: true } } },
  });
  if (!existing) {
    throw ApiError.notFound("Product not found");
  }
  if (!files || files.length === 0) {
    throw ApiError.badRequest("No image files uploaded");
  }
  const created = [];
  let position = existing._count.images;
  for (const file of files) {
    position += 1;
    created.push(
      await prisma.productImage.create({
        data: {
          productId: id,
          url: `/uploads/products/${file.filename}`,
          position,
        },
      })
    );
  }
  return created;
}

export async function deleteProductImage(id, imageId) {
  const image = await prisma.productImage.findFirst({
    where: { id: imageId, productId: id },
  });
  if (!image) {
    throw ApiError.notFound("Product image not found");
  }
  await prisma.productImage.delete({ where: { id: image.id } });
  try {
    await fs.unlink(path.join(process.cwd(), image.url.replace(/^\//, "")));
  } catch {
    // Best effort file cleanup
  }
  return { message: "Product image deleted" };
}

