import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';

/// Helpers for when auto-renewal applies in checkout.
class AutopayCheckoutHelper {
  AutopayCheckoutHelper._();

  /// Monthly subscription plans (interior / monthly payment action).
  static bool cartItemSupportsAutopay(CartItem item) {
    return item.action == CheckoutConstants.actionMonthly ||
        (item.action == CheckoutConstants.actionWashOneTime &&
            _paidMonths(item) >= 3);
  }

  static bool cartHasAutopayEligibleItems(List<CartItem> items) {
    return items.any(cartItemSupportsAutopay);
  }

  static int _paidMonths(CartItem item) =>
      int.tryParse(item.paidMonths.trim()) ?? 0;

  static String autopayQueryValue(bool enabled) => enabled ? '1' : '0';
}
