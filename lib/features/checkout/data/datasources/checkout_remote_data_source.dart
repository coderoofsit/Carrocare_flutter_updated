import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';

class CheckoutRemoteDataSource {
  CheckoutRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getRazorpayMode() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      'razorpay_mode.php',
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> validateCheckout({
    required String customerId,
    required String vehicleId,
    required String serviceType,
    String? subsType,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'validate_checkout.php',
      data: <String, dynamic>{
        'customer_id': customerId,
        'vehicle_id': vehicleId,
        'service_type': serviceType,
        if (subsType != null && subsType.isNotEmpty) 'subs_type': subsType,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> oneTimeWashCheckout({
    required String customerId,
    required String packAmount,
    required String vehicleId,
    required String serviceType,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'onetime_wash_checkout.php',
      data: <String, dynamic>{
        'customer_id': customerId,
        'pack_amount': packAmount,
        'vehicle_id': vehicleId,
        'service_type': serviceType,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> saveOrderOneTime({
    required String action,
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
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': action,
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
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> saveWashOrderOneTime({
    required String paymentId,
    required String customerId,
    required String token,
    required String packAmount,
    required String vehicleId,
    required String paidMonths,
    required String fineAmount,
    required String subTotal,
    required String gst,
    required String gstAmount,
    required String totalAmount,
    required String serviceType,
    required String packType,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': 'onetime_wash_payment',
        'payment_id': paymentId,
        'rzp_order_id': '',
        'customer_id': customerId,
        'token': token,
        'pack_amount': packAmount,
        'vehicle_id': vehicleId,
        'paid_months': paidMonths,
        'fine_amount': fineAmount,
        'sub_tot_amt': subTotal,
        'gst': gst,
        'gst_amount': gstAmount,
        'tot_amt': totalAmount,
        'service_type': serviceType,
        'pack_type': packType,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> saveAddOnOrderOneTime({
    required String paymentId,
    required String customerId,
    required String token,
    required String packAmount,
    required String vehicleId,
    required String paidMonths,
    required String fineAmount,
    required String subTotal,
    required String gst,
    required String gstAmount,
    required String totalAmount,
    required String scheduleDate,
    required String scheduleTime,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': 'onetime_wash_payment',
        'payment_id': paymentId,
        'rzp_order_id': '',
        'customer_id': customerId,
        'token': token,
        'pack_amount': packAmount,
        'vehicle_id': vehicleId,
        'paid_months': paidMonths,
        'fine_amount': fineAmount,
        'sub_tot_amt': subTotal,
        'gst': gst,
        'gst_amount': gstAmount,
        'tot_amt': totalAmount,
        'service_type': 'AddOn',
        'pack_type': '',
        'schedule_date': scheduleDate,
        'schedule_time': scheduleTime,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createRazorpayOrderId({
    required String amount,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': 'create_orderid',
        'amount': amount,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> tempWashOrder({
    required String razorpayOrderId,
    required String customerId,
    required String token,
    required String packAmount,
    required String vehicleId,
    required String paidMonths,
    required String fineAmount,
    required String subTotal,
    required String gst,
    required String gstAmount,
    required String totalAmount,
    required String serviceType,
    required String packType,
    required String successAction,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': 'temp_order',
        'rzp_order_id': razorpayOrderId,
        'customer_id': customerId,
        'token': token,
        'pack_amount': packAmount,
        'vehicle_id': vehicleId,
        'paid_months': paidMonths,
        'fine_amount': fineAmount,
        'sub_tot_amt': subTotal,
        'gst': gst,
        'gst_amount': gstAmount,
        'tot_amt': totalAmount,
        'service_type': serviceType,
        'pack_type': packType,
        'success_action': successAction,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> tempAddOnOrder({
    required String razorpayOrderId,
    required String customerId,
    required String token,
    required String packAmount,
    required String vehicleId,
    required String paidMonths,
    required String fineAmount,
    required String subTotal,
    required String gst,
    required String gstAmount,
    required String totalAmount,
    required String serviceType,
    required String packType,
    required String scheduleDate,
    required String scheduleTime,
    required String successAction,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': 'temp_order',
        'rzp_order_id': razorpayOrderId,
        'customer_id': customerId,
        'token': token,
        'pack_amount': packAmount,
        'vehicle_id': vehicleId,
        'paid_months': paidMonths,
        'fine_amount': fineAmount,
        'sub_tot_amt': subTotal,
        'gst': gst,
        'gst_amount': gstAmount,
        'tot_amt': totalAmount,
        'service_type': serviceType,
        'pack_type': packType,
        'schedule_date': scheduleDate,
        'schedule_time': scheduleTime,
        'success_action': successAction,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> tempExtraOrder({
    required String razorpayOrderId,
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
    required String successAction,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': 'temp_order',
        'rzp_order_id': razorpayOrderId,
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
        'success_action': successAction,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchPlansList({
    String? vehicleType,
    String? serviceType,
    String? packType,
    String? packAmount,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'plans_list.php',
      data: <String, dynamic>{
        if (vehicleType != null && vehicleType.isNotEmpty)
          'vehi_type': vehicleType,
        if (serviceType != null && serviceType.isNotEmpty)
          'serv_type': serviceType,
        if (packType != null && packType.isNotEmpty) 'pack_type': packType,
        if (packAmount != null && packAmount.isNotEmpty)
          'pack_amount': packAmount,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getPlan({
    required String token,
    required String packType,
    required String packAmount,
    required String vehicleType,
    required String serviceType,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'get_plan.php',
      data: <String, dynamic>{
        'token': token,
        'pack_type': packType,
        'pack_amount': packAmount,
        'vehi_type': vehicleType,
        'subs_type': 'Monthly',
        'serv_type': serviceType,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createSubscription({
    required String token,
    required String customerId,
    required String vehicleId,
    required String planId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'create_subscription.php',
      data: <String, dynamic>{
        'token': token,
        'customer_id': customerId,
        'vehicle_id': vehicleId,
        'plan_id': planId,
        'no_of_count': CheckoutConstants.subscriptionMonthsCount.toString(),
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createSubscriptionOrderId({
    required String customerId,
    required String token,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': 'create_subscription_orderid',
        'customer_id': customerId,
        'token': token,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> saveMonthlySubscriptionOrder({
    required String orderId,
    required String planId,
    required String subscriptionId,
    required String customerId,
    required String vehicleId,
    required String token,
    required String serviceType,
    required String totalAmount,
    required String subTotal,
    required String gst,
    required String gstAmount,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'save_order.php',
      data: <String, dynamic>{
        'action': CheckoutConstants.actionMonthly,
        'order_id': orderId,
        'plan_id': planId,
        'subscription_id': subscriptionId,
        'customer_id': customerId,
        'token': token,
        'vehicle_id': vehicleId,
        'service_type': serviceType,
        'tot_amt': totalAmount,
        'sub_tot_amt': subTotal,
        'gst': gst,
        'gst_amount': gstAmount,
      },
    );
    return response.data ?? <String, dynamic>{};
  }
}
