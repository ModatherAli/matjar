export function errorHandler(err, _req, res, _next) {
  const statusCode = err.statusCode ?? 500;
  const message = statusCode === 500 ? "Internal server error" : err.message;
  if (statusCode === 500) {
    console.error(err);
  }
  res.status(statusCode).json({
    success: false,
    error: {
      message,
      ...(err.details ? { details: err.details } : {}),
    },
  });
}

