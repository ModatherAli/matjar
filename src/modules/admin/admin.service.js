import { prisma } from "../../lib/prisma.js";

const PAID_STATUSES = ["PAID", "SHIPPED", "DELIVERED"];

export async function getDashboard() {
  const [revenue, ordersByStatus, totalUsers, totalProducts, totalOrders, lowStock, recentOrders] =
    await Promise.all([
      prisma.order.aggregate({
        where: { status: { in: PAID_STATUSES } },
        _sum: { total: true },
      }),
      prisma.order.groupBy({
        by: ["status"],
        _count: { status: true },
      }),
      prisma.user.count(),
      prisma.product.count({ where: { isActive: true } }),
      prisma.order.count(),
      prisma.product.findMany({
        where: { stockQty: { lte: 5 } },
        select: { id: true, title: true, sku: true, stockQty: true },
        orderBy: { stockQty: "asc" },
        take: 10,
      }),
      prisma.order.findMany({
        select: {
          id: true,
          total: true,
          status: true,
          createdAt: true,
          user: { select: { id: true, email: true, name: true } },
        },
        orderBy: { createdAt: "desc" },
        take: 5,
      }),
    ]);
  return {
    revenue: Number(revenue._sum.total ?? 0),
    ordersByStatus: Object.fromEntries(
      ordersByStatus.map((row) => [row.status, row._count.status])
    ),
    totalUsers,
    totalProducts,
    totalOrders,
    lowStock,
    recentOrders,
  };
}

