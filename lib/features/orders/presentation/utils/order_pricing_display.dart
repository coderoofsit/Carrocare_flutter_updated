import 'package:carrocare_flutter/features/checkout/core/checkout_gst_config.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_plan_fee_resolver.dart';
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
    this.platformFee = 0,
    this.serviceFee = 0,
  });

  final int taxableAmount;
  final int gstPercent;
  final int gstAmount;
  final int totalAmount;
  final bool showPackageValue;
  final int packageValue;
  final int platformFee;
  final int serviceFee;

  String get taxableLabel => CheckoutPricing.rupee(taxableAmount);
  String get gstPercentLabel => '$gstPercent%';
  String get gstAmountLabel => CheckoutPricing.rupee(gstAmount);
  String get totalLabel => CheckoutPricing.rupee(totalAmount);
  String get packageValueLabel => CheckoutPricing.rupee(packageValue);
  String get platformFeeLabel => CheckoutPricing.rupee(platformFee);
  String get serviceFeeLabel => CheckoutPricing.rupee(serviceFee);

  factory OrderPricingDisplay.fromOrder(OrderItem order) {
    final total = CheckoutPricing.parseMoney(order.totalAmount);
    final package = CheckoutPricing.parseMoney(order.packageValue);
    final parsedGst = CheckoutPricing.parseMoney(
      order.gst.replaceAll('%', '').trim(),
    );
    final gstPercent =
        parsedGst > 0 ? parsedGst : CheckoutGstConfig.defaultGstPercent;

    final apiPlatform = CheckoutPricing.parseMoney(order.platformFeeAmt);
    final apiService = CheckoutPricing.parseMoney(order.serviceFeeAmt);
    final unitPlan = package > 0 ? package : total;

    final breakdown = CheckoutPlanFeeResolver.breakdown(
      inclusiveTotal: total,
      unitPlanAmount: unitPlan,
      gstPercent: gstPercent,
      storedPlatformFeeAmt: apiPlatform > 0 ? apiPlatform : null,
    );

    var taxable = CheckoutPricing.parseMoney(order.subTotalAmount);
    var gst = CheckoutPricing.parseMoney(order.gstAmount);
    var platform = apiPlatform > 0 ? apiPlatform : breakdown.platformFee;
    var service = apiService > 0 ? apiService : breakdown.serviceFee;

    if (apiPlatform <= 0 || apiService <= 0) {
      taxable = breakdown.subTotal;
      gst = breakdown.gstAmount;
      platform = breakdown.platformFee;
      service = breakdown.serviceFee;
    } else if (total > 0 && gstPercent > 0) {
      if (taxable + gst != total || gst <= 0) {
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
      platformFee: platform,
      serviceFee: service,
    );
  }
}
