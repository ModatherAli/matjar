import { prisma } from "../../lib/prisma.js";
import { ApiError } from "../../utils/ApiError.js";
import { getPagination, buildPaginatedResponse } from "../../utils/pagination.js";

const reviewSelect = {
  id: true,
  rating: true,
  comment: true,
  createdAt: true,
  user: { select: { id: true, name: true } },
};

async function ensureProduct(productId) {
  const product = await prisma.product.findUnique({
    where: { id: productId },
    select: { id: true },
  });
  if (!product) {
    throw ApiError.notFound("Product not found");
  }
}

export async function listProductReviews(productId, query) {
  await ensureProduct(productId);
  const { page, limit, skip } = getPagination(query);
  const where = { productId };
  const [items, total] = await Promise.all([
    prisma.review.findMany({
      where,
      select: reviewSelect,
      orderBy: { createdAt: "desc" },
      skip,
      take: limit,
    }),
    prisma.review.count({ where }),
  ]);
  return buildPaginatedResponse(items, total, page, limit);
}

async function hasDeliveredPurchase(userId, productId) {
  const order = await prisma.order.findFirst({
    where: {
      userId,
      status: "DELIVERED",
      items: { some: { productId } },
    },
    select: { id: true },
  });
  return !!order;
}

export async function createReview(userId, productId, input) {
  await ensureProduct(productId);
  const existing = await prisma.review.findUnique({
    where: { userId_productId: { userId, productId } },
    select: { id: true },
  });
  if (existing) {
    throw ApiError.conflict("You have already reviewed this product");
  }
  const verified = await hasDeliveredPurchase(userId, productId);
  if (!verified) {
    throw ApiError.forbidden(
      "You can only review products you have purchased and received"
    );
  }
  return prisma.review.create({
    data: {
      userId,
      productId,
      rating: input.rating,
      comment: input.comment ?? null,
    },
    select: reviewSelect,
  });
}

export async function updateReview(userId, productId, input) {
  const existing = await prisma.review.findUnique({
    where: { userId_productId: { userId, productId } },
  });
  if (!existing) {
    throw ApiError.notFound("Review not found");
  }
  return prisma.review.update({
    where: { id: existing.id },
    data: {
      ...(input.rating !== undefined ? { rating: input.rating } : {}),
      ...(input.comment !== undefined ? { comment: input.comment } : {}),
    },
    select: reviewSelect,
  });
}

export async function deleteReview(userId, productId) {
  const existing = await prisma.review.findUnique({
    where: { userId_productId: { userId, productId } },
    select: { id: true },
  });
  if (!existing) {
    throw ApiError.notFound("Review not found");
  }
  await prisma.review.delete({ where: { id: existing.id } });
  return { message: "Review deleted" };
}

