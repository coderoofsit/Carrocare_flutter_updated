import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_app_bar.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_block_reason.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_gst_config.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_plan_fee_resolver.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_plan_params.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_service_type_mapper.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/checkout_plan.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/one_time_wash_checkout.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/payment_option_args.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/razorpay_price_summary_sheet.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:carrocare_flutter/features/daily_wash/domain/repositories/daily_wash_repository.dart';
import 'package:carrocare_flutter/features/bike_wash/domain/repositories/bike_wash_repository.dart';
import 'package:carrocare_flutter/features/checkout/core/monthly_subscription_checkout.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/checkout_navigation.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/razorpay_checkout_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum _PaymentCardAction { monthly, oneTime }

class PaymentOptionPage extends StatefulWidget {
  const PaymentOptionPage({super.key, required this.args});

  final PaymentOptionArgs args;

  @override
  State<PaymentOptionPage> createState() => _PaymentOptionPageState();
}

class _PaymentOptionPageState extends State<PaymentOptionPage> {
  final RazorpayCheckoutService _razorpay = RazorpayCheckoutService();
  final CartLocalStorage _cartStorage = CartLocalStorage();

  String _token = '';
  String _customerId = '';
  String _email = '';
  String _mobile = '';
  int _gstPercent = 0;
  int _cartCount = 0;
  bool _loading = true;
  _PaymentCardAction? _payingCard;

  OneTimeWashCheckout? _oneTimeCheckout;
  int _selectedMonths = 1;
  String _preferDate = '';
  String _preferTime = CheckoutConstants.preferredTimes.first;
  String _fineAmount = '0';
  String _discountAmount = '0';
  bool _acceptedTerms = false;
  List<CheckoutPlan> _plans = <CheckoutPlan>[];
  CheckoutPlan? _monthlyPlan;
  String _monthlyBlockedMessage = '';
  String _oneTimeBlockedMessage = '';
  bool _blockOneTimeDueToMonthly = false;
  String _resolvedInclusivePackAmount = '';
  bool _autoRenew = true;

  PaymentOptionArgs get _a => widget.args;

  bool get _isWashOrBike =>
      _a.serviceType == CheckoutConstants.serviceWash ||
      _a.serviceType == CheckoutConstants.serviceBikeWash;

  bool get _isAddon => _a.serviceType == CheckoutConstants.serviceAddon;

  bool get _isExtraInterior =>
      _a.serviceType == CheckoutConstants.serviceExtraInterior ||
      _a.carName.toLowerCase().startsWith('extra');

  bool get _showExtraDate => _isAddon || _isExtraInterior;

  bool get _showMonthlyCard =>
      _monthlyPlan != null &&
      !_isAddon &&
      !_isExtraInterior &&
      _monthlyBlockedMessage.isEmpty;

  bool get _showOneTimeCard =>
      (_isWashOrBike || _isAddon || _isExtraInterior) &&
      !_blockOneTimeDueToMonthly;

  bool get _canToggleAutoRenew => _showMonthlyCard && _showOneTimeCard;

  bool get _isSubscriptionMode {
    if (_showMonthlyCard && !_showOneTimeCard) return true;
    if (!_showMonthlyCard && _showOneTimeCard) return false;
    return _autoRenew;
  }

  String get _apiPackType {
    if (_a.serviceType == CheckoutConstants.serviceWash ||
        _a.serviceType == CheckoutConstants.serviceBikeWash ||
        _isAddon ||
        _isExtraInterior) {
      return CheckoutPlanParams.packageType(category: '', carName: _a.carName);
    }
    return CheckoutPlanParams.packageType(
      category: _a.vehicle.category,
      carName: _a.carName,
    );
  }

  String get _apiPlanServiceType => apiPlanServiceType(_a.serviceType);

  String get _apiVehicleType => CheckoutPlanParams.apiVehicleTypeFromVehicle(
        _a.vehicle,
      );

  String get _apiServiceType =>
      apiServiceTypeForSubscription(_a.serviceType);

