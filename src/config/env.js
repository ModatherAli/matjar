import "dotenv/config";

export const env = {
  port: parseInt(process.env.PORT ?? "4000", 10),
  nodeEnv: process.env.NODE_ENV ?? "development",
  databaseUrl: process.env.DATABASE_URL,
  jwtAccessSecret: process.env.JWT_ACCESS_SECRET ?? "dev-access-secret-change-me-0123456789",
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET ?? "dev-refresh-secret-change-me-0123456789",
  accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN ?? "15m",
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? "7d",
  adminEmail: process.env.ADMIN_EMAIL ?? "admin@matjar.local",
  adminPassword: process.env.ADMIN_PASSWORD ?? "Admin123!",
  adminName: process.env.ADMIN_NAME ?? "Admin",
};

