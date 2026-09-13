import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models.dart";
import "../../core/network.dart";

/// Query descriptor for the paginated product catalog.
class ProductQuery {
  const ProductQuery({
    this.search,
    this.categorySlug,
    this.sort,
    this.page = 1,
    this.limit = 12,
  });

  final String? search;
  final String? categorySlug;
  final String? sort;
  final int page;
  final int limit;

  ProductQuery copyWith({String? search, String? categorySlug, String? sort, int? page}) {
    return ProductQuery(
      search: search ?? this.search,
      categorySlug: categorySlug ?? this.categorySlug,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit,
    );
  }

  Map<String, dynamic> toQuery() {
    final query = <String, dynamic>{
      "page": page,
      "limit": limit,
    };
    if (search != null && search!.isNotEmpty) {
      query["search"] = search;
    }
    if (categorySlug != null && categorySlug!.isNotEmpty) {
      query["category"] = categorySlug;
    }
    if (sort != null && sort != "newest") {
      query["sort"] = sort;
    }
    return query;
  }

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.search == search &&
      other.categorySlug == categorySlug &&
      other.sort == sort &&
      other.page == page &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(search, categorySlug, sort, page, limit);
}

/// Public catalog endpoints: categories, products, product detail, reviews.
class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  Future<List<Category>> listCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>("/categories");
      return ((response.data?["data"] as List<dynamic>?) ?? [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Paged<Product>> listProducts(ProductQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        "/products",
        queryParameters: query.toQuery(),
      );
      return Paged.fromJson<Product>(
        response.data ?? {},
        (json) => Product.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Product> getProduct(String slug) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>("/products/$slug");
      return Product.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Paged<Review>> listReviews(String productId, {int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        "/products/$productId/reviews",
        queryParameters: {"page": page, "limit": limit},
      );
      return Paged.fromJson<Review>(
        response.data ?? {},
        (json) => Review.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(dioProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(catalogRepositoryProvider).listCategories();
});

final productsProvider =
    FutureProvider.autoDispose.family<Paged<Product>, ProductQuery>((ref, query) {
  return ref.watch(catalogRepositoryProvider).listProducts(query);
});

final productProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, slug) {
  return ref.watch(catalogRepositoryProvider).getProduct(slug);
});

final reviewsProvider =
    FutureProvider.autoDispose.family<Paged<Review>, String>((ref, productId) {
  return ref.watch(catalogRepositoryProvider).listReviews(productId);
});