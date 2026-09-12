import { prisma } from "../../lib/prisma.js";
import { ApiError } from "../../utils/ApiError.js";
import { getPagination, buildPaginatedResponse } from "../../utils/pagination.js";

const TRANSITIONS = {
  PENDING: ["PAID", "CANCELLED"],
  PAID: ["SHIPPED", "CANCELLED"],
  SHIPPED: ["DELIVERED"],
  DELIVERED: [],
  CANCELLED: [],
};

const orderSelect = {
  id: true,
  userId: true,
  status: true,
  paymentStatus: true,
  subtotal: true,
  shippingCost: true,
  total: true,
  shippingAddress: true,
  createdAt: true,
  user: { select: { id: true, email: true, name: true } },
  items: {
    select: {
      id: true,
      productId: true,
      titleSnapshot: true,
      priceAtPurchase: true,
      quantity: true,
      product: { select: { id: true, title: true, slug: true } },
    },
  },
};

async function restockItems(tx, orderId) {
  const items = await tx.orderItem.findMany({ where: { orderId } });
  for (const item of items) {
    await tx.product.update({
      where: { id: item.productId },
      data: { stockQty: { increment: item.quantity } },
    });
  }
}

export async function checkout(userId, input) {
  const address = await prisma.address.findFirst({
    where: { id: input.addressId, userId },
  });
  if (!address) {
    throw ApiError.badRequest("Address not found");
  }
  const user = await prisma.user.findUnique({ where: { id: userId } });
  const cart = await prisma.cart.findUnique({
    where: { userId },
    include: {
      items: {
        include: {
          product: true,
        },
      },
    },
  });
  if (!cart || cart.items.length === 0) {
    throw ApiError.badRequest("Cart is empty");
  }
  return prisma.$transaction(async (tx) => {
    let subtotal = 0;
    const orderItems = [];
    for (const item of cart.items) {
      const product = await tx.product.findUnique({
        where: { id: item.productId },
      });
      if (!product || !product.isActive) {
        throw ApiError.badRequest(
          `Product ${item.product ? item.product.title : item.productId} is not available`
        );
      }
      if (product.stockQty < item.quantity) {
        throw ApiError.badRequest(
          `Only ${product.stockQty} in stock for ${product.title}`
        );
      }
      subtotal += Number(product.price) * item.quantity;
      orderItems.push({
        productId: product.id,
        titleSnapshot: product.title,
        priceAtPurchase: product.price,
        quantity: item.quantity,
      });
      await tx.product.update({
        where: { id: product.id },
        data: { stockQty: { decrement: item.quantity } },
      });
    }
    subtotal = Math.round(subtotal * 100) / 100;
    const shippingCost = Math.round((input.shippingCost ?? 0) * 100) / 100;
    const order = await tx.order.create({
      data: {
        userId,
        status: "PENDING",
        paymentStatus: "UNPAID",
        subtotal,
        shippingCost,
        total: Math.round((subtotal + shippingCost) * 100) / 100,
        shippingAddress: {
          label: address.label,
          street: address.street,
          city: address.city,
          country: address.country,
          zip: address.zip,
          recipientName: user ? user.name : null,
          recipientEmail: user ? user.email : null,
        },
        items: { create: orderItems },
      },
      select: orderSelect,
    });
    await tx.cartItem.deleteMany({ where: { cartId: cart.id } });
    return order;
  });
}

export async function listOrders(userId, query) {
  const { page, limit, skip } = getPagination(query);
  const where = { userId };
  if (query.status) {
    where.status = query.status;
  }
  const [items, total] = await Promise.all([
    prisma.order.findMany({
      where,
      select: orderSelect,
      orderBy: { createdAt: "desc" },
      skip,
      take: limit,
    }),
    prisma.order.count({ where }),
  ]);
  return buildPaginatedResponse(items, total, page, limit);
}

export async function getOrder(userId, id, isAdmin = false) {
  const order = await prisma.order.findUnique({
    where: { id },
    select: orderSelect,
  });
  if (!order || (!isAdmin && order.userId !== userId)) {
    throw ApiError.notFound("Order not found");
  }
  return order;
}

export async function cancelOrder(userId, id) {
  const order = await getOrder(userId, id, false);
  if (order.status !== "PENDING") {
    throw ApiError.badRequest("Only pending orders can be cancelled");
  }
  return prisma.$transaction(async (tx) => {
    await restockItems(tx, id);
    return tx.order.update({
      where: { id },
      data: { status: "CANCELLED" },
      select: orderSelect,
    });
  });
}

export async function adminListOrders(query) {
  const { page, limit, skip } = getPagination(query);
  const where = {};
  if (query.status) {
    where.status = query.status;
  }
  if (query.userId) {
    where.userId = query.userId;
  }
  const [items, total] = await Promise.all([
    prisma.order.findMany({
      where,
      select: orderSelect,
      orderBy: { createdAt: "desc" },
      skip,
      take: limit,
    }),
    prisma.order.count({ where }),
  ]);
  return buildPaginatedResponse(items, total, page, limit);
}

export async function adminUpdateStatus(id, nextStatus) {
  const order = await prisma.order.findUnique({ where: { id } });
  if (!order) {
    throw ApiError.notFound("Order not found");
  }
  if (order.status === nextStatus) {
    throw ApiError.badRequest(`Order is already ${nextStatus}`);
  }
  if (!TRANSITIONS[order.status].includes(nextStatus)) {
    throw ApiError.badRequest(
      `Cannot move order from ${order.status} to ${nextStatus}`
    );
  }
  return prisma.$transaction(async (tx) => {
    const data = { status: nextStatus };
    if (nextStatus === "PAID") {
      data.paymentStatus = "PAID";
    }
    if (nextStatus === "CANCELLED") {
      if (order.paymentStatus === "PAID") {
        data.paymentStatus = "REFUNDED";
      }
      await restockItems(tx, id);
    }
    return tx.order.update({ where: { id }, data, select: orderSelect });
  });
}

