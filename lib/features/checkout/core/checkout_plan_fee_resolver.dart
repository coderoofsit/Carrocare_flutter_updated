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
    if (filtered.isNotEmpty) return filtered.first;

    // Match exact planAmount across any subscription type first
    if (target > 0) {
      final exactMatch = plans.where((plan) {
        return CheckoutPricing.parseMoney(plan.planAmount) == target;
      }).toList();
      if (exactMatch.isNotEmpty) return exactMatch.first;
    }

    if (!monthly) {
      final oneTime = CheckoutPlanParams.pickOneTime(plans, planAmount: planAmount);
      if (oneTime != null) return oneTime;
      // When no separate one-time plan row exists in the database, use the service tier's
      // plan so platform fee, service charges, and GST structure remain identical.
      return CheckoutPlanParams.pickMonthly(plans, planAmount: planAmount);
    }
    return CheckoutPlanParams.pickMonthly(plans, planAmount: planAmount);
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

    final planAmount = CheckoutPricing.parseMoney(plan?.planAmount ?? '');
    final ratioBase = planAmount > 0
        ? planAmount
        : (unitPlanAmount > 0 ? unitPlanAmount : inclusiveTotal);
    var unitPlatform = plan?.resolvedPlatformFeeAmt ?? 0;
    if (unitPlatform <= 0) {
      final (canonicalPlatform, _) = CheckoutPlanParams.canonicalFeeSplit(
        packageType: plan?.packageType ?? '',
        planAmount: ratioBase.toString(),
      );
      unitPlatform = CheckoutPricing.parseMoney(canonicalPlatform);
    }
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
    var unitPlatform = plan?.resolvedPlatformFeeAmt ?? 0;
    if (unitPlatform <= 0) {
      final (canonicalPlatform, _) = CheckoutPlanParams.canonicalFeeSplit(
        packageType: plan?.packageType ?? '',
        planAmount: planAmount.toString(),
      );
      unitPlatform = CheckoutPricing.parseMoney(canonicalPlatform);
    }
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
