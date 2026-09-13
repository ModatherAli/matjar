import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network.dart";

/// Profile: update own name/phone and change password.
class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<void> updateMe({String? name, String? phone}) async {
    try {
      final data = <String, dynamic>{"phone": phone};
      if (name != null && name.isNotEmpty) {
        data["name"] = name;
      }
      await _dio.put<Map<String, dynamic>>(
        "/users/me",
        data: data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        "/users/me/password",
        data: {"currentPassword": currentPassword, "newPassword": newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});