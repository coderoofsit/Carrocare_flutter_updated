import 'package:carrocare_flutter/core/network/api_client.dart';

class HelpRemoteDataSource {
  HelpRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> submitHelp({
    required String type,
    required String question,
    required String customerId,
    required String token,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'help_and_support.php',
      data: <String, dynamic>{
        'type': type,
        'question': question,
        'customer_id': customerId,
        'token': token,
      },
    );
    return response.data ?? <String, dynamic>{};
  }
}
