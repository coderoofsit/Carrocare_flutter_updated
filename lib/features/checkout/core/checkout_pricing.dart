import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';

class CheckoutPricing {
  static int parseAmount(String value) => int.tryParse(value) ?? 0;

  static int taxAmount(int base, int gstPercent) =>
      gstPercent == 0 ? 0 : ((gstPercent * base) / 100).round();

  static int finalAmount(int base, int gstPercent) => base + taxAmount(base, gstPercent);

  /// Customer price already includes GST — do not add tax on top.
  static int inclusiveTotal(int inclusive, int gstPercent) => inclusive;

  /// Split a GST-inclusive price into subtotal + tax (e.g. 100 @ 18% → 85 + 15).
  static ({int total, int subTotal, int gstAmount}) breakdownFromInclusive(
    int inclusive,
    int gstPercent,
  ) {
    if (gstPercent == 0) {
      return (total: inclusive, subTotal: inclusive, gstAmount: 0);
    }
    final subTotal = exclusiveAmount(inclusive, gstPercent);
    return (
      total: inclusive,
      subTotal: subTotal,
      gstAmount: inclusive - subTotal,
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
