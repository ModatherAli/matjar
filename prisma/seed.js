import "dotenv/config";
import bcrypt from "bcryptjs";
import { prisma } from "../src/lib/prisma.js";
import { env } from "../src/config/env.js";

async function main() {
  const passwordHash = await bcrypt.hash(env.adminPassword, 10);

  const admin = await prisma.user.upsert({
    where: { email: env.adminEmail },
    update: {},
    create: {
      email: env.adminEmail,
      passwordHash,
      role: "ADMIN",
      name: env.adminName,
    },
  });
  console.log("Admin user:", admin.email);

  const electronics = await prisma.category.upsert({
    where: { slug: "electronics" },
    update: {},
    create: {
      name: "Electronics",
      slug: "electronics",
      description: "Gadgets and devices",
    },
  });

  const clothing = await prisma.category.upsert({
    where: { slug: "clothing" },
    update: {},
    create: {
      name: "Clothing",
      slug: "clothing",
      description: "Apparel and accessories",
    },
  });

  const samples = [
    {
      title: "Wireless Headphones",
      slug: "wireless-headphones",
      description: "Noise-cancelling over-ear headphones",
      price: 199.99,
      sku: "ELEC-001",
      stockQty: 50,
      categoryId: electronics.id,
    },
    {
      title: "Smart Watch",
      slug: "smart-watch",
      description: "Fitness tracking smartwatch",
      price: 249.99,
      sku: "ELEC-002",
      stockQty: 30,
      categoryId: electronics.id,
    },
    {
      title: "Cotton T-Shirt",
      slug: "cotton-t-shirt",
      description: "Classic fit cotton t-shirt",
      price: 29.99,
      sku: "CLTH-001",
      stockQty: 200,
      categoryId: clothing.id,
    },
  ];

  for (const p of samples) {
    await prisma.product.upsert({
      where: { slug: p.slug },
      update: {},
      create: p,
    });
  }
  console.log("Seeded", samples.length, "products");
}

main()
  .catch((e) => {
    console.error("Seed failed:", e.message);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());

