export function errorHandler(err, _req, res, _next) {
  if (err && err.name === "MulterError") {
    const message =
      err.code === "LIMIT_FILE_SIZE"
        ? "File too large. Maximum size is 5MB."
        : err.code === "LIMIT_FILE_COUNT"
          ? "Too many files. Maximum is 5."
          : "File upload failed";
    return res.status(400).json({ success: false, error: { message } });
  }
  if (err && err.message === "Only image files are allowed") {
    return res.status(400).json({ success: false, error: { message: err.message } });
  }
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

