import 'package:carrocare_flutter/core/auth/session_expired_handler.dart';
import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:carrocare_flutter/core/network/api_request_interceptor.dart';
import 'package:carrocare_flutter/core/network/api_response_parser.dart';
import 'package:carrocare_flutter/core/network/auth_token_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient(this._authTokens, this._sessionExpired)
    : dio = Dio(
        BaseOptions(
          baseUrl: AppUrls.apiBaseUrl,
          contentType: Headers.formUrlEncodedContentType,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 45),
          responseType: ResponseType.plain,
          headers: const <String, dynamic>{
            'Accept': 'application/json',
          },
        ),
      ) {
    _authTokens.onSessionExpired = _sessionExpired.handle;
    dio.interceptors.add(
      ApiRequestInterceptor(_authTokens, _sessionExpired, dio),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final raw = response.data;
          if (raw is String && raw.isNotEmpty) {
            try {
              response.data = ApiResponseParser.decode(raw);
            } catch (error, stackTrace) {
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  error: error,
                  stackTrace: stackTrace,
                  type: DioExceptionType.badResponse,
                  message: 'Invalid server response',
                ),
              );
              return;
            }
          }
          handler.next(response);
        },
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }

  final Dio dio;
  final AuthTokenService _authTokens;
  final SessionExpiredHandler _sessionExpired;

  AuthTokenService get authTokens => _authTokens;

  /// After login, customer session token is sent in POST body as `token`.
  void setBearerToken(String token) {
    if (kDebugMode) {
      debugPrint('Customer session token updated');
    }
  }
}
