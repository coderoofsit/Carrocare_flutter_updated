import 'package:carrocare_flutter/core/auth/session_expired_handler.dart';
import 'package:carrocare_flutter/core/constants/api_platform_mode.dart';
import 'package:carrocare_flutter/core/network/api_response_parser.dart';
import 'package:carrocare_flutter/core/network/auth_token_service.dart';
import 'package:dio/dio.dart';

/// Adds customer access Bearer token and `mode=Android` on API requests.
class ApiRequestInterceptor extends Interceptor {
  ApiRequestInterceptor(
    this._authTokens,
    this._sessionExpired,
    this._dio,
  );

  final AuthTokenService _authTokens;
  final SessionExpiredHandler _sessionExpired;
  final Dio _dio;

  static const String authRetryKey = 'authRetry';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _authTokens.bearerAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Allow request through; server will respond with auth error.
    }
    _ensureAndroidMode(options);
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_shouldRetryAuth(response)) {
      try {
        await _authTokens.refreshAccessToken();
        final retried = await _retryRequest(response.requestOptions);
        return handler.resolve(retried);
      } catch (_) {
        await _sessionExpired.handleFromApi();
      }
    } else if (_isLegacySessionExpired(response)) {
      await _sessionExpired.handleFromApi();
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response != null && _shouldRetryAuth(response)) {
      try {
        await _authTokens.refreshAccessToken();
        final retried = await _retryRequest(response.requestOptions);
        return handler.resolve(retried);
      } catch (_) {
        await _sessionExpired.handleFromApi();
      }
    } else if (response != null && _isLegacySessionExpired(response)) {
      await _sessionExpired.handleFromApi();
    }
    handler.next(err);
  }

  bool _isLegacySessionExpired(Response<dynamic> response) {
    if (_isAuthEndpoint(response.requestOptions.path)) {
      return false;
    }
    final data = _responseMap(response.data);
    if (data == null) return false;
    return (data['code'] ?? '').toString() == '203';
  }

  bool _isAuthEndpoint(String path) {
    final lower = path.toLowerCase();
    return lower.contains('login.php') ||
        lower.contains('register.php') ||
        lower.contains('refresh-token.php') ||
        lower.contains('logout.php') ||
        lower.contains('send_otp') ||
        lower.contains('forgot');
  }

  bool _shouldRetryAuth(Response<dynamic> response) {
    if (response.requestOptions.extra[authRetryKey] == true) {
      return false;
    }
    final data = _responseMap(response.data);
    if (data == null || data['error'] != true) {
      return false;
    }
    final message = (data['message'] ?? '').toString().toLowerCase();
    return message.contains('unauthorized') || message.contains('invalid hash');
  }

  Map<String, dynamic>? _responseMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String && data.isNotEmpty) {
      try {
        return ApiResponseParser.decode(data);
      } catch (_) {}
    }
    return null;
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions options) async {
    final accessToken = await _authTokens.bearerAccessToken();
    final headers = Map<String, dynamic>.from(options.headers);
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return _dio.fetch<dynamic>(
      options.copyWith(
        headers: headers,
        extra: Map<String, dynamic>.from(options.extra)
          ..[authRetryKey] = true,
      ),
    );
  }

  void _ensureAndroidMode(RequestOptions options) {
    final data = options.data;
    if (data is Map<String, dynamic>) {
      data.putIfAbsent('mode', () => ApiPlatformMode.android);
      options.data = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      map.putIfAbsent('mode', () => ApiPlatformMode.android);
      options.data = map;
    }
  }
}
