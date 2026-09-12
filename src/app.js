import express from "express";
import helmet from "helmet";
import cors from "cors";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import swaggerUi from "swagger-ui-express";
import { notFound } from "./middlewares/notFound.js";
import { errorHandler } from "./middlewares/errorHandler.js";
import { swaggerSpec } from "./docs/swagger.js";
import { authRoutes } from "./modules/auth/auth.routes.js";
import {
  adminUserRoutes,
  userRoutes,
} from "./modules/users/users.routes.js";
import {
  adminCategoryRoutes,
  categoryRoutes,
} from "./modules/categories/categories.routes.js";
import {
  adminProductRoutes,
  productRoutes,
} from "./modules/products/products.routes.js";
import { addressRoutes } from "./modules/addresses/addresses.routes.js";
import { cartRoutes } from "./modules/cart/cart.routes.js";
import {
  adminOrderRoutes,
  orderRoutes,
} from "./modules/orders/orders.routes.js";
import { reviewRoutes } from "./modules/reviews/reviews.routes.js";
import { adminRoutes } from "./modules/admin/admin.routes.js";

export function createApp() {
  const app = express();

  app.use(helmet({ crossOriginResourcePolicy: false }));
  app.use(cors());
  app.use(express.json({ limit: "1mb" }));
  app.use(morgan("dev"));
  app.use("/uploads", express.static("uploads"));

  const authLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 60,
    standardHeaders: "draft-7",
    legacyHeaders: false,
  });

  app.get("/health", (_req, res) => {
    res.json({ success: true, data: { status: "ok", service: "matjar" } });
  });

  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

  app.use("/api/v1/auth", authLimiter, authRoutes);
  app.use("/api/v1/users", userRoutes);
  app.use("/api/v1/admin/users", adminUserRoutes);
  app.use("/api/v1/categories", categoryRoutes);
  app.use("/api/v1/admin/categories", adminCategoryRoutes);
  app.use("/api/v1/products", productRoutes, reviewRoutes);
  app.use("/api/v1/admin/products", adminProductRoutes);
  app.use("/api/v1/addresses", addressRoutes);
  app.use("/api/v1/cart", cartRoutes);
  app.use("/api/v1/orders", orderRoutes);
  app.use("/api/v1/admin/orders", adminOrderRoutes);
  app.use("/api/v1/admin", adminRoutes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

