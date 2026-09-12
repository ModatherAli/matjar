export function getPagination(query) {
  const page = Math.max(1, parseInt(query.page ?? "1", 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit ?? "20", 10) || 20));
  return { page, limit, skip: (page - 1) * limit };
}

export function buildPaginatedResponse(items, total, page, limit) {
  const totalPages = Math.max(1, Math.ceil(total / limit));
  return {
    success: true,
    data: items,
    pagination: { page, limit, total, totalPages },
  };
}

