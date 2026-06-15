import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_block_reason.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_service_type_mapper.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';

/// Validates whether checkout / subscribe is allowed for a vehicle.
class CheckoutVehicleGate {
  CheckoutVehicleGate._();

  static bool _isWashService(String header) =>
      header == CheckoutConstants.serviceWash ||
      header == CheckoutConstants.serviceBikeWash;

  static Future<CheckoutBlockReason> resolve({
    required String customerId,
    required String vehicleId,
    required String serviceHeader,
  }) async {
    if (customerId.isEmpty) return const CheckoutBlockReason();

    final serviceType = apiServiceTypeForValidation(serviceHeader);
    final repo = sl<CheckoutRepository>();

    try {
      if (_isWashService(serviceHeader)) {
        final monthlyValidation = await repo.validateCheckout(
          customerId: customerId,
          vehicleId: vehicleId,
          serviceType: serviceType,
          subsType: 'Monthly',
        );
        final oneTimeValidation = await repo.validateCheckout(
          customerId: customerId,
          vehicleId: vehicleId,
          serviceType: serviceType,
          subsType: 'OneTime',
        );
        return CheckoutBlockReason.fromValidations(
          monthlyValidation: monthlyValidation,
          oneTimeValidation: oneTimeValidation,
        );
      }

      final monthlyValidation = await repo.validateCheckout(
        customerId: customerId,
        vehicleId: vehicleId,
        serviceType: serviceType,
        subsType: 'Monthly',
      );
      return CheckoutBlockReason.fromValidations(
        monthlyValidation: monthlyValidation,
        oneTimeValidation: '',
      );
    } catch (_) {
      return const CheckoutBlockReason();
    }
  }

  /// Message when this vehicle already has an active monthly subscription.
  static String? activeSubscriptionMessage(CheckoutBlockReason reason) {
    if (!reason.blockOneTimeDueToMonthly) return null;
    if (reason.oneTimeMessage.isNotEmpty) return reason.oneTimeMessage;
    return CheckoutBlockReason.monthlyBlocksOneTimeFallback;
  }

  static Future<String?> blockMessageIfActiveSubscription({
    required String customerId,
    required String vehicleId,
    required String serviceHeader,
  }) async {
    final reason = await resolve(
      customerId: customerId,
      vehicleId: vehicleId,
      serviceHeader: serviceHeader,
    );
    return activeSubscriptionMessage(reason);
  }
}
