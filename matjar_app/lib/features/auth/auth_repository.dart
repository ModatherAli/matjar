import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network.dart";
import "../../core/storage.dart";
import "user.dart";

/// Talks to `/api/v1/auth` + `/api/v1/users/me`.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<AuthPayload> _savePayload(Map<String, dynamic> envelope) async {
    final payload =
        AuthPayload.fromJson(envelope["data"] as Map<String, dynamic>);
    await _storage.writeTokens(
      accessToken: payload.accessToken,
      refreshToken: payload.refreshToken,
    );
    return payload;
  }

  Future<AuthPayload> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "/auth/register",
        data: {"email": email, "password": password, "name": name},
      );
      return _savePayload(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "/auth/login",
        data: {"email": email, "password": password},
      );
      return _savePayload(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AppUser?> restoreSession() async {
    final access = await _storage.readAccess();
    if (access == null || access.isEmpty) {
      return null;
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>("/users/me");
      return AppUser.fromJson(
        response.data!["data"] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clear();
        return null;
      }
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() => _storage.clear();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});

