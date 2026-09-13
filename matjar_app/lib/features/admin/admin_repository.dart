import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models.dart";
import "../../core/network.dart";

/// Admin-only endpoints: dashboard, users, categories, products (+ images),
/// and order fulfillment.
class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  // ---------- dashboard ----------
  Future<Dashboard> dashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>("/admin/dashboard");
      return Dashboard.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- users ----------
  Future<Paged<AdminUserAccount>> listUsers({
    String? search,
    String? role,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        "page": page,
        "limit": 20,
      };
      if (search != null && search.isNotEmpty) {
        queryParams["search"] = search;
      }
      if (role != null && role != "ALL") {
        queryParams["role"] = role;
      }
      final response = await _dio.get<Map<String, dynamic>>(
        "/admin/users",
        queryParameters: queryParams,
      );
      return Paged.fromJson<AdminUserAccount>(
        response.data ?? {},
        AdminUserAccount.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AdminUserAccount> setUserRole(String id, String role) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        "/admin/users/$id/role",
        data: {"role": role},
      );
      return AdminUserAccount.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AdminUserAccount> setUserActive(String id, bool isActive) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        "/admin/users/$id/status",
        data: {"isActive": isActive},
      );
      return AdminUserAccount.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- categories ----------
  Map<String, dynamic> _categoryPayload(
    String name,
    String? description,
    String? parentId,
  ) {
    final payload = <String, dynamic>{"name": name};
    if (description != null && description.isNotEmpty) {
      payload["description"] = description;
    }
    if (parentId != null && parentId.isNotEmpty) {
      payload["parentId"] = parentId;
    }
    return payload;
  }

  Future<Category> createCategory({
    required String name,
    String? description,
    String? parentId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "/admin/categories",
        data: _categoryPayload(name, description, parentId),
      );
      return Category.fromJson(_flattenCategory(response.data!["data"]));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Category> updateCategory(
    String id, {
    required String name,
    String? description,
    String? parentId,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        "/admin/categories/$id",
        data: _categoryPayload(name, description, parentId),
      );
      return Category.fromJson(_flattenCategory(response.data!["data"]));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>("/admin/categories/$id");
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Admin category detail returns {parent, children, _count}; the list model
  /// only needs scalar fields, so keep those and drop relations.
  static Map<String, dynamic> _flattenCategory(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map<String, dynamic>);
    map
      ..remove("parent")
      ..remove("children");
    final count = map["_count"];
    if (count is Map<String, dynamic> && count["products"] is num) {
      map["_count"] = {"products": count["products"]};
    }
    return map;
  }

  // ---------- products ----------
  Future<Paged<Product>> listProducts({
    String? search,
    bool? isActive,
    String? sort,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        "page": page,
        "limit": 20,
      };
      if (search != null && search.isNotEmpty) {
        queryParams["search"] = search;
      }
      if (isActive != null) {
        queryParams["isActive"] = isActive.toString();
      }
      if (sort != null && sort != "newest") {
        queryParams["sort"] = sort;
      }
      final response = await _dio.get<Map<String, dynamic>>(
        "/admin/products",
        queryParameters: queryParams,
      );
      return Paged.fromJson<Product>(response.data ?? {}, Product.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Product> createProduct({
    required String title,
    required double price,
    required String categoryId,
    String? description,
    double? compareAtPrice,
    String? sku,
    int stockQty = 0,
    bool isActive = true,
  }) async {
    try {
      final payload = <String, dynamic>{
        "title": title,
        "price": price,
        "categoryId": categoryId,
        "stockQty": stockQty,
        "isActive": isActive,
      };
      if (description != null && description.isNotEmpty) {
        payload["description"] = description;
      }
      if (compareAtPrice != null) {
        payload["compareAtPrice"] = compareAtPrice;
      }
      if (sku != null && sku.isNotEmpty) {
        payload["sku"] = sku;
      }
      final response = await _dio.post<Map<String, dynamic>>(
        "/admin/products",
        data: payload,
      );
      return Product.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Product> updateProduct(
    String id, {
    String? title,
    double? price,
    String? categoryId,
    String? description,
    double? compareAtPrice,
    bool clearCompareAtPrice = false,
    String? sku,
    int? stockQty,
    bool? isActive,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (title != null) {
        payload["title"] = title;
      }
      if (price != null) {
        payload["price"] = price;
      }
      if (categoryId != null) {
        payload["categoryId"] = categoryId;
      }
      if (description != null) {
        payload["description"] = description;
      }
      if (clearCompareAtPrice) {
        payload["compareAtPrice"] = null;
      } else if (compareAtPrice != null) {
        payload["compareAtPrice"] = compareAtPrice;
      }
      if (sku != null && sku.isNotEmpty) {
        payload["sku"] = sku;
      }
      if (stockQty != null) {
        payload["stockQty"] = stockQty;
      }
      if (isActive != null) {
        payload["isActive"] = isActive;
      }
      final response = await _dio.put<Map<String, dynamic>>(
        "/admin/products/$id",
        data: payload,
      );
      return Product.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Returns true when the product was soft-deactivated (has order history).
  Future<bool> deleteProduct(String id) async {
    try {
      final response =
          await _dio.delete<Map<String, dynamic>>("/admin/products/$id");
      final data = response.data?["data"] as Map<String, dynamic>?;
      return data?["softDeleted"] as bool? ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ProductImage>> addImages(String productId, List<String> filePaths) async {
    try {
      final form = FormData();
      for (final path in filePaths) {
        form.files.add(
          MapEntry("images", await MultipartFile.fromFile(path)),
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        "/admin/products/$productId/images",
        data: form,
      );
      return ((response.data?["data"] as List<dynamic>?) ?? [])
          .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteImage(String productId, String imageId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        "/admin/products/$productId/images/$imageId",
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------- orders ----------
  Future<Paged<Order>> listOrders({String? status, int page = 1}) async {
    try {
      final queryParams = <String, dynamic>{
        "page": page,
        "limit": 20,
      };
      if (status != null && status != "ALL") {
        queryParams["status"] = status;
      }
      final response = await _dio.get<Map<String, dynamic>>(
        "/admin/orders",
        queryParameters: queryParams,
      );
      return Paged.fromJson<Order>(response.data ?? {}, Order.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> updateOrderStatus(String id, String status) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        "/admin/orders/$id/status",
        data: {"status": status},
      );
      return Order.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

final dashboardProvider = FutureProvider.autoDispose<Dashboard>((ref) {
  return ref.watch(adminRepositoryProvider).dashboard();
});

/// Key: "$search|$role|$page"
final adminUsersProvider =
    FutureProvider.autoDispose.family<Paged<AdminUserAccount>, String>((ref, key) {
  final parts = key.split("|");
  return ref.watch(adminRepositoryProvider).listUsers(
        search: parts[0].isEmpty ? null : parts[0],
        role: parts[1] == "ALL" ? null : parts[1],
        page: int.tryParse(parts[2]) ?? 1,
      );
});

/// Key: "$search|$isActiveFilter|$sort|$page" (isActiveFilter: all|true|false)
final adminProductsProvider =
    FutureProvider.autoDispose.family<Paged<Product>, String>((ref, key) {
  final parts = key.split("|");
  return ref.watch(adminRepositoryProvider).listProducts(
        search: parts[0].isEmpty ? null : parts[0],
        isActive: parts[1] == "all" ? null : parts[1] == "true",
        sort: parts[2] == "newest" ? null : parts[2],
        page: int.tryParse(parts[3]) ?? 1,
      );
});

/// Key: status filter ("ALL", "PENDING", ...)
final adminOrdersProvider =
    FutureProvider.autoDispose.family<Paged<Order>, String>((ref, status) {
  return ref.watch(adminRepositoryProvider).listOrders(status: status);
});