import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/features/daily_wash/data/models/service_price_model.dart';

class DoorStepFormRemoteDataSource {
  DoorStepFormRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ServicePriceModel> getServicePrice(String service) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'services_price.php',
      data: <String, dynamic>{'service': service},
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response');
    }
    return ServicePriceModel.fromJson(data);
  }

  Future<Map<String, dynamic>> submitCustomerForm({
    required String name,
    required String mobile,
    required String email,
    required String addressLine,
    required String landmark,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required String vehicleType,
    required String make,
    required String model,
    required String category,
    required String form,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'service_customer_form.php',
      data: <String, dynamic>{
        'name': name,
        'mobile': mobile,
        'email': email,
        'address_line': addressLine,
        'landmark': landmark,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
        'vehicle_type': vehicleType,
        'make': make,
        'model': model,
        'category': category,
        'form': form,
      },
    );
    return response.data ?? <String, dynamic>{};
  }
}
