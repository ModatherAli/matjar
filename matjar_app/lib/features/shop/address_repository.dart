import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models.dart";
import "../../core/network.dart";

/// Shipping addresses: list + create + delete.
class AddressRepository {
  AddressRepository(this._dio);

  final Dio _dio;

  Future<List<Address>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>("/addresses");
      return ((response.data?["data"] as List<dynamic>?) ?? [])
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Address> create({
    required String street,
    required String city,
    required String country,
    String label = "home",
    String? zip,
    bool isDefault = false,
  }) async {
    try {
      final addressData = <String, dynamic>{
        "label": label,
        "street": street,
        "city": city,
        "country": country,
        "isDefault": isDefault,
      };
      if (zip != null && zip.isNotEmpty) {
        addressData["zip"] = zip;
      }
      final response = await _dio.post<Map<String, dynamic>>(
        "/addresses",
        data: addressData,
      );
      return Address.fromJson(response.data!["data"] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>("/addresses/$id");
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(dioProvider));
});

final addressesProvider = FutureProvider<List<Address>>((ref) {
  return ref.watch(addressRepositoryProvider).list();
});