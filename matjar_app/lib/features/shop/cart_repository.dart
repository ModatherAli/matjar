import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models.dart";
import "../../core/network.dart";

/// Cart endpoints. Mutations invalidate [cartProvider] via [CartHandle].
class CartRepository {
  CartRepository(this._dio);

  final Dio _dio;

  Future<Cart> getCart() async => _readCart(() => _dio.get<Map<String, dynamic>>("/cart"));

  Future<Cart> addItem(String productId, int quantity) async => _readCart(
        () => _dio.post<Map<String, dynamic>>(
          "/cart/items",
          data: {"productId": productId, "quantity": quantity},
        ),
      );

  Future<Cart> updateItem(String itemId, int quantity) async => _readCart(
        () => _dio.patch<Map<String, dynamic>>(
          "/cart/items/$itemId",
          data: {"quantity": quantity},
        ),
      );

  Future<Cart> removeItem(String itemId) async =>
      _readCart(() => _dio.delete<Map<String, dynamic>>("/cart/items/$itemId"));

  Future<Cart> clearCart() async =>
      _readCart(() => _dio.delete<Map<String, dynamic>>("/cart"));

  Future<Cart> _readCart(Future<Response<Map<String, dynamic>>> Function() call) async {
    try {
      final response = await call();
      return Cart.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(dioProvider));
});

final cartProvider = FutureProvider.autoDispose<Cart>((ref) {
  return ref.watch(cartRepositoryProvider).getCart();
});

/// Live badge count for the app bar; 0 while the cart is unavailable.
final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.maybeWhen(data: (value) => value.itemCount, orElse: () => 0);
});