export function notFound(_req, res) {
  res.status(404).json({ success: false, error: { message: "Route not found" } });
}

