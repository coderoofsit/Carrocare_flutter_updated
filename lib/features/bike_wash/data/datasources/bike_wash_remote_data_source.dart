import 'package:carrocare_flutter/core/network/api_client.dart';

class BikeWashRemoteDataSource {
  BikeWashRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getBikeWashRawResponse() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'services_price.php',
      data: <String, dynamic>{'service': 'daily_car_wash'},
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response');
    }

    return data;
  }
}
