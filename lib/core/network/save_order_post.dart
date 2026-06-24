import 'package:dio/dio.dart';

/// Posts to save_order.php with one retry on transient connection errors
/// (common right after Razorpay closes on Android).
Future<Map<String, dynamic>> postSaveOrderWithRetry(
  Dio dio,
  Map<String, dynamic> data, {
  int maxAttempts = 2,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'save_order.php',
        data: data,
      );
      return response.data ?? <String, dynamic>{};
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

bool _isTransientConnectionError(DioException e) {
  if (e.type == DioExceptionType.connectionError) {
    return true;
  }
  final message = '${e.error ?? e.message ?? ''}'.toLowerCase();
  return message.contains('connection closed') ||
      message.contains('connection reset') ||
      message.contains('broken pipe');
}
