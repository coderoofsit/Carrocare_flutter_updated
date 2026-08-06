class CheckoutConstants {
  static const String actionMonthly = 'monthly_payment';
  static const String actionOneTime = 'onetime_payment';
  static const String actionWashOneTime = 'onetime_wash_payment';
  static const String actionExtraOneTime = 'onetime_wash_payment';

  static const String serviceWash = 'Daily Car Wash';
  static const String serviceBikeWash = 'Daily Bike Wash';
  static const String serviceAddon = 'Wax Polish';
  static const String serviceExtraInterior = 'Extra Interior';
  static const String serviceDisinfection = 'Car Disinfection';

  static const int offerPriceMarkup = 50;
  static const String chooseDateTime =
      'Please choose preferred date and time';

  static const List<String> preferredTimes = <String>[
    'Anytime',
    '9:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '6:00 PM - 7:00 PM',
    '7:00 PM - 8:00 PM',
  ];

  /// Razorpay subscription billing cycles (matches PHP `$subscription_months_count`).
  static const int subscriptionMonthsCount = 60;

  static const List<String> subscriptionMonths = <String>[
    '1 Month',
    '2 Months',
    '3 Months',
    '4 Months',
    '5 Months',
    '6 Months',
    '7 Months',
    '8 Months',
    '9 Months',
    '10 Months',
    '11 Months',
    '12 Months',
    '13 Months',
    '14 Months',
    '15 Months',
    '16 Months',
    '17 Months',
    '18 Months',
    '19 Months',
    '20 Months',
    '21 Months',
    '22 Months',
    '23 Months',
    '24 Months',
  ];

  static String resolveAction({
    required String serviceType,
    required bool isMonthlyPay,
    required bool isExtraInteriorName,
  }) {
    if (isExtraInteriorName || serviceType == serviceDisinfection) {
      return actionOneTime;
    }
    if (isMonthlyPay) return actionMonthly;
    if (serviceType == serviceAddon) return actionExtraOneTime;
    return actionWashOneTime;
  }

  static String oneTimeApiService(String serviceType) {
    if (serviceType == serviceAddon || serviceType == serviceExtraInterior) {
      return 'AddOn';
    }
    return 'Wash';
  }

  static String normalizePackageType(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('bike')) return 'Bike';
    if (lower.contains('hatch')) return 'Hatchback';
    if (lower.contains('sedan')) return 'Sedan';
    if (lower.contains('suv')) return 'SUV';
    if (lower.contains('extra')) return 'ExtraInterior';
    return category;
  }
}
