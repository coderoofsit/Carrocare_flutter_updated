import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/network/save_order_post.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/doorstep_package.dart';

class DoorStepRemoteDataSource {
  DoorStepRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<DoorstepPackagesResponse> getDoorstepPackages({
    String? category,
  }) async {
    final data = <String, dynamic>{'action': 'packages'};
    if (category != null && category.isNotEmpty && category != 'all') {
      data['category'] = category;
    }
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'doorstep_details.php',
      data: data,
    );
    final payload = response.data ?? <String, dynamic>{};
    final code = (payload['code'] ?? '').toString();
    final status = (payload['status'] ?? '').toString().toLowerCase();
    if (code != '200' && status != 'success') {
      throw Exception(
        (payload['result'] ?? payload['message'] ?? 'Failed to load doorstep services')
            .toString(),
      );
    }
    return DoorstepPackagesResponse.fromJson(payload);
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

  Future<Map<String, dynamic>> saveDoorstepOnlineOrder({
    required String paymentId,
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
    return postSaveOrderWithRetry(
      _apiClient.dio,
      <String, dynamic>{
        'action': 'onetime_payment',
        'order_id': paymentId,
        'rzp_order_id': '',
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
  }
}
