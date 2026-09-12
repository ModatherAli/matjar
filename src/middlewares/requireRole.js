import { ApiError } from "../utils/ApiError.js";

export function requireRole(...roles) {
  return (req, _res, next) => {
    if (!req.user) {
      return next(ApiError.unauthorized());
    }
    if (!roles.includes(req.user.role)) {
      return next(ApiError.forbidden("Insufficient permissions"));
    }
    return next();
  };
}

export const requireAdmin = requireRole("ADMIN");

