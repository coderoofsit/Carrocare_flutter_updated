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

  final double taxableAmount;
  final int gstPercent;
  final double gstAmount;
  final int totalAmount;
  final bool showPackageValue;
  final int packageValue;
  final double platformFee;
  final double serviceFee;

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

    final apiPlatform = CheckoutPricing.parseMoneyDecimal(order.platformFeeAmt);
    final apiService = CheckoutPricing.parseMoneyDecimal(order.serviceFeeAmt);
    final unitPlan = package > 0 ? package : total;

    final breakdown = CheckoutPlanFeeResolver.breakdown(
      inclusiveTotal: total,
      unitPlanAmount: unitPlan,
      gstPercent: gstPercent,
      storedPlatformFeeAmt: apiPlatform > 0 ? apiPlatform.round() : null,
    );

    var taxable = CheckoutPricing.parseMoneyDecimal(order.subTotalAmount);
    var gst = CheckoutPricing.parseMoneyDecimal(order.gstAmount);
    // Prefer exclusive platform fee from breakdown for bill display.
    var platform = breakdown.platformFee;
    var service = breakdown.serviceFee;

    if (apiPlatform > 0 && apiService > 0) {
      // Older orders may store GST-inclusive platform_fee_amt. Detect and
      // keep exclusive display via breakdown; only trust API service if it
      // matches the non-taxable remainder.
      if (CheckoutPricing.round2(apiPlatform + apiService) == total) {
        platform = breakdown.platformFee;
        service = apiService > 0 ? apiService : breakdown.serviceFee;
      } else if (CheckoutPricing.round2(apiPlatform + apiService + gst) ==
          total) {
        platform = apiPlatform;
        service = apiService;
      }
    }

    if (apiPlatform <= 0 || apiService <= 0) {
      taxable = breakdown.subTotal;
      gst = breakdown.gstAmount;
      platform = breakdown.platformFee;
      service = breakdown.serviceFee;
    } else if (total > 0 && gstPercent > 0) {
      if (CheckoutPricing.round2(taxable + gst) != total || gst <= 0) {
        taxable = breakdown.subTotal;
        gst = breakdown.gstAmount;
      }
    } else if (total > 0 && taxable <= 0) {
      taxable = total.toDouble();
      gst = 0;
    }

    final showPackageValue =
        package > 0 && package != taxable && package != total;

    return OrderPricingDisplay(
      taxableAmount: taxable,
      gstPercent: gstPercent,
      gstAmount: gst,
      totalAmount: total > 0 ? total : CheckoutPricing.round2(taxable + gst).round(),
      showPackageValue: showPackageValue,
      packageValue: package,
      platformFee: platform,
      serviceFee: service,
    );
  }
}
