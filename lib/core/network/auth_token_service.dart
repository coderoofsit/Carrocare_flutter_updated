import 'package:carrocare_flutter/core/constants/api_platform_mode.dart';
import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:carrocare_flutter/core/network/api_response_parser.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthExpiredException implements Exception {
  final String message;
  const AuthExpiredException(this.message);
  @override
  String toString() => message;
}

/// Persists and refreshes customer access/refresh tokens for API header auth.
class AuthTokenService {
  AuthTokenService()
    : _refreshDio = Dio(
        BaseOptions(
          baseUrl: AppUrls.apiBaseUrl,
          contentType: Headers.formUrlEncodedContentType,
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
          responseType: ResponseType.plain,
        ),
      );

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  final Dio _refreshDio;
  String? _cachedAccessToken;
  DateTime? _accessExpiresAt;
  Future<String>? _refreshInFlight;

  /// Invoked when access token renewal fails (missing or invalid refresh token).
  Future<void> Function()? onSessionExpired;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(accessTokenKey, accessToken);
    await prefs.setString(refreshTokenKey, refreshToken);
    _cachedAccessToken = accessToken;
    _accessExpiresAt =
        _expiryFromToken(accessToken) ??
        DateTime.now().add(const Duration(minutes: 14));
  }

  Future<String?> bearerAccessToken() async {
    final now = DateTime.now();
    if (_cachedAccessToken != null &&
        _accessExpiresAt != null &&
        now.isBefore(_accessExpiresAt!.subtract(const Duration(minutes: 2)))) {
      return _cachedAccessToken;
    }
    final prefs = await _prefs;
    final stored = prefs.getString(accessTokenKey);
    if (stored == null || stored.isEmpty) {
      return null;
    }
    final expiresAt =
        _expiryFromToken(stored) ?? now.add(const Duration(minutes: 14));
    if (now.isBefore(expiresAt.subtract(const Duration(minutes: 2)))) {
      _cachedAccessToken = stored;
      _accessExpiresAt = expiresAt;
      return stored;
    }
    try {
      return await refreshAccessToken();
    } on AuthExpiredException {
      await onSessionExpired?.call();
      return null;
    } catch (_) {
      // Temporary network/timeout error; preserve session rather than logging out.
      return stored;
    }
  }

  Future<String> refreshAccessToken() {
    _refreshInFlight ??= _performRefresh();
    return _refreshInFlight!.whenComplete(() => _refreshInFlight = null);
  }

  Future<String> _performRefresh() async {
    final prefs = await _prefs;
    final refreshToken = prefs.getString(refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthExpiredException('No refresh token');
    }
    try {
      final response = await _refreshDio.post<dynamic>(
        'refresh-token.php',
        data: <String, dynamic>{
          'refresh_token': refreshToken,
          'mode': ApiPlatformMode.android,
        },
      );
      final raw = response.data;
      final Map<String, dynamic> data = raw is String && raw.isNotEmpty
          ? ApiResponseParser.decode(raw)
          : (raw as Map<String, dynamic>? ?? <String, dynamic>{});
      final code = (data['code'] ?? '').toString();
      final message = (data['message'] ?? '').toString();
      if (code == '401' ||
          code == '403' ||
          message.toLowerCase().contains('invalid') ||
          message.toLowerCase().contains('expired')) {
        throw AuthExpiredException(
          message.isNotEmpty ? message : 'Invalid or expired refresh token',
        );
      }
      if (code != '200') {
        throw Exception(
          message.isNotEmpty ? message : 'Token refresh failed',
        );
      }
      final access = (data['access_token'] ?? '').toString();
      final refresh = (data['refresh_token'] ?? '').toString();
      if (access.isEmpty || refresh.isEmpty) {
        throw Exception('Token refresh response incomplete');
      }
      await saveTokens(accessToken: access, refreshToken: refresh);
      return access;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw const AuthExpiredException('Session expired');
      }
      rethrow;
    }
  }

  Future<bool> hasStoredSession() async {
    final prefs = await _prefs;
    final refresh = prefs.getString(refreshTokenKey);
    if (refresh != null && refresh.isNotEmpty) {
      return true;
    }
    final apiToken = prefs.getString('token');
    final customerId = prefs.getString('customer_id');
    return apiToken != null &&
        apiToken.isNotEmpty &&
        customerId != null &&
        customerId.isNotEmpty;
  }

  Future<void> clearTokens() async {
    final prefs = await _prefs;
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
    _cachedAccessToken = null;
    _accessExpiresAt = null;
  }

  DateTime? _expiryFromToken(String token) {
    try {
      final jwt = JWT.decode(token);
      final exp = jwt.payload['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (_) {}
    return null;
  }
}
