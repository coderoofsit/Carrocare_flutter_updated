import 'package:dio/dio.dart';

/// Posts to a legacy PHP endpoint with one retry on transient connection errors
/// (common right after Razorpay closes on Android).
Future<Map<String, dynamic>> postApiWithRetry(
  Dio dio,
  String path,
  Map<String, dynamic> data, {
  int maxAttempts = 2,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final response = await dio.post<dynamic>(
        path,
        data: data,
      );
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return body;
      }
      if (body is Map) {
        return body.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      return <String, dynamic>{};
    } on DioException catch (e) {
      final isRetryable =
          attempt < maxAttempts && _isTransientConnectionError(e);
      if (!isRetryable) {
        rethrow;
      }
    }
  }
  return <String, dynamic>{};
}

Future<Map<String, dynamic>> postSaveOrderWithRetry(
  Dio dio,
  Map<String, dynamic> data, {
  int maxAttempts = 2,
}) {
  return postApiWithRetry(
    dio,
    'save_order.php',
    data,
    maxAttempts: maxAttempts,
  );
}

bool _isTransientConnectionError(DioException e) {
  if (e.type == DioExceptionType.connectionError) {
    return true;
  }
  final message = '${e.error ?? e.message ?? ''}'.toLowerCase();
  return message.contains('connection closed') ||
      message.contains('connection reset') ||
      message.contains('broken pipe');
}
