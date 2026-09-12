import { prisma } from "../../lib/prisma.js";
import { ApiError } from "../../utils/ApiError.js";

export async function listAddresses(userId) {
  return prisma.address.findMany({
    where: { userId },
    orderBy: [{ isDefault: "desc" }, { id: "desc" }],
  });
}

export async function getAddress(userId, id) {
  const address = await prisma.address.findFirst({
    where: { id, userId },
  });
  if (!address) {
    throw ApiError.notFound("Address not found");
  }
  return address;
}

export async function createAddress(userId, input) {
  const existingCount = await prisma.address.count({ where: { userId } });
  const makeDefault = input.isDefault || existingCount === 0;
  return prisma.$transaction(async (tx) => {
    if (makeDefault) {
      await tx.address.updateMany({
        where: { userId, isDefault: true },
        data: { isDefault: false },
      });
    }
    return tx.address.create({
      data: {
        userId,
        label: input.label ?? "home",
        street: input.street,
        city: input.city,
        country: input.country,
        zip: input.zip ?? null,
        isDefault: makeDefault,
      },
    });
  });
}

export async function updateAddress(userId, id, input) {
  await getAddress(userId, id);
  return prisma.$transaction(async (tx) => {
    if (input.isDefault === true) {
      await tx.address.updateMany({
        where: { userId, isDefault: true },
        data: { isDefault: false },
      });
    }
    return tx.address.update({
      where: { id },
      data: {
        ...(input.label !== undefined ? { label: input.label } : {}),
        ...(input.street !== undefined ? { street: input.street } : {}),
        ...(input.city !== undefined ? { city: input.city } : {}),
        ...(input.country !== undefined ? { country: input.country } : {}),
        ...(input.zip !== undefined ? { zip: input.zip } : {}),
        ...(input.isDefault !== undefined ? { isDefault: input.isDefault } : {}),
      },
    });
  });
}

export async function deleteAddress(userId, id) {
  const address = await getAddress(userId, id);
  await prisma.address.delete({ where: { id } });
  if (address.isDefault) {
    const next = await prisma.address.findFirst({
      where: { userId },
      orderBy: { id: "asc" },
    });
    if (next) {
      await prisma.address.update({
        where: { id: next.id },
        data: { isDefault: true },
      });
    }
  }
  return { message: "Address deleted" };
}

