import 'dart:convert';

import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/network/save_order_post.dart';

class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getInternalOrders({
    required String token,
    required String customerId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'order_list_ext.php',
      data: <String, dynamic>{
        'token': token,
        'customer_id': customerId,
      },
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getOrders({
    required String token,
    required String customerId,
  }) {
    return postApiWithRetry(
      _apiClient.dio,
      'order_list.php',
      <String, dynamic>{
        'token': token,
        'customer_id': customerId,
      },
    );
  }

  Future<Map<String, dynamic>> getWashDetails({
    required String token,
    required String customerId,
    required String vehicleId,
    required String orderId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'customer_wash_details.php',
      data: <String, dynamic>{
        'token': token,
        'customer_id': customerId,
        'vehicle_id': vehicleId,
        'order_id': orderId,
      },
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getExtraInteriorDetails({
    required String token,
    required String customerId,
    required String vehicleId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'extrainterior.php',
      data: <String, dynamic>{
        'token': token,
        'customer_id': customerId,
        'vehicle_id': vehicleId,
      },
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> cancelSubscription({
    required String token,
    required String vehicleId,
    required String orderId,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'cancel_subscription.php',
      data: <String, dynamic>{
        'token': token,
        'vehicle_id': vehicleId,
        'order_id': orderId,
      },
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> cancelCodOrder({
    required String orderId,
    required String customerId,
    required String reason,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'cancel_cod_order.php',
      data: <String, dynamic>{
        'order_id': orderId,
        'customer_id': customerId,
        'reason': reason,
      },
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> scheduleInternalCleanNew({
    required String token,
    required String customerId,
    required String vehicleId,
    required String orderId,
    required String scheduleDate1,
    required String scheduleTime1,
    required String comment1,
    required String scheduleDate2,
    required String scheduleTime2,
    required String comment2,
    required String id,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'internal_clean_schedule_new.php',
      data: <String, dynamic>{
        'token': token,
        'customer_id': customerId,
        'vehicle_id': vehicleId,
        'order_id': orderId,
        'schedule_date1': scheduleDate1,
        'schedule_time1': scheduleTime1,
        'comment_box1': comment1,
        'schedule_date2': scheduleDate2,
        'schedule_time2': scheduleTime2,
        'comment_box2': comment2,
        'id': id,
      },
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> scheduleInternalClean({
    required String token,
    required String customerId,
    required String vehicleId,
    required String orderId,
    required String scheduleDate,
    required String scheduleTime,
    required String comment,
    required String dateType,
    required String id,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'internal_clean_schedule.php',
      data: <String, dynamic>{
        'token': token,
        'customer_id': customerId,
        'vehicle_id': vehicleId,
        'order_id': orderId,
        'schedule_date': scheduleDate,
        'schedule_time': scheduleTime,
        'comment_box': comment,
        'date_type': dateType,
        'id': id,
      },
    );
    return _asMap(response.data);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is String && data.isNotEmpty) {
      try {
        return _asMap(jsonDecode(data));
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }
}
