import { prisma } from "../../lib/prisma.js";
import { ApiError } from "../../utils/ApiError.js";

const cartInclude = {
  items: {
    orderBy: { id: "asc" },
    select: {
      id: true,
      quantity: true,
      product: {
        select: {
          id: true,
          title: true,
          slug: true,
          price: true,
          stockQty: true,
          isActive: true,
          images: {
            select: { url: true },
            orderBy: { position: "asc" },
            take: 1,
          },
        },
      },
    },
  },
};

function withTotals(cart) {
  let subtotal = 0;
  let itemCount = 0;
  for (const item of cart.items) {
    subtotal += Number(item.product.price) * item.quantity;
    itemCount += item.quantity;
  }
  return {
    ...cart,
    subtotal: Math.round(subtotal * 100) / 100,
    itemCount,
  };
}

export async function getCart(userId) {
  const cart = await prisma.cart.upsert({
    where: { userId },
    update: {},
    create: { userId },
    include: cartInclude,
  });
  return withTotals(cart);
}

async function getUserItem(userId, itemId) {
  const item = await prisma.cartItem.findFirst({
    where: { id: itemId, cart: { userId } },
    include: { cart: { select: { id: true } } },
  });
  if (!item) {
    throw ApiError.notFound("Cart item not found");
  }
  return item;
}

export async function addItem(userId, input) {
  const product = await prisma.product.findUnique({
    where: { id: input.productId },
  });
  if (!product) {
    throw ApiError.notFound("Product not found");
  }
  if (!product.isActive) {
    throw ApiError.badRequest("Product is not available");
  }
  const cart = await prisma.cart.upsert({
    where: { userId },
    update: {},
    create: { userId },
  });
  const existing = await prisma.cartItem.findUnique({
    where: { cartId_productId: { cartId: cart.id, productId: product.id } },
  });
  const nextQty = (existing ? existing.quantity : 0) + input.quantity;
  if (nextQty > product.stockQty) {
    throw ApiError.badRequest(
      `Only ${product.stockQty} in stock for ${product.title}`
    );
  }
  if (existing) {
    await prisma.cartItem.update({
      where: { id: existing.id },
      data: { quantity: nextQty },
    });
  } else {
    await prisma.cartItem.create({
      data: { cartId: cart.id, productId: product.id, quantity: input.quantity },
    });
  }
  return getCart(userId);
}

export async function updateItem(userId, itemId, quantity) {
  const item = await getUserItem(userId, itemId);
  const product = await prisma.product.findUnique({
    where: { id: item.productId },
  });
  if (!product || !product.isActive) {
    throw ApiError.badRequest("Product is not available");
  }
  if (quantity > product.stockQty) {
    throw ApiError.badRequest(
      `Only ${product.stockQty} in stock for ${product.title}`
    );
  }
  await prisma.cartItem.update({
    where: { id: item.id },
    data: { quantity },
  });
  return getCart(userId);
}

export async function removeItem(userId, itemId) {
  const item = await getUserItem(userId, itemId);
  await prisma.cartItem.delete({ where: { id: item.id } });
  return getCart(userId);
}

export async function clearCart(userId) {
  const cart = await prisma.cart.upsert({
    where: { userId },
    update: {},
    create: { userId },
  });
  await prisma.cartItem.deleteMany({ where: { cartId: cart.id } });
  return getCart(userId);
}