  /// GST-inclusive price shown to the customer (drives get_plan + checkout totals).
  String get _inclusivePackAmount {
    if (_resolvedInclusivePackAmount.isNotEmpty) {
      return _resolvedInclusivePackAmount;
    }
    if (_a.booking.displayPrice.isNotEmpty) {
      return _a.booking.displayPrice;
    }
    return _a.carPrice;
  }

  String get _monthlyPackAmount => _inclusivePackAmount;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _customerId = prefs.getString('customer_id') ?? '';
    _email = prefs.getString('email') ?? '';
    _mobile = prefs.getString('mobile') ?? prefs.getString('usermobile') ?? '';
    _gstPercent = CheckoutGstConfig.resolvePercent(prefs);
    _cartCount = await _cartStorage.count();

    await _resolveTierPrice();

    if (_isWashOrBike) {
      try {
        _oneTimeCheckout =
            await sl<CheckoutRepository>().fetchOneTimeWashCheckout(
          customerId: _customerId,
          packAmount: _inclusivePackAmount,
          vehicleId: _a.vehicle.id,
          serviceType: CheckoutConstants.oneTimeApiService(_a.serviceType),
        );
        if (_oneTimeCheckout != null) {
          _fineAmount = _oneTimeCheckout!.fineAmount;
          _discountAmount = _oneTimeCheckout!.discountAmount;
        }
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        if (message.isNotEmpty) {
          _oneTimeBlockedMessage = message;
          _blockOneTimeDueToMonthly = true;
        }
      }
    }

    await _loadPlans();

    if (_monthlyPlan != null &&
        !_isAddon &&
        !_isExtraInterior &&
        _customerId.isNotEmpty) {
      try {
        _monthlyBlockedMessage =
            await sl<CheckoutRepository>().validateCheckout(
          customerId: _customerId,
          vehicleId: _a.vehicle.id,
          serviceType: apiServiceTypeForValidation(_a.serviceType),
          subsType: 'Monthly',
        );
      } catch (_) {}
    }

    var oneTimeValidation = '';
    if (_isWashOrBike || _isAddon || _isExtraInterior) {
      if (_customerId.isNotEmpty) {
        try {
          oneTimeValidation =
              await sl<CheckoutRepository>().validateCheckout(
            customerId: _customerId,
            vehicleId: _a.vehicle.id,
            serviceType: apiServiceTypeForValidation(_a.serviceType),
            subsType: 'OneTime',
          );
        } catch (_) {}
      }
    }

