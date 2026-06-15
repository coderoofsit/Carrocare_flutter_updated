import 'package:carrocare_flutter/core/network/api_client.dart';

class DoorStepRemoteDataSource {
  DoorStepRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getDoorStepServices({
    required String action,
    required String vehicleCategory,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'doorstep_details.php',
      data: <String, dynamic>{
        'action': action,
        'type': vehicleCategory,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> saveDoorstepCodOrder({
    required String customerId,
    required String token,
    required String packType,
    required String packAmount,
    required String vehicleId,
    required String serviceType,
    required String subTotal,
    required String gst,
    required String gstAmount,
    required String totalAmount,
    required String scheduleDate,
    required String scheduleTime,
    required String address,
    required String latitude,
    required String longitude,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': 'doorstep_payment',
        'customer_id': customerId,
        'token': token,
        'pack_type': packType,
        'pack_amount': packAmount,
        'vehicle_id': vehicleId,
        'service_type': serviceType,
        'sub_tot_amt': subTotal,
        'gst': gst,
        'gst_amount': gstAmount,
        'tot_amt': totalAmount,
        'schedule_date': scheduleDate,
        'schedule_time': scheduleTime,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return response.data ?? <String, dynamic>{};
  }
}
