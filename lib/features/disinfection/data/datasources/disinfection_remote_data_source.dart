import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/features/daily_wash/data/models/service_price_model.dart';

class DisinfectionRemoteDataSource {
  DisinfectionRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ServicePriceModel> getDisinfectionServices() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'disinfection.php',
      data: <String, dynamic>{'action': 'disinfection'},
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response');
    }
    return ServicePriceModel.fromJson(data);
  }
}
