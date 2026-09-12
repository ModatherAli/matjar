import bcrypt from "bcryptjs";
import { prisma } from "../../lib/prisma.js";
import { ApiError } from "../../utils/ApiError.js";
import { authTokens, verifyRefreshToken } from "../../utils/tokens.js";

export function toPublicUser(user) {
  return {
    id: user.id,
    email: user.email,
    role: user.role,
    name: user.name,
    phone: user.phone,
    isActive: user.isActive,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

export async function register(input) {
  const existing = await prisma.user.findUnique({
    where: { email: input.email },
  });
  if (existing) {
    throw ApiError.conflict("Email already registered");
  }
  const passwordHash = await bcrypt.hash(input.password, 10);
  const user = await prisma.user.create({
    data: {
      email: input.email,
      passwordHash,
      name: input.name,
      phone: input.phone ?? null,
      role: "CUSTOMER",
    },
  });
  return { user: toPublicUser(user), ...authTokens(user) };
}

export async function login(input) {
  const user = await prisma.user.findUnique({
    where: { email: input.email },
  });
  if (!user || !user.isActive) {
    throw ApiError.unauthorized("Invalid email or password");
  }
  const ok = await bcrypt.compare(input.password, user.passwordHash);
  if (!ok) {
    throw ApiError.unauthorized("Invalid email or password");
  }
  return { user: toPublicUser(user), ...authTokens(user) };
}

export async function refresh(refreshToken) {
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw ApiError.unauthorized("Invalid or expired refresh token");
  }
  const user = await prisma.user.findUnique({
    where: { id: payload.sub },
  });
  if (!user || !user.isActive) {
    throw ApiError.unauthorized("Invalid or expired refresh token");
  }
  return { user: toPublicUser(user), ...authTokens(user) };
}

