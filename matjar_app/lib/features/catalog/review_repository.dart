import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models.dart";
import "../../core/network.dart";

/// Reviews on a product: create / update / delete the caller's own review.
/// The backend only allows reviewing products from a delivered order.
Map<String, dynamic> reviewPayload(int rating, String? comment) {
  final data = <String, dynamic>{"rating": rating};
  if (comment != null && comment.isNotEmpty) {
    data["comment"] = comment;
  }
  return data;
}

class ReviewRepository {
  ReviewRepository(this._dio);

  final Dio _dio;

  Future<Review> create(String productId, {required int rating, String? comment}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "/products/$productId/reviews",
        data: reviewPayload(rating, comment),
      );
      return Review.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Review> update(String productId, {required int rating, String? comment}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        "/products/$productId/reviews",
        data: reviewPayload(rating, comment),
      );
      return Review.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String productId) async {
    try {
      await _dio.delete<Map<String, dynamic>>("/products/$productId/reviews");
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(dioProvider));
});