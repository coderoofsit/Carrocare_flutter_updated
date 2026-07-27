import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';

/// Display helpers matching Android [CartListAdapter].
class CartDisplayHelper {
  static String serviceLabel(CartItem item) {
    switch (item.action) {
      case 'onetime_wash_payment':
        if (item.serviceType == CheckoutConstants.serviceAddon) {
          return 'Wax polish';
        }
        return 'Wash';
      case 'onetime_wax_payment':
        return 'Wax polish';
      case 'onetime_payment':
        return 'Extra Interior';
      case 'onetime_disinfection_payment':
        return 'Disinfection';
      default:
        break;
    }
    if (item.serviceType == CheckoutConstants.serviceAddon) {
      return 'Wax polish';
    }
    if (item.serviceType == CheckoutConstants.serviceExtraInterior) {
      return 'Extra Interior';
    }
    if (item.serviceType == CheckoutConstants.serviceDisinfection) {
      return 'Disinfection';
    }
    if (item.serviceType.contains('Wash')) return 'Wash';
    return item.serviceType;
  }

  static bool showMonthLabel(CartItem item) {
    if (item.action == CheckoutConstants.actionMonthly) return true;
    return item.action == CheckoutConstants.actionWashOneTime &&
        serviceLabel(item) == 'Wash';
  }

  static String periodLabel(CartItem item) {
    if (item.action == CheckoutConstants.actionMonthly) {
      return 'Monthly (auto-renew)';
    }
    return monthLabel(item.paidMonths);
  }

  static bool showSchedule(CartItem item) {
    return item.action == 'onetime_wax_payment' ||
        item.action == CheckoutConstants.actionOneTime ||
        item.action == 'onetime_disinfection_payment';
  }

  static String monthLabel(String paidMonths) {
    final months = paidMonths.trim();
    if (months == '1' || months == '0' || months.isEmpty) {
      return '1 Month';
    }
    return '$months Months';
  }

  static String packageType(CartItem item) {
    final fromCategory = CheckoutConstants.normalizePackageType(item.carCategory);
    if (fromCategory.isNotEmpty &&
        fromCategory != item.carCategory &&
        !fromCategory.toLowerCase().contains('wash')) {
      return fromCategory;
    }
    final fromName = CheckoutConstants.normalizePackageType(item.carName);
    if (fromName.isNotEmpty && !fromName.toLowerCase().contains('wash')) {
      return fromName;
    }
    final parts = item.dbType.split('=');
    final tag = parts.length > 1 ? parts[1] : item.serviceType;
    if (tag == CheckoutConstants.serviceBikeWash) return 'Bike';
    if (tag == CheckoutConstants.serviceExtraInterior) return 'ExtraInterior';
    if (tag == CheckoutConstants.serviceDisinfection) return 'Disinfection';
    return fromCategory.isNotEmpty ? fromCategory : fromName;
  }

  static int parseAmount(String value) => int.tryParse(value) ?? 0;

  static String formatRupee(int amount) => '₹ $amount';

  static String formatRupeeFromString(String amount) =>
      formatRupee(parseAmount(amount));
}
