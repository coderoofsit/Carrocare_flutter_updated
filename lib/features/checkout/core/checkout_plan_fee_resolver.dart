import 'package:carrocare_flutter/features/checkout/core/checkout_plan_params.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/checkout_plan.dart';

/// Resolves platform/service fee splits from live plan data.
abstract final class CheckoutPlanFeeResolver {
  static CheckoutPlan? matchPlan({
    required List<CheckoutPlan> plans,
    required String planAmount,
    required bool monthly,
  }) {
    if (plans.isEmpty) return null;
    final target = CheckoutPricing.parseMoney(planAmount);
    final filtered = plans.where((plan) {
      final amount = CheckoutPricing.parseMoney(plan.planAmount);
      if (target > 0 && amount != target) return false;
      return monthly ? plan.isMonthly : plan.isOneTime;
    }).toList();
    if (filtered.isEmpty) {
      return monthly
          ? CheckoutPlanParams.pickMonthly(plans, planAmount: planAmount)
          : CheckoutPlanParams.pickOneTime(plans);
    }
    return filtered.first;
  }

  /// Platform fee INR for a checkout total, scaled from the matched plan ratio.
  static int platformFeeForTotal({
    required int inclusiveTotal,
    required int unitPlanAmount,
    CheckoutPlan? plan,
    int? storedPlatformFeeAmt,
  }) {
    if (storedPlatformFeeAmt != null && storedPlatformFeeAmt > 0) {
      return storedPlatformFeeAmt;
    }

    final unitPlatform = plan?.resolvedPlatformFeeAmt ?? 0;
    if (unitPlanAmount > 0 && unitPlatform > 0) {
      return ((unitPlatform * inclusiveTotal) / unitPlanAmount).round();
    }

    return CheckoutPricing.derivePlatformFeeAmt(
      inclusiveTotal,
      CheckoutPricing.defaultPlatformFeePercent,
    );
  }

  static ({
    int total,
    int subTotal,
    int gstAmount,
    int platformFee,
    int serviceFee,
  }) breakdown({
    required int inclusiveTotal,
    required int unitPlanAmount,
    required int gstPercent,
    CheckoutPlan? plan,
    int? storedPlatformFeeAmt,
  }) {
    final platformFeeAmt = platformFeeForTotal(
      inclusiveTotal: inclusiveTotal,
      unitPlanAmount: unitPlanAmount > 0 ? unitPlanAmount : inclusiveTotal,
      plan: plan,
      storedPlatformFeeAmt: storedPlatformFeeAmt,
    );
    return CheckoutPricing.breakdownWithPlatformFee(
      inclusiveTotal: inclusiveTotal,
      planAmount: unitPlanAmount > 0 ? unitPlanAmount : inclusiveTotal,
      platformFeeAmt: platformFeeAmt,
      gstPercent: gstPercent,
    );
  }
}
