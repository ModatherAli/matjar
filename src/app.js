import express from "express";
import helmet from "helmet";
import cors from "cors";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import { notFound } from "./middlewares/notFound.js";
import { errorHandler } from "./middlewares/errorHandler.js";

export function createApp() {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(express.json({ limit: "1mb" }));
  app.use(morgan("dev"));

  const authLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 60,
    standardHeaders: "draft-7",
    legacyHeaders: false,
  });
  app.use("/api/v1/auth", authLimiter);

  app.get("/health", (_req, res) => {
    res.json({ success: true, data: { status: "ok", service: "matjar" } });
  });

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

