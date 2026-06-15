import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_block_reason.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_gst_config.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
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
import 'package:carrocare_flutter/features/checkout/presentation/services/razorpay_checkout_service.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/autopay_consent_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _paying = false;

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

  String get _apiPackType {
    if (_a.serviceType == CheckoutConstants.serviceWash ||
        _a.serviceType == CheckoutConstants.serviceBikeWash) {
      return CheckoutPlanParams.packageType(category: '', carName: _a.carName);
    }
    return CheckoutPlanParams.packageType(
      category: _a.vehicle.category,
      carName: _a.carName,
    );
  }

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
    setState(() => _loading = false);
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
      var plans = await sl<CheckoutRepository>().fetchPlansList(
        vehicleType: _apiVehicleType,
        serviceType: _apiServiceType,
        packType: _apiPackType,
        packAmount: _inclusivePackAmount,
      );
      plans = CheckoutPlanParams.filterForBooking(
        plans,
        packageType: _apiPackType,
        serviceType: _apiServiceType,
      );
      if (plans.isEmpty && !_isAddon && !_isExtraInterior) {
        plans = CheckoutPlanParams.fallbackPlans(
          packageType: _apiPackType,
          vehicleType: _apiVehicleType,
          serviceType: _apiServiceType,
          planAmount: _inclusivePackAmount,
        );
      }
      _plans = plans;
      _monthlyPlan = CheckoutPlanParams.pickMonthly(
        plans,
        planAmount: _inclusivePackAmount,
      );
    } catch (_) {
      if (!_isAddon && !_isExtraInterior) {
        _plans = CheckoutPlanParams.fallbackPlans(
          packageType: _apiPackType,
          vehicleType: _apiVehicleType,
          serviceType: _apiServiceType,
          planAmount: _inclusivePackAmount,
        );
        _monthlyPlan = CheckoutPlanParams.pickMonthly(
          _plans,
          planAmount: _inclusivePackAmount,
        );
      }
    }
  }

  int get _monthlyBase => CheckoutPricing.parseAmount(_inclusivePackAmount);

  int get _oneTimeBase {
    if (_oneTimeCheckout != null) {
      return CheckoutPricing.parseAmount(_oneTimeCheckout!.totalAmount);
    }
    return CheckoutPricing.parseAmount(_a.carPrice) * _selectedMonths;
  }

  int _finalAmount(int inclusiveBase) =>
      CheckoutPricing.inclusiveTotal(inclusiveBase, _gstPercent);

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
    if (!_acceptedTerms) {
      _toast('Please accept the terms and conditions');
      return;
    }
    setState(() => _paying = true);
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

      final priceSummary = RazorpayPriceSummary.fromInclusive(
        serviceLabel: _displayServiceType(),
        inclusiveTotal: _monthlyBase,
        gstPercent: _gstPercent,
      );
      if (!await showRazorpayPriceSummarySheet(
        context: context,
        summary: priceSummary,
      )) {
        return;
      }
      if (!mounted) return;

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
        onSuccess: () async {
          if (!mounted) return;
          context.go('/payment-success');
        },
      );
    } catch (e) {
      _toast(
        e.toString().contains('Timeout')
            ? 'Timeout.Try after sometime'
            : e.toString(),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _payOneTime({required bool monthlyCard}) async {
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

    setState(() => _paying = true);
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

      final keys = await sl<CheckoutRepository>().getRazorpayKeys();
      final base = monthlyCard ? _monthlyBase : _oneTimeBase;
      final amountPaise = _finalAmount(base) * 100;
      final priceSummary = RazorpayPriceSummary.fromInclusive(
        serviceLabel: _displayServiceType(),
        inclusiveTotal: base,
        gstPercent: _gstPercent,
      );
      if (!await showRazorpayPriceSummarySheet(
        context: context,
        summary: priceSummary,
      )) {
        return;
      }
      if (!mounted) return;

      final action = CheckoutConstants.resolveAction(
        serviceType: _a.serviceType,
        isMonthlyPay: monthlyCard,
        isExtraInteriorName: _isExtraInterior,
      );

      _razorpay.open(
        keyId: keys.keyId,
        amountPaise: amountPaise,
        description: _displayServiceType(),
        email: _email,
        contact: _mobile,
        priceSummary: priceSummary,
        onSuccess: (paymentId) => _placeOrder(
          paymentId: paymentId,
          action: action,
          monthlyCard: monthlyCard,
        ),
        onError: (message) => _toast(message),
      );
    } catch (_) {
      _toast('Timeout.Try after sometime');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _placeOrder({
    required String paymentId,
    required String action,
    required bool monthlyCard,
  }) async {
    setState(() => _paying = true);
    try {
      final base = monthlyCard ? _monthlyBase : _oneTimeBase;
      final breakdown = CheckoutPricing.breakdownFromInclusive(base, _gstPercent);
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
          subTotal: breakdown.subTotal.toString(),
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
          subTotal: breakdown.subTotal.toString(),
          gst: gst,
          totalAmount: total,
          scheduleDate: _preferDate,
          scheduleTime: _preferTime,
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
          subTotal: breakdown.subTotal.toString(),
          gst: gst,
          totalAmount: total,
          serviceType: 'Wash',
        );
      }

      _toast(message);
      if (!mounted) return;
      context.go('/payment-success');
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _paying = false);
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
    final breakdown = CheckoutPricing.breakdownFromInclusive(base, _gstPercent);
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
      packAmount: _a.carPrice,
      carId: _a.vehicle.id,
      paidMonths: monthlyCard ? '1' : _selectedMonths.toString(),
      fineAmount: _fineAmount,
      subTotal: breakdown.subTotal.toString(),
      gstPercent: _gstPercent.toString(),
      gstAmount: tax.toString(),
      totalAmount: total.toString(),
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

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 35,
                      height: 35,
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(5),
                      child: Image.asset('assets/images/back.png'),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'PAYMENT OPTION',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/cart').then((_) => _bootstrap()),
                    child: SizedBox(
                      width: 35,
                      height: 35,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Center(
                            child: SvgPicture.asset(
                              'assets/vectors/ic_cart.svg',
                              width: 25,
                              height: 25,
                              colorFilter: const ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          if (_cartCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_cartCount',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEDEFF1),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                        child: Column(
                          children: <Widget>[
                            if (_showExtraDate) ...<Widget>[
                              _dateCard(),
                              const SizedBox(height: 8),
                            ],
                            _vehicleCard(vehicle),
                            if (_monthlyBlockedMessage.isNotEmpty &&
                                _isWashOrBike) ...<Widget>[
                              const SizedBox(height: 8),
                              _checkoutBlockedBanner(_monthlyBlockedMessage),
                            ],
                            if (_blockOneTimeDueToMonthly &&
                                (_isWashOrBike || _showExtraDate)) ...<Widget>[
                              const SizedBox(height: 8),
                              _checkoutBlockedBanner(_oneTimeBlockedMessage),
                            ],
                            if (_showMonthlyCard) ...<Widget>[
                              const SizedBox(height: 8),
                              AutopayConsentPanel(
                                enableAutopay: true,
                                showAutopayToggle: false,
                                acceptedTerms: _acceptedTerms,
                                onAutopayChanged: (_) {},
                                onTermsChanged: (value) =>
                                    setState(() => _acceptedTerms = value),
                                renewalAmount: CheckoutPricing.rupee(
                                  _finalAmount(_monthlyBase),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _subscriptionCard(
                                title: 'Monthly Subscription',
                                subtitle:
                                    'Auto-renews each month (Razorpay subscription)',
                                base: _monthlyBase,
                                onPay: _payMonthly,
                                onCart: () => _addToCart(monthlyCard: true),
                                payLabel: 'Pay Now',
                                payEnabled: _acceptedTerms,
                              ),
                            ],
                            if (_showOneTimeCard) ...<Widget>[
                              const SizedBox(height: 8),
                              _subscriptionCard(
                                title: _isAddon
                                    ? 'One Time Subscription'
                                    : 'One Time Prepay',
                                subtitle: _isAddon
                                    ? 'One-time payment'
                                    : '$_selectedMonths month(s) prepaid — not auto-renew',
                                base: _oneTimeBase,
                                onPay: () => _payOneTime(monthlyCard: false),
                                onCart: () => _addToCart(monthlyCard: false),
                                payLabel: 'Pay Now',
                                showMonths: _isWashOrBike,
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
            if (_paying)
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primary,
              ),
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
    return Card(
      color: const Color(0xFFFFF3E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.info_outline, color: Color(0xFFE65100)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
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

  Widget _subscriptionCard({
    required String title,
    required String subtitle,
    required int base,
    required VoidCallback onPay,
    required VoidCallback onCart,
    required String payLabel,
    bool showMonths = false,
    bool payEnabled = true,
  }) {
    final finalAmt = _finalAmount(base);
    final mrp = CheckoutPricing.mrpWithOffer(
      finalAmt,
      months: showMonths ? _selectedMonths : 1,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.black),
            ),
            if (showMonths) ...<Widget>[
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
            if (_gstPercent > 0)
              Text('Offer Price applied with GST ($_gstPercent%)'),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _paying ? null : onCart,
                    child: const Text('Add To Cart'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _paying || !payEnabled ? null : onPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(payLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
