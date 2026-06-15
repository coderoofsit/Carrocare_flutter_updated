import 'package:carrocare_flutter/core/network/api_client.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getProfile({
    required String token,
    required String customerId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'profile_details.php',
      data: <String, dynamic>{
        'token': token,
        'customer_id': customerId,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String customerId,
    required String apartmentName,
    required String apartmentBuilding,
    required String flatNo,
    required String address,
    required String latitude,
    required String longitude,
    required String gst,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'profile_update.php',
      data: <String, dynamic>{
        'token': token,
        'customer_id': customerId,
        'apartment_name': apartmentName,
        'apartment_building': apartmentBuilding,
        'flat_no': flatNo,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'gst': gst,
      },
    );
    return response.data ?? <String, dynamic>{};
  }
}
