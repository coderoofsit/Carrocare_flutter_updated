import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/features/daily_wash/data/models/service_price_model.dart';

class DailyWashRemoteDataSource {
  DailyWashRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ServicePriceModel> getDailyCarWashServices() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'services_price.php',
      data: <String, dynamic>{
        'service': 'daily_car_wash',
        'type': 'car',
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response');
    }

    return ServicePriceModel.fromJson(data);
  }
}
