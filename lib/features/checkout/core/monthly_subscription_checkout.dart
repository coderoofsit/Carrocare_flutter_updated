import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/razorpay_checkout_service.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';

/// Native monthly subscription flow:
/// get_plan → create_subscription → Razorpay SDK →
/// save_order (create_subscription_orderid + monthly_payment) → order_list.
class MonthlySubscriptionCheckout {
  MonthlySubscriptionCheckout._();

  static Future<void> run({
    required RazorpayCheckoutService razorpay,
    required String token,
    required String customerId,
    required String vehicleId,
    required String packType,
    required String vehicleType,
    required String serviceType,
    required String packAmount,
    required int gstPercent,
    required RazorpayPriceSummary priceSummary,
    required void Function(String message) onError,
    required Future<void> Function() onSuccess,
  }) async {
    final repo = sl<CheckoutRepository>();

    // Always resolve via get_plan.php so Razorpay plan matches [packAmount]
    // (plans_list may return older plan ids/amounts like 600 vs 635).
    final planId = await repo.resolveMonthlyPlanId(
      token: token,
      packType: packType,
      packAmount: packAmount,
      vehicleType: vehicleType,
      serviceType: serviceType,
    );

    final session = await repo.createSubscription(
      token: token,
      customerId: customerId,
      vehicleId: vehicleId,
      planId: planId,
    );

    final breakdown = CheckoutPricing.breakdownFromInclusive(
      CheckoutPricing.parseAmount(packAmount),
      gstPercent,
    );

    await razorpay.openSubscription(
      keyId: session.keyId,
      subscriptionId: session.subscriptionId,
      description: serviceType,
      email: session.customerEmail,
      contact: session.customerMobile,
      priceSummary: priceSummary,
      onSuccess: (_) async {
        try {
          final orderId = await repo.createSubscriptionOrderId(
            customerId: customerId,
            token: token,
          );
          await repo.saveMonthlySubscriptionOrder(
            orderId: orderId,
            planId: planId,
            subscriptionId: session.subscriptionId,
            customerId: customerId,
            vehicleId: vehicleId,
            token: token,
            serviceType: serviceType,
            totalAmount: breakdown.total.toString(),
            subTotal: breakdown.subTotal.toString(),
            gst: gstPercent.toString(),
            gstAmount: breakdown.gstAmount.toString(),
          );
          await sl<OrdersRepository>().getOrders(
            token: token,
            customerId: customerId,
          );
          await onSuccess();
        } catch (e) {
          onError(e.toString());
        }
      },
      onError: onError,
    );
  }
}
