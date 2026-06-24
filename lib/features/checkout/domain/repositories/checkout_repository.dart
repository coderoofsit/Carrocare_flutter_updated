import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/checkout_plan.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/convert_subscription_eligibility.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/one_time_wash_checkout.dart';

abstract class CheckoutRepository {
  Future<({String keyId, String secretKey})> getRazorpayKeys();

  Future<String> validateCheckout({
    required String customerId,
    required String vehicleId,
    required String serviceType,
    String? subsType,
  });

  Future<List<CheckoutPlan>> fetchPlansList({
    String? vehicleType,
    String? serviceType,
    String? packType,
    String? packAmount,
  });

  Future<String> resolveMonthlyPlanId({
    required String token,
    required String packType,
    required String packAmount,
    required String vehicleType,
    required String serviceType,
  });

  Future<SubscriptionCheckoutSession> createSubscription({
    required String token,
    required String customerId,
    required String vehicleId,
    required String planId,
    String? sourceOrderId,
  });

  Future<ConvertSubscriptionEligibility> fetchConvertSubscriptionEligibility({
    required String token,
    required String customerId,
    required String orderId,
  });

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
  });

  Future<String> createSubscriptionOrderId({
    required String customerId,
    required String token,
  });

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
  });

  Future<OneTimeWashCheckout?> fetchOneTimeWashCheckout({
    required String customerId,
    required String packAmount,
    required String vehicleId,
    required String serviceType,
  });

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
  });

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
  });

  Future<String> createCartRazorpayOrderId({required int cartTotal});

  Future<void> createTempOrdersForCart({
    required List<CartItem> items,
    required String razorpayOrderId,
    required String customerId,
    required String token,
    required String cartTotal,
  });

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
  });
}
