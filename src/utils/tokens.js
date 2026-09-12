import jwt from "jsonwebtoken";
import { env } from "../config/env.js";

export function signAccessToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role, typ: "access" },
    env.jwtAccessSecret,
    { expiresIn: env.accessExpiresIn }
  );
}

export function signRefreshToken(user) {
  return jwt.sign(
    { sub: user.id, typ: "refresh" },
    env.jwtRefreshSecret,
    { expiresIn: env.refreshExpiresIn }
  );
}

export function verifyAccessToken(token) {
  const payload = jwt.verify(token, env.jwtAccessSecret);
  if (payload.typ !== "access") {
    throw new Error("Not an access token");
  }
  return payload;
}

export function verifyRefreshToken(token) {
  const payload = jwt.verify(token, env.jwtRefreshSecret);
  if (payload.typ !== "refresh") {
    throw new Error("Not a refresh token");
  }
  return payload;
}

export function authTokens(user) {
  return {
    accessToken: signAccessToken(user),
    refreshToken: signRefreshToken(user),
  };
}

