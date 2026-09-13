import "dart:async";

import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "config.dart";
import "storage.dart";

/// Human-readable API failure surfaced to the UI.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  static ApiException fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data["error"];
      if (error is Map<String, dynamic> && error["message"] is String) {
        return ApiException(
          error["message"] as String,
          statusCode: e.response?.statusCode,
        );
      }
      if (data["message"] is String) {
        return ApiException(
          data["message"] as String,
          statusCode: e.response?.statusCode,
        );
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          "Connection timed out. Check that the backend is running.",
          statusCode: e.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          "Cannot reach the server. Is the backend running?",
          statusCode: e.response?.statusCode,
        );
      default:
        return ApiException(
          "Something went wrong. Please try again.",
          statusCode: e.response?.statusCode,
        );
    }
  }
}

const List<String> _publicPaths = [
  "/auth/login",
  "/auth/register",
  "/auth/refresh",
];

/// Attaches the access token and transparently refreshes it once on 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;
  Completer<void>? _refreshCompleter;

  bool _isPublic(String path) =>
      _publicPaths.any((public) => path.endsWith(public));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final access = await _ref.read(tokenStorageProvider).readAccess();
      if (access != null && access.isNotEmpty) {
        options.headers["Authorization"] = "Bearer $access";
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final alreadyRetried = request.extra["matjarRetried"] == true;

    if (err.response?.statusCode != 401 ||
        alreadyRetried ||
        _isPublic(request.path)) {
      return handler.next(err);
    }

    try {
      await _refreshOnce();
    } catch (_) {
      await _ref.read(tokenStorageProvider).clear();
      _ref.invalidate(sessionSignalProvider);
      return handler.next(err);
    }

    final access = await _ref.read(tokenStorageProvider).readAccess();
    if (access == null || access.isEmpty) {
      return handler.next(err);
    }

    final dio = _ref.read(dioProvider);
    try {
      final response = await dio.request<dynamic>(
        request.path,
        data: request.data,
        queryParameters: request.queryParameters,
        options: Options(
          method: request.method,
          headers: {
            ...request.headers,
            "Authorization": "Bearer $access",
          },
          responseType: request.responseType,
          contentType: request.contentType,
        ),
      );
      return handler.resolve(response);
    } catch (e) {
      return handler.next(e is DioException ? e : err);
    }
  }

  /// Single-flight refresh: concurrent 401s share one refresh call.
  Future<void> _refreshOnce() {
    final inflight = _refreshCompleter;
    if (inflight != null) {
      return inflight.future;
    }
    final completer = Completer<void>();
    _refreshCompleter = completer;
    _doRefresh().then((_) {
      _refreshCompleter = null;
      completer.complete();
    }).catchError((Object e) {
      _refreshCompleter = null;
      completer.completeError(e);
    });
    return completer.future;
  }

  Future<void> _doRefresh() async {
    final storage = _ref.read(tokenStorageProvider);
    final refresh = await storage.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      throw ApiException("Session expired. Please log in again.");
    }
    final plain = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiPrefix,
        headers: {"Content-Type": "application/json"},
      ),
    );
    final response = await plain.post<Map<String, dynamic>>(
      "/auth/refresh",
      data: {"refreshToken": refresh},
    );
    final data = response.data?["data"] as Map<String, dynamic>?;
    final accessToken = data?["accessToken"] as String?;
    final refreshToken = data?["refreshToken"] as String?;
    if (accessToken == null || refreshToken == null) {
      throw ApiException("Session expired. Please log in again.");
    }
    await storage.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}

/// Bumped to force router rebuilds on session changes.
final sessionSignalProvider = NotifierProvider<SessionSignal, int>(SessionSignal.new);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.apiPrefix,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {"Content-Type": "application/json"},
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));
  return dio;
});




/// Invalidated to force router rebuilds on session changes.
class SessionSignal extends Notifier<int> {
  @override
  int build() => 0;
}
