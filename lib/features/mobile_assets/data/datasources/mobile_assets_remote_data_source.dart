import 'package:carrocare_flutter/core/network/api_client.dart';

class MobileAssetsRemoteDataSource {
  MobileAssetsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchMobileAssets() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      'mobile-assets.php',
    );
    final data = response.data;
    if (data == null || data['status'] != 'success') {
      throw Exception('Failed to load mobile assets');
    }
    return data;
  }
}
