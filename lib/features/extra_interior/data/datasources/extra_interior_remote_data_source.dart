import 'package:carrocare_flutter/core/network/api_client.dart';

class ExtraInteriorRemoteDataSource {
  ExtraInteriorRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getExtraInteriorRawResponse() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'services_price.php',
      data: <String, dynamic>{'service': 'add_on_service'},
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response');
    }

    return data;
  }
}
