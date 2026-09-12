import bcrypt from "bcryptjs";
import { prisma } from "../../lib/prisma.js";
import { ApiError } from "../../utils/ApiError.js";
import { getPagination, buildPaginatedResponse } from "../../utils/pagination.js";
import { toPublicUser } from "../auth/auth.service.js";

const publicSelect = {
  id: true,
  email: true,
  role: true,
  name: true,
  phone: true,
  isActive: true,
  createdAt: true,
  updatedAt: true,
};

export async function getMe(userId) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw ApiError.notFound("User not found");
  }
  return toPublicUser(user);
}

export async function updateMe(userId, input) {
  const user = await prisma.user.update({
    where: { id: userId },
    data: {
      ...(input.name !== undefined ? { name: input.name } : {}),
      ...(input.phone !== undefined ? { phone: input.phone } : {}),
    },
  });
  return toPublicUser(user);
}

export async function changePassword(userId, input) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw ApiError.notFound("User not found");
  }
  const ok = await bcrypt.compare(input.currentPassword, user.passwordHash);
  if (!ok) {
    throw ApiError.badRequest("Current password is incorrect");
  }
  const passwordHash = await bcrypt.hash(input.newPassword, 10);
  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash },
  });
  return { message: "Password updated" };
}

export async function adminList(query) {
  const { page, limit, skip } = getPagination(query);
  const where = {};
  if (query.role) {
    where.role = query.role;
  }
  if (query.search) {
    where.OR = [
      { email: { contains: query.search, mode: "insensitive" } },
      { name: { contains: query.search, mode: "insensitive" } },
    ];
  }
  const [items, total] = await Promise.all([
    prisma.user.findMany({
      where,
      select: publicSelect,
      orderBy: { createdAt: "desc" },
      skip,
      take: limit,
    }),
    prisma.user.count({ where }),
  ]);
  return buildPaginatedResponse(items, total, page, limit);
}

export async function adminGetById(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: publicSelect,
  });
  if (!user) {
    throw ApiError.notFound("User not found");
  }
  return user;
}

export async function adminUpdateRole(targetId, role, actorId) {
  if (targetId === actorId && role !== "ADMIN") {
    throw ApiError.badRequest("You cannot remove your own admin role");
  }
  try {
    const user = await prisma.user.update({
      where: { id: targetId },
      data: { role },
      select: publicSelect,
    });
    return user;
  } catch {
    throw ApiError.notFound("User not found");
  }
}

export async function adminSetActive(targetId, isActive, actorId) {
  if (targetId === actorId && isActive === false) {
    throw ApiError.badRequest("You cannot deactivate your own account");
  }
  try {
    const user = await prisma.user.update({
      where: { id: targetId },
      data: { isActive },
      select: publicSelect,
    });
    return user;
  } catch {
    throw ApiError.notFound("User not found");
  }
}

