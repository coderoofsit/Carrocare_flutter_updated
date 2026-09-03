import 'package:carrocare_flutter/features/checkout/core/cart_display_helper.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/checkout_plan.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/convert_subscription_eligibility.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/one_time_wash_checkout.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  CheckoutRepositoryImpl(this._remote);

  final CheckoutRemoteDataSource _remote;
  static const String _razorpayKeyId = 'rzp_test_SwKFnmjXZGAt93';

  @override
  Future<({String keyId, String secretKey})> getRazorpayKeys() async {
    try {
      final data = await _remote.getRazorpayMode();
      if ((data['code'] ?? '').toString() == '200') {
        final keyId = (data['keyid'] ?? data['key_id'] ?? '').toString();
        if (keyId.isNotEmpty) {
          return (
            keyId: keyId,
            secretKey: (data['secretkey'] ?? '').toString(),
          );
        }
      }
    } catch (_) {}
    return (
      keyId: _razorpayKeyId,
      secretKey: '',
    );
  }

  @override
  Future<List<CheckoutPlan>> fetchPlansList({
    String? vehicleType,
    String? serviceType,
    String? packType,
    String? packAmount,
  }) async {
    final data = await _remote.fetchPlansList(
      vehicleType: vehicleType,
      serviceType: serviceType,
      packType: packType,
      packAmount: packAmount,
    );
    final code = (data['code'] ?? '').toString();
    if (code != '200') {
      return <CheckoutPlan>[];
    }
    final plans = data['plans'];
    if (plans is! List) return <CheckoutPlan>[];
    return plans
        .whereType<Map>()
        .map(
          (row) => CheckoutPlan.fromJson(
            row.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  @override
  Future<String> resolveMonthlyPlanId({
    required String token,
    required String packType,
    required String packAmount,
    required String vehicleType,
    required String serviceType,
  }) async {
    final data = await _remote.getPlan(
      token: token,
      packType: packType,
      packAmount: packAmount,
      vehicleType: vehicleType,
      serviceType: serviceType,
    );
    final code = (data['code'] ?? '').toString();
    if (code != '200') {
      throw Exception((data['message'] ?? 'Plan validation failed').toString());
    }
    final planId = (data['plan_id'] ?? '').toString();
    if (planId.isEmpty) {
      throw Exception('Plan id missing');
    }
    return planId;
  }

  @override
  Future<SubscriptionCheckoutSession> createSubscription({
    required String token,
    required String customerId,
    required String vehicleId,
    required String planId,
    String? sourceOrderId,
  }) async {
    final data = await _remote.createSubscription(
      token: token,
      customerId: customerId,
      vehicleId: vehicleId,
      planId: planId,
      sourceOrderId: sourceOrderId,
    );
    final code = (data['code'] ?? '').toString();
    if (code != '200') {
      throw Exception(
        (data['result'] ?? data['message'] ?? 'Subscription failed').toString(),
      );
    }
    final subscriptionId = (data['subscription_id'] ?? '').toString();
    final keyId = (data['razorpay_keyid'] ?? _razorpayKeyId).toString();
    if (subscriptionId.isEmpty) {
      throw Exception('Subscription id missing');
    }
    return SubscriptionCheckoutSession(
      keyId: keyId,
      subscriptionId: subscriptionId,
      planId: (data['plan_id'] ?? planId).toString(),
      customerName: (data['customer_name'] ?? '').toString(),
      customerEmail: (data['customer_email'] ?? '').toString(),
      customerMobile: (data['customer_mobile'] ?? '').toString(),
    );
  }

  @override
  Future<ConvertSubscriptionEligibility> fetchConvertSubscriptionEligibility({
    required String token,
    required String customerId,
    required String orderId,
  }) async {
    final data = await _remote.fetchConvertSubscriptionEligibility(
      token: token,
      customerId: customerId,
      orderId: orderId,
    );
    final code = (data['code'] ?? '').toString();
    if (code != '200') {
      throw Exception(
        (data['message'] ?? data['result'] ?? 'Not eligible for auto-renew')
            .toString(),
      );
    }
    return ConvertSubscriptionEligibility.fromJson(data);
  }

  @override
  Future<String> saveConvertToSubscription({
    required String sourceOrderId,
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
    final data = await _remote.saveConvertToSubscription(
      sourceOrderId: sourceOrderId,
      planId: planId,
      subscriptionId: subscriptionId,
      customerId: customerId,
      vehicleId: vehicleId,
      token: token,
      serviceType: serviceType,
      totalAmount: totalAmount,
      subTotal: subTotal,
      gst: gst,
      gstAmount: gstAmount,
    );
    return _messageFromSave(data);
  }

  @override
  Future<String> createSubscriptionOrderId({
    required String customerId,
    required String token,
  }) async {
    final data = await _remote.createSubscriptionOrderId(
      customerId: customerId,
      token: token,
    );
    if ((data['code'] ?? '').toString() != '200') {
      throw Exception(
        (data['result'] ?? data['message'] ?? 'Order id failed').toString(),
      );
    }
    final orderId = (data['order_id'] ?? '').toString();
    if (orderId.isEmpty) {
      throw Exception('Order id missing');
    }
    return orderId;
  }

  @override
  Future<String> saveMonthlySubscriptionOrder({
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
    final data = await _remote.saveMonthlySubscriptionOrder(
      orderId: orderId,
      planId: planId,
      subscriptionId: subscriptionId,
      customerId: customerId,
      vehicleId: vehicleId,
      token: token,
      serviceType: serviceType,
      totalAmount: totalAmount,
      subTotal: subTotal,
      gst: gst,
      gstAmount: gstAmount,
    );
    return _messageFromSave(data);
  }

  @override
  Future<String> validateCheckout({
    required String customerId,
    required String vehicleId,
    required String serviceType,
    String? subsType,
  }) async {
    final data = await _remote.validateCheckout(
      customerId: customerId,
      vehicleId: vehicleId,
      serviceType: serviceType,
      subsType: subsType,
    );
    final code = (data['code'] ?? '').toString();
    if (code == '200') return '';
    return (data['message'] ?? data['result'] ?? 'Validation failed').toString();
  }

  @override
  Future<OneTimeWashCheckout?> fetchOneTimeWashCheckout({
    required String customerId,
    required String packAmount,
    required String vehicleId,
    required String serviceType,
  }) async {
    final data = await _remote.oneTimeWashCheckout(
      customerId: customerId,
      packAmount: packAmount,
      vehicleId: vehicleId,
      serviceType: serviceType,
    );
    final code = (data['code'] ?? '').toString();
    final message = (data['message'] ?? data['result'] ?? '').toString();
    if (code != '200') {
      throw Exception(
        message.isNotEmpty ? message : 'One-time checkout unavailable',
      );
    }
    final result = data['result'];
    if (result is! List || result.isEmpty) return null;
    final first = result.first;
    if (first is! Map) return null;
    return OneTimeWashCheckout.fromJson(
      first.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  Future<String> createCartRazorpayOrderId({required int cartTotal}) async {
    final data = await _remote.createRazorpayOrderId(amount: cartTotal.toString());
    if ((data['code'] ?? '').toString() != '200') {
      throw Exception(
        (data['result'] ?? 'Unable to create payment order').toString(),
      );
    }
    final orderId = (data['rzp_order_id'] ?? '').toString();
    if (orderId.isEmpty) {
      throw Exception('Unable to create payment order');
    }
    return orderId;
  }

  @override
  Future<void> createTempOrdersForCart({
    required List<CartItem> items,
    required String razorpayOrderId,
    required String customerId,
    required String token,
    required String cartTotal,
  }) async {
    for (final CartItem item in items) {
      final packageType = CartDisplayHelper.packageType(item);
      final action = item.action;

      Map<String, dynamic> data;
      if (action == CheckoutConstants.actionWashOneTime &&
          item.serviceType != CheckoutConstants.serviceAddon) {
        data = await _remote.tempWashOrder(
          razorpayOrderId: razorpayOrderId,
          customerId: customerId,
          token: token,
          packAmount: item.packAmount,
          vehicleId: item.carId,
          paidMonths: item.paidMonths,
          fineAmount: item.fineAmount,
          subTotal: item.subTotal,
          gst: item.gstPercent,
          gstAmount: item.gstAmount,
          totalAmount: item.totalAmount.isNotEmpty ? item.totalAmount : item.packAmount,
          serviceType: 'Wash',
          packType: packageType,
          successAction: CheckoutConstants.actionWashOneTime,
          orderId: item.sourceOrderId,
        );
      } else if (action == 'onetime_wax_payment' ||
          (action == CheckoutConstants.actionWashOneTime &&
              item.serviceType == CheckoutConstants.serviceAddon)) {
        data = await _remote.tempAddOnOrder(
          razorpayOrderId: razorpayOrderId,
          customerId: customerId,
          token: token,
          packAmount: item.packAmount,
          vehicleId: item.carId,
          paidMonths: item.paidMonths,
          fineAmount: item.fineAmount,
          subTotal: item.subTotal,
          gst: item.gstPercent,
          gstAmount: item.gstAmount,
          totalAmount: item.totalAmount.isNotEmpty ? item.totalAmount : item.packAmount,
          serviceType: 'AddOn',
          packType: packageType,
          scheduleDate: item.scheduleDate,
          scheduleTime: item.scheduleTime,
          successAction: CheckoutConstants.actionWashOneTime,
          orderId: item.sourceOrderId,
        );
      } else if (action == CheckoutConstants.actionOneTime ||
          action == 'onetime_disinfection_payment') {
        data = await _remote.tempExtraOrder(
          razorpayOrderId: razorpayOrderId,
          customerId: customerId,
          token: token,
          packType: packageType,
          packAmount: item.packAmount,
          vehicleId: item.carId,
          serviceType: 'AddOn',
          subTotal: item.subTotal,
          gst: item.gstPercent,
          gstAmount: item.gstAmount,
          totalAmount: item.totalAmount.isNotEmpty ? item.totalAmount : item.packAmount,
          scheduleDate: item.scheduleDate,
          scheduleTime: item.scheduleTime,
          successAction: action,
          orderId: item.sourceOrderId,
        );
      } else {
        throw Exception('Unsupported cart item type');
      }

      if ((data['code'] ?? '').toString() != '200') {
        throw Exception((data['result'] ?? 'Temp order failed').toString());
      }
    }
  }

  @override
  Future<String> placeOneTimeExtraOrder({
    required String action,
    required String paymentId,
    required String customerId,
    required String token,
    required String packAmount,
    required String vehicleId,
    required String subTotal,
    required String gst,
    required String totalAmount,
    required String scheduleDate,
    required String scheduleTime,
    String razorpayOrderId = '',
  }) async {
    final data = await _remote.saveOrderOneTime(
      action: action,
      paymentId: paymentId,
      customerId: customerId,
      token: token,
      packType: 'ExtraInterior',
      packAmount: packAmount,
      vehicleId: vehicleId,
      serviceType: 'AddOn',
      subTotal: subTotal,
      gst: gst,
      gstAmount: '0',
      totalAmount: totalAmount,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      razorpayOrderId: razorpayOrderId,
    );
    return _messageFromSave(data);
  }

  @override
  Future<String> placeOneTimeWashOrder({
    required String paymentId,
    required String customerId,
    required String token,
    required String packAmount,
    required String vehicleId,
    required String paidMonths,
    required String fineAmount,
    required String subTotal,
    required String gst,
    required String totalAmount,
    required String serviceType,
    required String packType,
    String razorpayOrderId = '',
    String gstAmount = '',
  }) async {
    final data = await _remote.saveWashOrderOneTime(
      paymentId: paymentId,
      customerId: customerId,
      token: token,
      packAmount: packAmount,
      vehicleId: vehicleId,
      paidMonths: paidMonths,
      fineAmount: fineAmount,
      subTotal: subTotal,
      gst: gst,
      gstAmount: gstAmount,
      totalAmount: totalAmount,
      serviceType: serviceType,
      packType: packType,
      razorpayOrderId: razorpayOrderId,
    );
    return _messageFromSave(data);
  }

  @override
  Future<String> placeOneTimeAddOnOrder({
    required String paymentId,
    required String customerId,
    required String token,
    required String packAmount,
    required String vehicleId,
    required String paidMonths,
    required String fineAmount,
    required String subTotal,
    required String gst,
    required String totalAmount,
    required String scheduleDate,
    required String scheduleTime,
    required String packType,
    String razorpayOrderId = '',
    String gstAmount = '',
  }) async {
    final data = await _remote.saveAddOnOrderOneTime(
      paymentId: paymentId,
      customerId: customerId,
      token: token,
      packAmount: packAmount,
      vehicleId: vehicleId,
      paidMonths: paidMonths,
      fineAmount: fineAmount,
      subTotal: subTotal,
      gst: gst,
      gstAmount: gstAmount,
      totalAmount: totalAmount,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      packType: packType,
      razorpayOrderId: razorpayOrderId,
    );
    return _messageFromSave(data);
  }

  String _messageFromSave(Map<String, dynamic> data) {
    final code = (data['code'] ?? '').toString();
    if (code == '200' ||
        (data['message'] ?? '').toString().toLowerCase() == 'success') {
      return (data['result'] ?? 'Order placed successfully').toString();
    }
    throw Exception((data['result'] ?? data['message'] ?? 'Order failed')
        .toString());
  }
}
