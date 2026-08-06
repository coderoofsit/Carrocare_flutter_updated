import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/checkout_plan.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';

/// Maps app vehicle/booking data to [get_plan] / [plans_list] API fields.
abstract final class CheckoutPlanParams {
  /// Razorpay plan `package_type` (Hatchback, Sedan, SUV, Bike).
  static String packageType({
    required String category,
    required String carName,
  }) {
    if (category.trim().isNotEmpty) {
      return CheckoutConstants.normalizePackageType(category);
    }
    return CheckoutConstants.normalizePackageType(carName);
  }

  /// Razorpay plan `vehicle_type` (Car or Bike — not body style).
  static String apiVehicleType({
    required String vehicleType,
    required String category,
    required String carName,
  }) {
    final raw = vehicleType.trim().toLowerCase();
    if (raw.contains('bike')) return 'Bike';
    if (raw.contains('car')) return 'Car';

    final pack = packageType(category: category, carName: carName).toLowerCase();
    if (pack.contains('bike')) return 'Bike';
    return 'Car';
  }

  static String apiVehicleTypeFromVehicle(VehicleItem vehicle) {
    return apiVehicleType(
      vehicleType: vehicle.vehicleType,
      category: vehicle.category,
      carName: vehicle.makeModel,
    );
  }

  static String packageTypeFromVehicle(VehicleItem vehicle) {
    return packageType(
      category: vehicle.category,
      carName: vehicle.makeModel,
    );
  }

  /// When [plans_list] returns nothing, still offer Monthly + OneTime from booking price.
  static List<CheckoutPlan> fallbackPlans({
    required String packageType,
    required String vehicleType,
    required String serviceType,
    required String planAmount,
  }) {
    return <CheckoutPlan>[
      CheckoutPlan(
        planId: '',
        packageType: packageType,
        vehicleType: vehicleType,
        subscriptionType: 'Monthly',
        serviceType: serviceType,
        planAmount: planAmount,
      ),
      CheckoutPlan(
        planId: '',
        packageType: packageType,
        vehicleType: vehicleType,
        subscriptionType: 'OneTime',
        serviceType: serviceType,
        planAmount: planAmount,
      ),
    ];
  }

  static List<CheckoutPlan> filterForBooking(
    List<CheckoutPlan> plans, {
    required String packageType,
    required String serviceType,
  }) {
    final normalizedPack = packageType.trim().toLowerCase();
    return plans
        .where((CheckoutPlan plan) {
          final packMatch =
              plan.packageType.trim().toLowerCase() == normalizedPack;
          final serviceMatch =
              serviceTypesMatch(plan.serviceType, serviceType);
          return packMatch && serviceMatch;
        })
        .toList();
  }

  static bool serviceTypesMatch(String a, String b) {
    return _normalizeServiceType(a) == _normalizeServiceType(b);
  }

  static String _normalizeServiceType(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  }

  static CheckoutPlan? pickMonthly(
    List<CheckoutPlan> plans, {
    String? planAmount,
  }) {
    final monthly = plans.where((CheckoutPlan plan) => plan.isMonthly).toList();
    if (monthly.isEmpty) {
      return null;
    }
    final target = planAmount?.trim() ?? '';
    if (target.isNotEmpty) {
      for (final CheckoutPlan plan in monthly) {
        if (plan.planAmount.trim() == target) {
          return plan;
        }
      }
    }
    return monthly.reduce((CheckoutPlan best, CheckoutPlan plan) {
      final bestAmount = int.tryParse(best.planAmount) ?? 0;
      final planAmountValue = int.tryParse(plan.planAmount) ?? 0;
      return planAmountValue > bestAmount ? plan : best;
    });
  }

  static CheckoutPlan? pickOneTime(List<CheckoutPlan> plans) {
    for (final plan in plans) {
      if (plan.isOneTime) return plan;
    }
    return null;
  }
}
