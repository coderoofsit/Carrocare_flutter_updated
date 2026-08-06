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
    // Ratio base must be the plan's own amount when present (may differ from
    // catalog/checkout price, e.g. plan 999 vs carPrice 847).
    final planAmount = CheckoutPricing.parseMoney(plan?.planAmount ?? '');
    final ratioBase = planAmount > 0
        ? planAmount
        : (unitPlanAmount > 0 ? unitPlanAmount : inclusiveTotal);
    if (ratioBase > 0 && unitPlatform > 0) {
      return ((unitPlatform * inclusiveTotal) / ratioBase).round();
    }

    return CheckoutPricing.derivePlatformFeeAmt(
      inclusiveTotal,
      CheckoutPricing.defaultPlatformFeePercent,
    );
  }

  static ({
    int total,
    double subTotal,
    double gstAmount,
    double platformFee,
    double serviceFee,
  }) breakdown({
    required int inclusiveTotal,
    required int unitPlanAmount,
    required int gstPercent,
    CheckoutPlan? plan,
    int? storedPlatformFeeAmt,
  }) {
    // Stored fee is the GST-inclusive platform share for this inclusiveTotal.
    if (storedPlatformFeeAmt != null && storedPlatformFeeAmt > 0) {
      return CheckoutPricing.breakdownWithPlatformFee(
        inclusiveTotal: inclusiveTotal,
        planAmount: inclusiveTotal,
        platformFeeAmt: storedPlatformFeeAmt,
        gstPercent: gstPercent,
      );
    }

    // Plan platform fee must be ratioed against the plan's own amount, not the
    // checkout/catalog price (those can diverge, e.g. 999 plan vs 847 total).
    final listedPlanAmount = CheckoutPricing.parseMoney(plan?.planAmount ?? '');
    final planAmount = listedPlanAmount > 0
        ? listedPlanAmount
        : (unitPlanAmount > 0 ? unitPlanAmount : inclusiveTotal);
    final unitPlatform = plan?.resolvedPlatformFeeAmt ?? 0;
    final platformFeeAmt = unitPlatform > 0
        ? unitPlatform
        : CheckoutPricing.derivePlatformFeeAmt(
            planAmount,
            CheckoutPricing.defaultPlatformFeePercent,
          );
    return CheckoutPricing.breakdownWithPlatformFee(
      inclusiveTotal: inclusiveTotal,
      planAmount: planAmount,
      platformFeeAmt: platformFeeAmt,
      gstPercent: gstPercent,
    );
  }
}
