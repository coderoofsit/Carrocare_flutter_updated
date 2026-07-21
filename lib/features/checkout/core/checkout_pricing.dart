import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';

class CheckoutPricing {
  static const int defaultPlatformFeePercent = 64;

  static int parseAmount(String value) => parseMoney(value);

  /// Parses API money fields that may be integers or decimals (e.g. "299.00").
  static int parseMoney(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    final asDouble = double.tryParse(trimmed);
    if (asDouble != null) return asDouble.round();
    return int.tryParse(trimmed) ?? 0;
  }

  static int taxAmount(int base, int gstPercent) =>
      gstPercent == 0 ? 0 : ((gstPercent * base) / 100).round();

  static int finalAmount(int base, int gstPercent) => base + taxAmount(base, gstPercent);

  /// Customer price already includes GST — do not add tax on top.
  static int inclusiveTotal(int inclusive, int gstPercent) => inclusive;

  /// Platform fee INR from plan amount and configured percent.
  static int derivePlatformFeeAmt(int planAmount, int platformFeePercent) =>
      ((planAmount * platformFeePercent) / 100).round();

  /// GST applies only to platform fee. Service provider share is non-taxable.
  static ({
    int total,
    int subTotal,
    int gstAmount,
    int platformFee,
    int serviceFee,
  }) breakdownWithPlatformFee({
    required int inclusiveTotal,
    required int planAmount,
    required int platformFeeAmt,
    required int gstPercent,
  }) {
    if (inclusiveTotal <= 0) {
      return (
        total: 0,
        subTotal: 0,
        gstAmount: 0,
        platformFee: 0,
        serviceFee: 0,
      );
    }

    final plan = planAmount > 0 ? planAmount : inclusiveTotal;
    final ratio = plan > 0 ? (platformFeeAmt / plan).clamp(0.0, 1.0) : 0.0;
    final platformGross = (inclusiveTotal * ratio).round();
    final serviceGross = inclusiveTotal - platformGross;

    var platformExcl = platformGross;
    var gstAmount = 0;
    if (gstPercent > 0 && platformGross > 0) {
      platformExcl = ((platformGross * 100) / (100 + gstPercent)).round();
      gstAmount = platformGross - platformExcl;
    }

    final subTotal = platformExcl + serviceGross;
    return (
      total: inclusiveTotal,
      subTotal: subTotal,
      gstAmount: gstAmount,
      platformFee: platformGross,
      serviceFee: serviceGross,
    );
  }

  /// Split a GST-inclusive price using platform-fee-only GST (default 64% platform).
  static ({int total, int subTotal, int gstAmount}) breakdownFromInclusive(
    int inclusive,
    int gstPercent,
  ) {
    final full = breakdownWithPlatformFee(
      inclusiveTotal: inclusive,
      planAmount: inclusive,
      platformFeeAmt: derivePlatformFeeAmt(inclusive, defaultPlatformFeePercent),
      gstPercent: gstPercent,
    );
    return (
      total: full.total,
      subTotal: full.subTotal,
      gstAmount: full.gstAmount,
    );
  }

  /// Taxable amount from a GST-inclusive total (e.g. 1062 @ 18% → 900).
  static int exclusiveAmount(int inclusive, int gstPercent) {
    if (gstPercent == 0) return inclusive;
    return ((inclusive * 100) / (100 + gstPercent)).round();
  }

  /// GST-exclusive price string from a GST-inclusive API [apiPrice].
  static String exclusiveApiPrice(String apiPrice, int gstPercent) =>
      exclusiveAmount(parseAmount(apiPrice), gstPercent).toString();

  static int mrpWithOffer(int finalAmt, {int months = 1}) =>
      finalAmt + (CheckoutConstants.offerPriceMarkup * months);

  static String rupee(int amount) => '₹ $amount';
}
