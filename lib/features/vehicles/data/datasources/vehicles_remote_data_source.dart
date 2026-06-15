import 'package:carrocare_flutter/core/constants/api_platform_mode.dart';
import 'package:carrocare_flutter/core/network/api_client.dart';

class VehiclesRemoteDataSource {
  VehiclesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> myVehicles({
    required String customerId,
    required String token,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'vehicle_details.php',
      data: <String, dynamic>{
        'customer_id': customerId,
        'token': token,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> vehiclesForBooking({
    required String customerId,
    required String token,
    required String category,
    required bool extraInterior,
  }) async {
    final data = <String, dynamic>{
      'customer_id': customerId,
      'token': token,
      'category': category,
    };
    if (extraInterior) {
      data['wash_vehicles'] = '';
    }
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'vehicle_details.php',
      data: data,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> apartmentList() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'apartment_list.php',
      data: <String, dynamic>{'mode': ApiPlatformMode.android},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> parkingAreaList() async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'parking_area.php',
      data: <String, dynamic>{'mode': ApiPlatformMode.android},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> makeModel(String category) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'car_make_model.php',
      data: <String, dynamic>{'vehicle_category': category},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> addVehicle({
    required String vehicleType,
    required String category,
    required String make,
    required String model,
    required String vehicleNo,
    required String color,
    required String apartmentName,
    required String parkingLotNo,
    required String parkingArea,
    required String preferredSchedule,
    required String preferredTime,
    required String customerId,
    required String token,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'vehicle_add.php',
      data: <String, dynamic>{
        'vehicle_type': vehicleType,
        'category': category,
        'make': make,
        'model': model,
        'vehicle_no': vehicleNo,
        'color': color,
        'apartment_name': apartmentName,
        'parking_lot_no': parkingLotNo,
        'parking_area': parkingArea,
        'preferred_schedule': preferredSchedule,
        'preferred_time': preferredTime,
        'customer_id': customerId,
        'token': token,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> addDoorstepVehicle({
    required String vehicleType,
    required String category,
    required String make,
    required String model,
    required String vehicleNo,
    required String color,
    required String customerId,
    required String token,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'vehicle_add.php',
      data: <String, dynamic>{
        'vehicle_type': vehicleType,
        'category': category,
        'make': make,
        'model': model,
        'vehicle_no': vehicleNo,
        'color': color,
        'customer_id': customerId,
        'token': token,
      },
    );
    return response.data ?? <String, dynamic>{};
  }
}
