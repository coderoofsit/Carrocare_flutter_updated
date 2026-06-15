import 'package:carrocare_flutter/core/network/api_client.dart';

class BillingRemoteDataSource {
  BillingRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getBillings({
    required String token,
    required String customerId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'invoice_list.php',
      data: <String, dynamic>{
        'token': token,
        'customer_id': customerId,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }
}
