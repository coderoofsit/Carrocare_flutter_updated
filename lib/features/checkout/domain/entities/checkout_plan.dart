import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';

class CheckoutPlan {
  const CheckoutPlan({
    required this.planId,
    required this.packageType,
    required this.vehicleType,
    required this.subscriptionType,
    required this.serviceType,
    required this.planAmount,
    this.platformFeeAmt = '',
    this.platformFeePercent = '',
    this.serviceFeeAmt = '',
  });

  final String planId;
  final String packageType;
  final String vehicleType;
  final String subscriptionType;
  final String serviceType;
  final String planAmount;
  final String platformFeeAmt;
  final String platformFeePercent;
  final String serviceFeeAmt;

  int get resolvedPlatformFeeAmt {
    final direct = CheckoutPricing.parseMoney(platformFeeAmt);
    if (direct > 0) return direct;
    final plan = CheckoutPricing.parseMoney(planAmount);
    final pct = double.tryParse(platformFeePercent.trim()) ?? 0;
    if (plan > 0 && pct > 0) {
      return ((plan * pct) / 100).round();
    }
    return 0;
  }

  bool get isMonthly =>
      subscriptionType.toLowerCase() == 'monthly';

  bool get isOneTime =>
      subscriptionType.toLowerCase() == 'onetime' ||
      subscriptionType.toLowerCase() == 'one time';

  factory CheckoutPlan.fromJson(Map<String, dynamic> json) {
    return CheckoutPlan(
      planId: (json['plan_id'] ?? '').toString(),
      packageType: (json['package_type'] ?? '').toString(),
      vehicleType: (json['vehicle_type'] ?? '').toString(),
      subscriptionType: (json['subscription_type'] ?? '').toString(),
      serviceType: (json['service_type'] ?? '').toString(),
      planAmount: (json['plan_amount'] ?? '').toString(),
      platformFeeAmt: (json['platform_fee_amt'] ?? '').toString(),
      platformFeePercent: (json['platform_fee_percent'] ?? '').toString(),
      serviceFeeAmt: (json['service_fee_amt'] ?? '').toString(),
    );
  }
}

class SubscriptionCheckoutSession {
  const SubscriptionCheckoutSession({
    required this.keyId,
    required this.subscriptionId,
    required this.planId,
    required this.customerName,
    required this.customerEmail,
    required this.customerMobile,
  });

  final String keyId;
  final String subscriptionId;
  final String planId;
  final String customerName;
  final String customerEmail;
  final String customerMobile;
}
