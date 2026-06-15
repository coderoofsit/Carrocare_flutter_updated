import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';

/// Maps UI service labels to API [serv_type] for plan/subscription APIs.
String apiServiceTypeForSubscription(String serviceType) {
  if (serviceType == CheckoutConstants.serviceWash ||
      serviceType == CheckoutConstants.serviceBikeWash) {
    return 'Wash';
  }
  if (serviceType == CheckoutConstants.serviceAddon ||
      serviceType == CheckoutConstants.serviceExtraInterior) {
    return 'Add On';
  }
  if (serviceType == CheckoutConstants.serviceDisinfection) {
    return 'Disinfection';
  }
  if (serviceType == 'Wash' || serviceType == 'Add On') {
    return serviceType;
  }
  return serviceType;
}

/// [validate_checkout.php] service_type field from booking header.
String apiServiceTypeForValidation(String serviceType) {
  if (serviceType == CheckoutConstants.serviceWash ||
      serviceType == CheckoutConstants.serviceBikeWash) {
    return 'Wash';
  }
  if (serviceType == CheckoutConstants.serviceAddon ||
      serviceType == CheckoutConstants.serviceExtraInterior) {
    return 'Add On';
  }
  if (serviceType == CheckoutConstants.serviceDisinfection) {
    return 'Disinfection';
  }
  return serviceType;
}
