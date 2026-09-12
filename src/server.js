import { createApp } from "./app.js";
import { env } from "./config/env.js";
import { prisma } from "./lib/prisma.js";

const app = createApp();

async function main() {
  try {
    await prisma.$connect();
    console.log("Connected to PostgreSQL");
  } catch (err) {
    console.warn("WARNING: could not connect to PostgreSQL:", err.message);
    console.warn("API will start without a database connection.");
  }
  app.listen(env.port, () => {
    console.log(`matjar API listening on http://localhost:${env.port}`);
  });
}

main().catch((err) => {
  console.error("Failed to start server", err);
  process.exit(1);
});

