import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';

abstract final class CartSubscriptionToggleHelper {
  static bool itemSupportsConversion(CartItem item) {
    return item.action == CheckoutConstants.actionWashOneTime &&
        item.sourceOrderId.trim().isNotEmpty &&
        _isWashService(item.serviceType);
  }

  static String defaultDisabledReason() {
    return 'Subscription mode is available only when all cart items are eligible one-time Wash renewals.';
  }

  static bool _isWashService(String serviceType) {
    final normalized = serviceType.trim().toLowerCase();
    return normalized == CheckoutConstants.serviceWash.toLowerCase() ||
        normalized == CheckoutConstants.serviceBikeWash.toLowerCase() ||
        normalized == 'wash';
  }
}
