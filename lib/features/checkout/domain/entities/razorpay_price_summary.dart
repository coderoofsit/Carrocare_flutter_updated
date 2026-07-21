import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';

/// GST-aware copy for Razorpay checkout `description` and `notes` fields.
class RazorpayPriceSummary {
  const RazorpayPriceSummary({
    required this.serviceLabel,
    required this.total,
    required this.subTotal,
    required this.gstAmount,
    required this.gstPercent,
    this.platformFee = 0,
    this.serviceFee = 0,
  });

  final String serviceLabel;
  final int total;
  final int subTotal;
  final int gstAmount;
  final int gstPercent;
  final int platformFee;
  final int serviceFee;

  factory RazorpayPriceSummary.fromInclusive({
    required String serviceLabel,
    required int inclusiveTotal,
    required int gstPercent,
    int? planAmount,
    int? platformFeeAmt,
  }) {
    final plan = planAmount ?? inclusiveTotal;
    final platform = platformFeeAmt ??
        CheckoutPricing.derivePlatformFeeAmt(
          plan,
          CheckoutPricing.defaultPlatformFeePercent,
        );
    final breakdown = CheckoutPricing.breakdownWithPlatformFee(
      inclusiveTotal: inclusiveTotal,
      planAmount: plan,
      platformFeeAmt: platform,
      gstPercent: gstPercent,
    );
    return RazorpayPriceSummary(
      serviceLabel: serviceLabel,
      total: breakdown.total,
      subTotal: breakdown.subTotal,
      gstAmount: breakdown.gstAmount,
      gstPercent: gstPercent,
      platformFee: breakdown.platformFee,
      serviceFee: breakdown.serviceFee,
    );
  }

  /// Shown on the Razorpay checkout sheet (single-line summary).
  String get description {
    if (gstPercent <= 0 || gstAmount <= 0) {
      return '$serviceLabel — Total ${CheckoutPricing.rupee(total)}';
    }
    return '$serviceLabel — Platform ${CheckoutPricing.rupee(platformFee)} + '
        'Service ${CheckoutPricing.rupee(serviceFee)} + '
        'GST ($gstPercent%) ${CheckoutPricing.rupee(gstAmount)} = '
        '${CheckoutPricing.rupee(total)}';
  }

  /// Stored on the Razorpay payment for receipts / dashboard.
  Map<String, String> get notes => <String, String>{
        'service': serviceLabel,
        'sub_total': subTotal.toString(),
        'platform_fee': platformFee.toString(),
        'service_fee': serviceFee.toString(),
        'gst_percent': gstPercent.toString(),
        'gst_amount': gstAmount.toString(),
        'total': total.toString(),
      };
}
