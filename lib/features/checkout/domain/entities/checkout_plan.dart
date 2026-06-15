class CheckoutPlan {
  const CheckoutPlan({
    required this.planId,
    required this.packageType,
    required this.vehicleType,
    required this.subscriptionType,
    required this.serviceType,
    required this.planAmount,
  });

  final String planId;
  final String packageType;
  final String vehicleType;
  final String subscriptionType;
  final String serviceType;
  final String planAmount;

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
