import 'package:carrocare_flutter/features/checkout/core/checkout_gst_config.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';

/// Normalized GST-inclusive pricing for order detail / invoice-style UI.
class OrderPricingDisplay {
  const OrderPricingDisplay({
    required this.taxableAmount,
    required this.gstPercent,
    required this.gstAmount,
    required this.totalAmount,
    required this.showPackageValue,
    required this.packageValue,
  });

  final int taxableAmount;
  final int gstPercent;
  final int gstAmount;
  final int totalAmount;
  final bool showPackageValue;
  final int packageValue;

  String get taxableLabel => CheckoutPricing.rupee(taxableAmount);
  String get gstPercentLabel => '$gstPercent%';
  String get gstAmountLabel => CheckoutPricing.rupee(gstAmount);
  String get totalLabel => CheckoutPricing.rupee(totalAmount);
  String get packageValueLabel => CheckoutPricing.rupee(packageValue);

  factory OrderPricingDisplay.fromOrder(OrderItem order) {
    final total = CheckoutPricing.parseAmount(order.totalAmount);
    final package = CheckoutPricing.parseAmount(order.packageValue);
    final parsedGst = CheckoutPricing.parseAmount(
      order.gst.replaceAll('%', '').trim(),
    );
    final gstPercent =
        parsedGst > 0 ? parsedGst : CheckoutGstConfig.defaultGstPercent;

    var taxable = CheckoutPricing.parseAmount(order.subTotalAmount);
    var gst = CheckoutPricing.parseAmount(order.gstAmount);

    if (total > 0 && gstPercent > 0) {
      if (taxable + gst != total || gst <= 0) {
        final breakdown = CheckoutPricing.breakdownFromInclusive(total, gstPercent);
        taxable = breakdown.subTotal;
        gst = breakdown.gstAmount;
      }
    } else if (total > 0 && taxable <= 0) {
      taxable = total;
      gst = 0;
    }

    final showPackageValue =
        package > 0 && package != taxable && package != total;

    return OrderPricingDisplay(
      taxableAmount: taxable,
      gstPercent: gstPercent,
      gstAmount: gst,
      totalAmount: total > 0 ? total : taxable + gst,
      showPackageValue: showPackageValue,
      packageValue: package,
    );
  }
}