    final blockReason = CheckoutBlockReason.fromValidations(
      monthlyValidation: _monthlyBlockedMessage,
      oneTimeValidation: oneTimeValidation,
    );
    _blockOneTimeDueToMonthly = blockReason.blockOneTimeDueToMonthly;
    if (blockReason.oneTimeMessage.isNotEmpty) {
      _oneTimeBlockedMessage = blockReason.oneTimeMessage;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _autoRenew = _showMonthlyCard;
    });
  }

  Future<void> _resolveTierPrice() async {
    if (_a.serviceType == CheckoutConstants.serviceWash) {
      try {
        final (_, services) =
            await sl<DailyWashRepository>().getDailyCarWashServices();
        final target = _a.carName.trim().toLowerCase();
        for (final service in services) {
          if (service.type.trim().toLowerCase() == target) {
            _resolvedInclusivePackAmount = service.displayPrice;
            return;
          }
        }
      } catch (_) {}
      return;
    }
    if (_a.serviceType == CheckoutConstants.serviceBikeWash) {
      try {
        final service = await sl<BikeWashRepository>().getBikeWashService();
        _resolvedInclusivePackAmount = service.displayPrice;
      } catch (_) {}
    }
  }

  Future<void> _loadPlans() async {
    try {
      final rawPlans = await sl<CheckoutRepository>().fetchPlansList(
        vehicleType: _apiVehicleType,
        serviceType: _apiPlanServiceType,
        packType: _apiPackType,
        packAmount: _inclusivePackAmount,
      );
      var plans = CheckoutPlanParams.filterForBooking(
        rawPlans,
        packageType: _apiPackType,
        serviceType: _apiPlanServiceType,
      );
      if (plans.isEmpty) {
        final targetAmt = CheckoutPricing.parseMoney(_inclusivePackAmount);
        plans = rawPlans.where((p) {
          final amt = CheckoutPricing.parseMoney(p.planAmount);
          final packMatch =
              p.packageType.trim().toLowerCase() == _apiPackType.trim().toLowerCase();
          return (targetAmt > 0 && amt == targetAmt) || packMatch;
        }).toList();
      }
      if (plans.isEmpty) {
        plans = CheckoutPlanParams.fallbackPlans(
          packageType: _apiPackType,
          vehicleType: _apiVehicleType,
          serviceType: _apiPlanServiceType,
          planAmount: _inclusivePackAmount,
        );
      }
      _plans = plans;
      _monthlyPlan = CheckoutPlanParams.pickMonthly(
        plans,
        planAmount: _inclusivePackAmount,
      );
    } catch (_) {
      _plans = CheckoutPlanParams.fallbackPlans(
        packageType: _apiPackType,
        vehicleType: _apiVehicleType,
        serviceType: _apiPlanServiceType,
        planAmount: _inclusivePackAmount,
      );
      _monthlyPlan = CheckoutPlanParams.pickMonthly(
        _plans,
        planAmount: _inclusivePackAmount,
      );
    }
  }

  int get _monthlyBase => CheckoutPricing.parseAmount(_inclusivePackAmount);

  int get _oneTimeBase {
    if (_oneTimeCheckout != null) {
      return CheckoutPricing.parseAmount(_oneTimeCheckout!.totalAmount);
    }
    return CheckoutPricing.parseAmount(_inclusivePackAmount) * _selectedMonths;
  }

  int _finalAmount(int inclusiveBase) =>
      CheckoutPricing.inclusiveTotal(inclusiveBase, _gstPercent);

  int _unitPlanAmount({required bool monthly}) {
    if (monthly) return _monthlyBase;
    final resolved = CheckoutPricing.parseMoney(_inclusivePackAmount);
    if (resolved > 0) return resolved;
    return CheckoutPricing.parseMoney(_inclusivePackAmount);
  }

  CheckoutPlan? _planForBreakdown({required bool monthly}) {
    if (monthly) return _monthlyPlan;
    return CheckoutPlanParams.pickOneTime(_plans) ?? _monthlyPlan;
  }

  RazorpayPriceSummary _priceSummaryFor(
    int inclusiveTotal,
    String label, {
    required bool monthly,
  }) {
    final unitPlan = _unitPlanAmount(monthly: monthly);
    final plan = _planForBreakdown(monthly: monthly);
    final breakdown = CheckoutPlanFeeResolver.breakdown(
      inclusiveTotal: inclusiveTotal,
      unitPlanAmount: unitPlan > 0 ? unitPlan : inclusiveTotal,
      gstPercent: _gstPercent,
      plan: plan,
    );
    return RazorpayPriceSummary(
      serviceLabel: label,
      total: breakdown.total,
      subTotal: breakdown.subTotal,
      gstAmount: breakdown.gstAmount,
      gstPercent: _gstPercent,
      platformFee: breakdown.platformFee,
      serviceFee: breakdown.serviceFee,
    );
  }

  ({
    int total,
    double subTotal,
    double gstAmount,
    double platformFee,
    double serviceFee,
  }) _breakdownFor(int inclusiveTotal, {required bool monthly}) {
    final unitPlan = _unitPlanAmount(monthly: monthly);
    final plan = _planForBreakdown(monthly: monthly);
    return CheckoutPlanFeeResolver.breakdown(
      inclusiveTotal: inclusiveTotal,
      unitPlanAmount: unitPlan > 0 ? unitPlan : inclusiveTotal,
      gstPercent: _gstPercent,
      plan: plan,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _preferDate = DateFormat('d/M/y').format(picked);
    });
  }

  Future<void> _pickTime() async {
    if (_preferDate.isEmpty) {
      _toast(CheckoutConstants.chooseDateTime);
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: CheckoutConstants.preferredTimes
                .map(
                  (time) => ListTile(
                    title: Text(time),
                    onTap: () => Navigator.pop(context, time),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected != null) setState(() => _preferTime = selected);
  }

  Future<void> _payMonthly() async {
    if (_payingCard != null) return;
    if (!_acceptedTerms) {
      _toast('Please accept the terms and conditions');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _payingCard = _PaymentCardAction.monthly);
    try {
      final validation = await sl<CheckoutRepository>().validateCheckout(
        customerId: _customerId,
        vehicleId: _a.vehicle.id,
        serviceType: apiServiceTypeForValidation(_a.serviceType),
        subsType: 'Monthly',
      );
      if (validation.isNotEmpty) {
        _toast(validation);
        return;
      }
      if (!mounted) return;

      final priceSummary = _priceSummaryFor(
        _monthlyBase,
        _displayServiceType(),
        monthly: true,
      );
      final router = GoRouter.of(context);
      final confirmed = await showRazorpayPriceSummarySheet(
        context: context,
        summary: priceSummary,
        onConfirmPay: () async {
          await MonthlySubscriptionCheckout.run(
            razorpay: _razorpay,
            token: _token,
            customerId: _customerId,
            vehicleId: _a.vehicle.id,
            packType: _apiPackType,
            vehicleType: _apiVehicleType,
            serviceType: _apiServiceType,
            packAmount: _monthlyPackAmount,
            gstPercent: _gstPercent,
            priceSummary: priceSummary,
            onError: _toast,
            onSuccess: () async {},
          );
        },
      );
      if (!confirmed || !mounted) return;
      goToPaymentSuccess(router);
    } catch (e) {
      _toast(
        e.toString().contains('Timeout')
            ? 'Timeout.Try after sometime'
            : e.toString(),
      );
    } finally {
      if (mounted) setState(() => _payingCard = null);
    }
  }

  Future<void> _payOneTime({required bool monthlyCard}) async {
    if (_payingCard != null) return;
    if (_blockOneTimeDueToMonthly) {
      _toast(_oneTimeBlockedMessage.isNotEmpty
          ? _oneTimeBlockedMessage
          : CheckoutBlockReason.monthlyBlocksOneTimeFallback);
      return;
    }
    if (_showExtraDate && _preferDate.isEmpty) {
      _toast(CheckoutConstants.chooseDateTime);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(
      () => _payingCard = monthlyCard
          ? _PaymentCardAction.monthly
          : _PaymentCardAction.oneTime,
    );
    try {
      final validation = await sl<CheckoutRepository>().validateCheckout(
        customerId: _customerId,
        vehicleId: _a.vehicle.id,
        serviceType: apiServiceTypeForValidation(_a.serviceType),
        subsType: 'OneTime',
      );
      if (validation.isNotEmpty) {
        _toast(validation);
        return;
      }
      if (!mounted) return;

      final base = monthlyCard ? _monthlyBase : _oneTimeBase;
      final amountPaise = _finalAmount(base) * 100;
      final priceSummary = _priceSummaryFor(
        base,
        _displayServiceType(),
        monthly: monthlyCard,
      );
      final action = CheckoutConstants.resolveAction(
        serviceType: _a.serviceType,
        isMonthlyPay: monthlyCard,
        isExtraInteriorName: _isExtraInterior,
      );
      final router = GoRouter.of(context);
      final confirmed = await showRazorpayPriceSummarySheet(
        context: context,
        summary: priceSummary,
        onConfirmPay: () async {
          final keys = await sl<CheckoutRepository>().getRazorpayKeys();
          if (!mounted) return;

          final paymentId = await _razorpay.openAndWait(
            keyId: keys.keyId,
            amountPaise: amountPaise,
            description: _displayServiceType(),
            email: _email,
            contact: _mobile,
            priceSummary: priceSummary,
          );
          await _placeOrder(
            paymentId: paymentId,
            action: action,
            monthlyCard: monthlyCard,
            navigateOnSuccess: false,
          );
        },
      );
      if (!confirmed || !mounted) return;
      goToPaymentSuccess(router);
    } catch (_) {
      _toast('Timeout.Try after sometime');
    } finally {
      if (mounted) setState(() => _payingCard = null);
    }
  }

  Future<void> _placeOrder({
    required String paymentId,
    required String action,
    required bool monthlyCard,
    bool navigateOnSuccess = true,
  }) async {
    if (_payingCard == null) {
      setState(
        () => _payingCard = monthlyCard
            ? _PaymentCardAction.monthly
            : _PaymentCardAction.oneTime,
      );
    }
    try {
      final base = monthlyCard ? _monthlyBase : _oneTimeBase;
      final breakdown = _breakdownFor(base, monthly: monthlyCard);
      final total = breakdown.total.toString();
      final gst = _gstPercent.toString();
      String message;

      if (_isExtraInterior) {
        message = await sl<CheckoutRepository>().placeOneTimeExtraOrder(
          action: CheckoutConstants.actionOneTime,
          paymentId: paymentId,
          customerId: _customerId,
          token: _token,
          packAmount: _inclusivePackAmount,
          vehicleId: _a.vehicle.id,
          subTotal: CheckoutPricing.moneyString(breakdown.subTotal),
          gst: gst,
          totalAmount: total,
          scheduleDate: _preferDate,
          scheduleTime: _preferTime,
        );
      } else if (_isAddon) {
        message = await sl<CheckoutRepository>().placeOneTimeAddOnOrder(
          paymentId: paymentId,
          customerId: _customerId,
          token: _token,
          packAmount: _inclusivePackAmount,
          vehicleId: _a.vehicle.id,
          paidMonths: '1',
          fineAmount: _fineAmount,
          subTotal: CheckoutPricing.moneyString(breakdown.subTotal),
          gst: gst,
          totalAmount: total,
          scheduleDate: _preferDate,
          scheduleTime: _preferTime,
          packType: _apiPackType,
        );
      } else {
        message = await sl<CheckoutRepository>().placeOneTimeWashOrder(
          paymentId: paymentId,
          customerId: _customerId,
          token: _token,
          packAmount: _inclusivePackAmount,
          vehicleId: _a.vehicle.id,
          paidMonths: _selectedMonths.toString(),
          fineAmount: _fineAmount,
          subTotal: CheckoutPricing.moneyString(breakdown.subTotal),
          gst: gst,
          totalAmount: total,
          serviceType: 'Wash',
          packType: _apiPackType,
        );
      }

      _toast(message);
      if (!mounted) return;
      if (navigateOnSuccess) {
        goToPaymentSuccess(GoRouter.of(context));
      }
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _payingCard = null);
    }
  }

  Future<void> _addToCart({required bool monthlyCard}) async {
    if (!monthlyCard && _blockOneTimeDueToMonthly) {
      _toast(_oneTimeBlockedMessage.isNotEmpty
          ? _oneTimeBlockedMessage
          : CheckoutBlockReason.monthlyBlocksOneTimeFallback);
      return;
    }
    if (_showExtraDate && _preferDate.isEmpty) {
      _toast(CheckoutConstants.chooseDateTime);
      return;
    }

    final subsType = monthlyCard ? 'Monthly' : 'OneTime';
    final validation = await sl<CheckoutRepository>().validateCheckout(
      customerId: _customerId,
      vehicleId: _a.vehicle.id,
      serviceType: apiServiceTypeForValidation(_a.serviceType),
      subsType: subsType,
    );
    if (validation.isNotEmpty) {
      _toast(validation);
      return;
    }

    final base = monthlyCard ? _monthlyBase : _oneTimeBase;
    final breakdown = _breakdownFor(base, monthly: monthlyCard);
    final tax = breakdown.gstAmount;
    final total = breakdown.total;
    final action = CheckoutConstants.resolveAction(
      serviceType: _a.serviceType,
      isMonthlyPay: monthlyCard,
      isExtraInteriorName: _isExtraInterior,
    );
    final dbType = '$action=${_a.serviceType}';

    final item = CartItem(
      dbType: dbType,
      action: action,
      serviceType: _a.serviceType,
      carImage: _a.vehicle.image,
      carMakeModel: _a.vehicle.makeModel,
      carNo: _a.vehicle.vehicleNo,
      packAmount: _inclusivePackAmount.isNotEmpty
          ? _inclusivePackAmount
          : _a.carPrice,
      carId: _a.vehicle.id,
      paidMonths: monthlyCard ? '1' : _selectedMonths.toString(),
      fineAmount: _fineAmount,
      subTotal: CheckoutPricing.moneyString(breakdown.subTotal),
      gstPercent: _gstPercent.toString(),
      gstAmount: CheckoutPricing.moneyString(tax),
      totalAmount: total.toString(),
      platformFeeAmt: CheckoutPricing.moneyString(
        breakdown.platformFee + breakdown.gstAmount,
      ),
      serviceFeeAmt: CheckoutPricing.moneyString(breakdown.serviceFee),
      scheduleDate: _preferDate,
      scheduleTime: _preferTime,
      carName: _a.carName,
      carCategory: _a.vehicle.category,
      header: _a.serviceType,
    );

    final ok = await _cartStorage.upsert(item);
    if (!ok) {
      _toast('Added Failed.');
      return;
    }
    _toast('Added.');
    _cartCount = await _cartStorage.count();
    if (!mounted) return;
    setState(() {});
    context.push('/cart');
  }

  String _displayServiceType() {
    if (_isWashOrBike) return 'Wash';
    if (_isAddon) return 'Add On';
    if (_isExtraInterior) return 'Add On';
    if (_a.serviceType == CheckoutConstants.serviceDisinfection) {
      return 'Disinfection';
    }
    return _a.serviceType;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _a.vehicle;

    return CarroCareScaffold(
      title: 'Payment Option',
      onBack: () => context.pop(),
      actions: <Widget>[
        CarroCareCartAction(
          count: _cartCount,
          onTap: () => context.push('/cart').then((_) => _bootstrap()),
        ),
      ],
      footer: _payingCard != null
          ? const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.primary,
            )
          : null,
      body: _loading
          ? const CarroCareLoadingOverlay()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: <Widget>[
                  if (_showExtraDate) ...<Widget>[
                    _dateCard(),
                    const SizedBox(height: 10),
                  ],
                  _vehicleCard(vehicle),
                  if (_monthlyBlockedMessage.isNotEmpty &&
                      _isWashOrBike) ...<Widget>[
                    const SizedBox(height: 10),
                    _checkoutBlockedBanner(_monthlyBlockedMessage),
                  ],
                  if (_blockOneTimeDueToMonthly &&
                      (_isWashOrBike || _showExtraDate)) ...<Widget>[
                    const SizedBox(height: 10),
                    _checkoutBlockedBanner(_oneTimeBlockedMessage),
                  ],
                  if (_showMonthlyCard || _showOneTimeCard) ...<Widget>[
                    const SizedBox(height: 10),
                    _paymentOptionCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _dateCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Preferred Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _preferDate.isEmpty ? 'Preferred Date' : _preferDate,
                ),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Preferred Time',
                  border: OutlineInputBorder(),
                ),
                child: Text(_preferTime),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkoutBlockedBanner(String message) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppDecorations.inputRadius),
        border: Border.all(color: AppColors.primaryTintStrong),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.dmSans(
                fontSize: 13,
                color: AppColors.grey700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard(VehicleItem vehicle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                vehicle.image,
                width: 90,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/placeholder.png',
                  width: 90,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    vehicle.makeModel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text('Color: ${vehicle.color}'),
                  Text('No: ${vehicle.vehicleNo}'),
                  Text('Parking: ${vehicle.parkingArea}'),
                  Text('Lot: ${vehicle.parkingLotNo}'),
                  Text(vehicle.apartmentName),
                  Text(
                    '${vehicle.preferredSchedule}\n${vehicle.preferredTime}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOptionCard() {
    final isSubscription = _isSubscriptionMode;
    final base = isSubscription ? _monthlyBase : _oneTimeBase;
    final finalAmt = _finalAmount(base);
    final mrp = CheckoutPricing.mrpWithOffer(
      finalAmt,
      months: !isSubscription && _isWashOrBike ? _selectedMonths : 1,
    );
    final cardAction =
        isSubscription ? _PaymentCardAction.monthly : _PaymentCardAction.oneTime;
    final cardBusy = _payingCard == cardAction;
    final renewalHint = CheckoutPricing.rupee(_finalAmount(_monthlyBase));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Payment',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (_canToggleAutoRenew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _autoRenew,
                onChanged: cardBusy
                    ? null
                    : (value) => setState(() => _autoRenew = value),
                title: const Text(
                  'Auto-renew',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  isSubscription
                      ? 'Monthly subscription — renews automatically each billing cycle. We will charge $renewalHint on your renewal date.'
                      : _isAddon
                          ? 'One-time payment — no automatic renewal.'
                          : 'One-time payment — not auto-renew.',
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
                thumbColor: WidgetStateProperty.resolveWith<Color>(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.white,
                ),
                trackColor: WidgetStateProperty.resolveWith<Color>(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.grey.shade300,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  isSubscription
                      ? 'Monthly subscription — auto-renews each billing cycle.'
                      : _isAddon
                          ? 'One-time payment'
                          : 'One-time payment — not auto-renew',
                  style: const TextStyle(fontSize: 14, color: AppColors.black),
                ),
              ),
            const SizedBox(height: 4),
            _termsCheckbox(),
            if (!isSubscription && _isWashOrBike) ...<Widget>[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedMonths,
                decoration: const InputDecoration(
                  labelText: 'Subscription',
                  border: OutlineInputBorder(),
                ),
                items: List<DropdownMenuItem<int>>.generate(
                  24,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(CheckoutConstants.subscriptionMonths[index]),
                  ),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedMonths = value);
                },
              ),
            ],
            const SizedBox(height: 8),
            Text('Service: ${_displayServiceType()}'),
            Text(
              'Package: ${_a.vehicle.category.isEmpty ? _a.carName : _a.vehicle.category}',
            ),
            const Divider(),
            Text('MRP: ${CheckoutPricing.rupee(mrp)}'),
            Text(
              'DEAL: ${CheckoutPricing.rupee(finalAmt)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (_gstPercent > 0) ...<Widget>[
              Builder(
                builder: (context) {
                  final b = _breakdownFor(finalAmt, monthly: isSubscription);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Platform fee: ${CheckoutPricing.rupee(b.platformFee)}',
                      ),
                      Text(
                        'Service provider: ${CheckoutPricing.rupee(b.serviceFee)}',
                      ),
                      Text(
                        'GST ($_gstPercent% on platform fee): ${CheckoutPricing.rupee(b.gstAmount)}',
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: cardBusy
                        ? null
                        : () => _addToCart(monthlyCard: isSubscription),
                    child: const Text('Add To Cart'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: cardBusy || !_acceptedTerms
                        ? null
                        : () {
                            if (isSubscription) {
                              _payMonthly();
                            } else {
                              _payOneTime(monthlyCard: false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.45,
                      ),
                      disabledForegroundColor: AppColors.white,
                    ),
                    child: cardBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text('Pay Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _termsCheckbox() {
    return CheckboxListTile(
      value: _acceptedTerms,
      onChanged: _payingCard != null
          ? null
          : (value) => setState(() => _acceptedTerms = value ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: AppColors.black),
          children: <TextSpan>[
            const TextSpan(text: 'I accept the '),
            TextSpan(
              text: 'terms and conditions',
              style: const TextStyle(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrl(
                      Uri.parse(AppUrls.termsAndConditions),
                      mode: LaunchMode.externalApplication,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
