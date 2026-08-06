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

/// Razorpay plan `service_type` for [plans_list] / fee split (AddOn, Wash, …).
String apiPlanServiceType(String serviceType) {
  if (serviceType == CheckoutConstants.serviceWash ||
      serviceType == CheckoutConstants.serviceBikeWash) {
    return 'Wash';
  }
  if (serviceType == CheckoutConstants.serviceAddon ||
      serviceType == CheckoutConstants.serviceExtraInterior) {
    return 'AddOn';
  }
  if (serviceType == CheckoutConstants.serviceDisinfection) {
    return 'Disinfection';
  }
  final normalized = serviceType.trim().replaceAll(' ', '');
  if (normalized.toLowerCase() == 'addon') return 'AddOn';
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
