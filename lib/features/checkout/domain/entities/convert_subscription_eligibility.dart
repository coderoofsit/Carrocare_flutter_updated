class ConvertSubscriptionEligibility {
  const ConvertSubscriptionEligibility({
    required this.chargeAt,
    required this.planId,
    required this.packAmount,
    required this.packType,
    required this.vehicleType,
    required this.serviceType,
    this.immediate = false,
  });

  final String chargeAt;
  final String planId;
  final String packAmount;
  final String packType;
  final String vehicleType;
  final String serviceType;
  final bool immediate;

  factory ConvertSubscriptionEligibility.fromJson(Map<String, dynamic> json) {
    final immediateRaw = json['immediate'];
    final immediate = immediateRaw == true ||
        immediateRaw == 1 ||
        immediateRaw?.toString().toLowerCase() == 'true';
    return ConvertSubscriptionEligibility(
      chargeAt: (json['charge_at'] ?? '').toString(),
      planId: (json['plan_id'] ?? '').toString(),
      packAmount: (json['pack_amount'] ?? '').toString(),
      packType: (json['pack_type'] ?? '').toString(),
      vehicleType: (json['vehicle_type'] ?? '').toString(),
      serviceType: (json['service_type'] ?? 'Wash').toString(),
      immediate: immediate,
    );
  }
}
