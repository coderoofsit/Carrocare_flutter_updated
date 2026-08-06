import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/convert_subscription_eligibility.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/razorpay_checkout_service.dart';

/// One-time Wash order → deferred monthly autopay:
/// eligibility → create_subscription(source_order_id) → Razorpay SDK →
/// save_order (convert_to_subscription).
class ConvertToSubscriptionCheckout {
  ConvertToSubscriptionCheckout._();

  static Future<void> run({
    required RazorpayCheckoutService razorpay,
    required String token,
    required String customerId,
    required String sourceOrderId,
    required String vehicleId,
    required int gstPercent,
    required RazorpayPriceSummary priceSummary,
    required void Function(String message) onError,
    required Future<void> Function(String chargeAt) onSuccess,
  }) async {
    final repo = sl<CheckoutRepository>();

    final ConvertSubscriptionEligibility eligibility =
        await repo.fetchConvertSubscriptionEligibility(
      token: token,
      customerId: customerId,
      orderId: sourceOrderId,
    );

    final packAmount = eligibility.packAmount;
    final breakdown = CheckoutPricing.breakdownFromInclusive(
      CheckoutPricing.parseAmount(packAmount),
      gstPercent,
    );

    final session = await repo.createSubscription(
      token: token,
      customerId: customerId,
      vehicleId: vehicleId,
      planId: eligibility.planId,
      sourceOrderId: sourceOrderId,
    );

    try {
      await razorpay.openSubscriptionAndWait(
        keyId: session.keyId,
        subscriptionId: session.subscriptionId,
        description: eligibility.serviceType,
        email: session.customerEmail,
        contact: session.customerMobile,
        priceSummary: priceSummary,
      );

      await repo.saveConvertToSubscription(
        sourceOrderId: sourceOrderId,
        planId: eligibility.planId,
        subscriptionId: session.subscriptionId,
        customerId: customerId,
        vehicleId: vehicleId,
        token: token,
        serviceType: eligibility.serviceType,
        totalAmount: breakdown.total.toString(),
        subTotal: CheckoutPricing.moneyString(breakdown.subTotal),
        gst: gstPercent.toString(),
        gstAmount: CheckoutPricing.moneyString(breakdown.gstAmount),
      );

      await onSuccess(eligibility.chargeAt);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      onError(message.isNotEmpty ? message : 'Payment failed');
      rethrow;
    }
  }
}
