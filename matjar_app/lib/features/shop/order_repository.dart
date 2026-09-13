import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models.dart";
import "../../core/network.dart";

/// Orders: checkout, list (with status filter), detail, cancel.
Map<String, dynamic> orderListParams(String? status, int page, int limit) {
  final params = <String, dynamic>{
    "page": page,
    "limit": limit,
  };
  if (status != null && status != "ALL") {
    params["status"] = status;
  }
  return params;
}

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<Order> checkout({required String addressId, double shippingCost = 0}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "/orders/checkout",
        data: {"addressId": addressId, "shippingCost": shippingCost},
      );
      return Order.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Paged<Order>> list({String? status, int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        "/orders",
        queryParameters: orderListParams(status, page, limit),
      );
      return Paged.fromJson<Order>(response.data ?? {}, Order.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> get(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>("/orders/$id");
      return Order.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> cancel(String id) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>("/orders/$id/cancel");
      return Order.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(dioProvider));
});

/// Key is the status filter: "ALL", "PENDING", "PAID", "SHIPPED", ...
final ordersProvider =
    FutureProvider.autoDispose.family<Paged<Order>, String>((ref, status) {
  return ref.watch(orderRepositoryProvider).list(status: status);
});

final orderProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).get(id);
});