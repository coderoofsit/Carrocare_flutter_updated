import 'package:carrocare_flutter/features/car_details/domain/entities/car_details_args.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_plan_fee_resolver.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/checkout_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CarDetailsArgs catalogPrice resolution', () {
    test('uses displayPrice when present', () {
      const args = CarDetailsArgs(
        carName: 'suv',
        carPrice: '931',
        carDesc: 'desc',
        carImage: 'img',
        carId: '1',
        header: 'Daily Car Wash',
        displayPrice: '1099',
      );
      expect(args.catalogPrice, '1099');
    });

    test('falls back to carPrice when displayPrice is empty', () {
      const args = CarDetailsArgs(
        carName: 'suv',
        carPrice: '1099',
        carDesc: 'desc',
        carImage: 'img',
        carId: '1',
        header: 'Daily Car Wash',
        displayPrice: '',
      );
      expect(args.catalogPrice, '1099');
    });
  });

  group('CheckoutPlanFeeResolver breakdown calculations', () {
    test('monthly breakdown matches matched plan fee split', () {
      const monthlyPlan = CheckoutPlan(
        planId: 'plan_1',
        packageType: 'SUV',
        vehicleType: 'Car',
        subscriptionType: 'Monthly',
        serviceType: 'Wash',
        planAmount: '1099',
        platformFeeAmt: '299',
        serviceFeeAmt: '800',
      );

      final breakdown = CheckoutPlanFeeResolver.breakdown(
        inclusiveTotal: 1099,
        unitPlanAmount: 1099,
        gstPercent: 18,
        plan: monthlyPlan,
      );

      expect(breakdown.total, 1099);
      expect(breakdown.serviceFee, 800.0);
      expect(breakdown.platformFee, 253.39);
      expect(breakdown.gstAmount, 45.61);
      expect(CheckoutPricing.round2(breakdown.platformFee + breakdown.serviceFee + breakdown.gstAmount), 1099.0);
    });

    test('one-time breakdown on catalog price (1099) preserves total 1099', () {
      final breakdown = CheckoutPlanFeeResolver.breakdown(
        inclusiveTotal: 1099,
        unitPlanAmount: 1099,
        gstPercent: 18,
        plan: null,
      );

      expect(breakdown.total, 1099);
      expect(CheckoutPricing.round2(breakdown.platformFee + breakdown.serviceFee + breakdown.gstAmount), 1099.0);
      expect(CheckoutPricing.mrpWithOffer(breakdown.total, months: 1), 1149);
    });

    test('one-time breakdown matches monthly plan split when only monthly plan exists', () {
      const plans = <CheckoutPlan>[
        CheckoutPlan(
          planId: 'plan_749',
          packageType: 'Hatchback',
          vehicleType: 'Car',
          subscriptionType: 'Monthly',
          serviceType: 'Wash',
          planAmount: '749',
          platformFeeAmt: '249',
          serviceFeeAmt: '500',
        ),
      ];

      final matchedMonthly = CheckoutPlanFeeResolver.matchPlan(
        plans: plans,
        planAmount: '749',
        monthly: true,
      );
      final matchedOneTime = CheckoutPlanFeeResolver.matchPlan(
        plans: plans,
        planAmount: '749',
        monthly: false,
      );

      expect(matchedMonthly, isNotNull);
      expect(matchedOneTime, isNotNull);
      expect(matchedOneTime?.planId, matchedMonthly?.planId);

      final monthlyBreakdown = CheckoutPlanFeeResolver.breakdown(
        inclusiveTotal: 749,
        unitPlanAmount: 749,
        gstPercent: 18,
        plan: matchedMonthly,
      );

      final oneTimeBreakdown = CheckoutPlanFeeResolver.breakdown(
        inclusiveTotal: 749,
        unitPlanAmount: 749,
        gstPercent: 18,
        plan: matchedOneTime,
      );

      expect(oneTimeBreakdown.total, 749);
      expect(oneTimeBreakdown.serviceFee, 500.0);
      expect(oneTimeBreakdown.platformFee, 211.02);
      expect(oneTimeBreakdown.gstAmount, 37.98);

      expect(oneTimeBreakdown.total, monthlyBreakdown.total);
      expect(oneTimeBreakdown.serviceFee, monthlyBreakdown.serviceFee);
      expect(oneTimeBreakdown.platformFee, monthlyBreakdown.platformFee);
      expect(oneTimeBreakdown.gstAmount, monthlyBreakdown.gstAmount);
    });

    test('all vehicle tiers and services match canonical price breakdowns', () {
      final allPlans = <CheckoutPlan>[
        // Hatchback Daily Wash & Wax
        const CheckoutPlan(
          planId: 'wash_hatchback',
          packageType: 'Hatchback',
          vehicleType: 'Car',
          subscriptionType: 'Monthly',
          serviceType: 'Wash',
          planAmount: '749',
          platformFeeAmt: '249',
          serviceFeeAmt: '500',
        ),
        // Sedan Daily Wash & Wax
        const CheckoutPlan(
          planId: 'wash_sedan',
          packageType: 'Sedan',
          vehicleType: 'Car',
          subscriptionType: 'Monthly',
          serviceType: 'Wash',
          planAmount: '999',
          platformFeeAmt: '299',
          serviceFeeAmt: '700',
        ),
        // SUV Daily Wash & Wax
        const CheckoutPlan(
          planId: 'wash_suv',
          packageType: 'SUV',
          vehicleType: 'Car',
          subscriptionType: 'Monthly',
          serviceType: 'Wash',
          planAmount: '1099',
          platformFeeAmt: '299',
          serviceFeeAmt: '800',
        ),
        // Bike Wash
        const CheckoutPlan(
          planId: 'wash_bike',
          packageType: 'Bike',
          vehicleType: 'Bike',
          subscriptionType: 'Monthly',
          serviceType: 'Wash',
          planAmount: '354',
          platformFeeAmt: '104',
          serviceFeeAmt: '250',
        ),
        // Extra Interior
        const CheckoutPlan(
          planId: 'extra_interior',
          packageType: 'ExtraInterior',
          vehicleType: 'Car',
          subscriptionType: 'OneTime',
          serviceType: 'AddOn',
          planAmount: '118',
          platformFeeAmt: '38',
          serviceFeeAmt: '80',
        ),
      ];

      // Test Hatchback (749)
      final hatchPlan = CheckoutPlanFeeResolver.matchPlan(plans: allPlans, planAmount: '749', monthly: false);
      final hatch = CheckoutPlanFeeResolver.breakdown(inclusiveTotal: 749, unitPlanAmount: 749, gstPercent: 18, plan: hatchPlan);
      expect(hatch.total, 749);
      expect(hatch.serviceFee, 500.0);
      expect(hatch.platformFee, 211.02);
      expect(hatch.gstAmount, 37.98);

      // Test Sedan (999)
      final sedanPlan = CheckoutPlanFeeResolver.matchPlan(plans: allPlans, planAmount: '999', monthly: false);
      final sedan = CheckoutPlanFeeResolver.breakdown(inclusiveTotal: 999, unitPlanAmount: 999, gstPercent: 18, plan: sedanPlan);
      expect(sedan.total, 999);
      expect(sedan.serviceFee, 700.0);
      expect(sedan.platformFee, 253.39);
      expect(sedan.gstAmount, 45.61);

      // Test SUV (1099)
      final suvPlan = CheckoutPlanFeeResolver.matchPlan(plans: allPlans, planAmount: '1099', monthly: false);
      final suv = CheckoutPlanFeeResolver.breakdown(inclusiveTotal: 1099, unitPlanAmount: 1099, gstPercent: 18, plan: suvPlan);
      expect(suv.total, 1099);
      expect(suv.serviceFee, 800.0);
      expect(suv.platformFee, 253.39);
      expect(suv.gstAmount, 45.61);

      // Test Bike (354)
      final bikePlan = CheckoutPlanFeeResolver.matchPlan(plans: allPlans, planAmount: '354', monthly: false);
      final bike = CheckoutPlanFeeResolver.breakdown(inclusiveTotal: 354, unitPlanAmount: 354, gstPercent: 18, plan: bikePlan);
      expect(bike.total, 354);
      expect(bike.serviceFee, 250.0);
      expect(bike.platformFee, 88.14);
      expect(bike.gstAmount, 15.86);

      // Test Extra Interior (118)
      final extraPlan = CheckoutPlanFeeResolver.matchPlan(plans: allPlans, planAmount: '118', monthly: false);
      final extra = CheckoutPlanFeeResolver.breakdown(inclusiveTotal: 118, unitPlanAmount: 118, gstPercent: 18, plan: extraPlan);
      expect(extra.total, 118);
      expect(extra.serviceFee, 80.0);
      expect(extra.platformFee, 32.20);
      expect(extra.gstAmount, 5.80);
    });

    test('multi-month one-time breakdown on 3 months (3297) scales correctly', () {
      final breakdown = CheckoutPlanFeeResolver.breakdown(
        inclusiveTotal: 3297,
        unitPlanAmount: 1099,
        gstPercent: 18,
        plan: null,
      );

      expect(breakdown.total, 3297);
      expect(CheckoutPricing.round2(breakdown.platformFee + breakdown.serviceFee + breakdown.gstAmount), 3297.0);
      expect(CheckoutPricing.mrpWithOffer(breakdown.total, months: 3), 3447);
    });
  });
}
