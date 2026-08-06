import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/bill_line_row.dart';
import 'package:carrocare_flutter/core/widgets/dotted_divider.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_block_reason.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_vehicle_gate.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_service_type_mapper.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_plan_fee_resolver.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_plan_params.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/checkout_plan.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/one_time_wash_checkout.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/renew/core/renew_checkout_mapper.dart';
import 'package:carrocare_flutter/features/vehicle_list/domain/entities/vehicle_list_args.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Android renew flow smart checkout (`RenewActivity` + `RenewOrderAdapter`).
Future<bool> showRenewSmartCheckoutSheet({
  required BuildContext context,
  required OrderItem order,
  required String customerId,
  required String token,
}) {
  final mapped = RenewCheckoutMapper.fromOrder(order);
  return showSmartCheckoutSheet(
    context: context,
    booking: mapped.booking,
    vehicle: mapped.vehicle,
    customerId: customerId,
    token: token,
    sourceOrderId: order.orderId,
  );
}

/// Android `showCheckoutPopupWash` / `showCheckoutPopupAddon` parity.
Future<bool> showSmartCheckoutSheet({
  required BuildContext context,
  required VehicleListArgs booking,
  required VehicleItem vehicle,
  required String customerId,
  required String token,
  String? sourceOrderId,
}) async {
  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _SmartCheckoutLoaderSheet(
        booking: booking,
        vehicle: vehicle,
        customerId: customerId,
        token: token,
        sourceOrderId: sourceOrderId,
      );
    },
  );
  return added ?? false;
}

class _SmartCheckoutLoaderSheet extends StatefulWidget {
  const _SmartCheckoutLoaderSheet({
    required this.booking,
    required this.vehicle,
    required this.customerId,
    required this.token,
    this.sourceOrderId,
  });

  final VehicleListArgs booking;
  final VehicleItem vehicle;
  final String customerId;
  final String token;
  final String? sourceOrderId;

  @override
  State<_SmartCheckoutLoaderSheet> createState() =>
      _SmartCheckoutLoaderSheetState();
}

class _SmartCheckoutLoaderSheetState extends State<_SmartCheckoutLoaderSheet> {
  bool _loading = true;
  OneTimeWashCheckout? _checkout;
  int _gstPercent = 0;
  bool _isWash = false;
  bool _isExtra = false;
  bool _monthlyBlocked = false;
  bool _oneTimeBlocked = false;
  bool _blockOneTimeDueToMonthly = false;
  bool _blockMonthlyDueToOneTime = false;
  List<CheckoutPlan> _plans = <CheckoutPlan>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gstPercent =
          int.tryParse(prefs.getString('gst_percentage') ?? '0') ?? 0;

      final isWash = widget.booking.header == CheckoutConstants.serviceWash ||
          widget.booking.header == CheckoutConstants.serviceBikeWash;
      final isExtra =
          widget.booking.header.toLowerCase() == 'extra interior' ||
              widget.booking.carName.toLowerCase().startsWith('extra');

      final blockReason = await CheckoutVehicleGate.resolve(
        customerId: widget.customerId,
        vehicleId: widget.vehicle.id,
        serviceHeader: widget.booking.header,
      );

      final subscriptionMessage =
          CheckoutVehicleGate.activeSubscriptionMessage(blockReason);
      if (subscriptionMessage != null) {
        if (!mounted) return;
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(subscriptionMessage)),
        );
        return;
      }

      final checkout = await sl<CheckoutRepository>().fetchOneTimeWashCheckout(
        customerId: widget.customerId,
        packAmount: widget.booking.carPrice,
        vehicleId: widget.vehicle.id,
        serviceType: CheckoutConstants.oneTimeApiService(widget.booking.header),
      );

      List<CheckoutPlan> plans = <CheckoutPlan>[];
      if (isWash) {
        try {
          final packType = CheckoutPlanParams.packageType(
            category: widget.vehicle.category,
            carName: widget.booking.carName,
          );
          final vehicleType = CheckoutPlanParams.apiVehicleTypeFromVehicle(
            widget.vehicle,
          );
          final serviceType = CheckoutConstants.oneTimeApiService(
            widget.booking.header,
          );
          plans = await sl<CheckoutRepository>().fetchPlansList(
            vehicleType: vehicleType,
            serviceType: serviceType,
            packType: packType,
            packAmount: widget.booking.carPrice,
          );
          plans = CheckoutPlanParams.filterForBooking(
            plans,
            packageType: packType,
            serviceType: serviceType,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      if (checkout == null) {
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout unavailable for this vehicle.'),
          ),
        );
        return;
      }

      var monthlyBlocked = false;
      var oneTimeBlocked = false;
      if (isWash && widget.customerId.isNotEmpty) {
        monthlyBlocked = blockReason.blockMonthlyDueToOneTime;
        oneTimeBlocked = blockReason.blockOneTimeDueToMonthly;
      }

      setState(() {
        _loading = false;
        _checkout = checkout;
        _gstPercent = gstPercent;
        _isWash = isWash;
        _isExtra = isExtra;
        _monthlyBlocked = monthlyBlocked;
        _oneTimeBlocked = oneTimeBlocked;
        _blockOneTimeDueToMonthly = blockReason.blockOneTimeDueToMonthly;
        _blockMonthlyDueToOneTime = blockReason.blockMonthlyDueToOneTime;
        _plans = plans;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context, false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: _loading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Smart Checkout',
                    style: AppTypography.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Center(child: DottedLoader()),
                  const SizedBox(height: 32),
                ],
              )
            : _SmartCheckoutSheetBody(
                booking: widget.booking,
                vehicle: widget.vehicle,
                checkout: _checkout!,
                gstPercent: _gstPercent,
                isWash: _isWash,
                isExtra: _isExtra,
                monthlyBlocked: _monthlyBlocked,
                oneTimeBlocked: _oneTimeBlocked,
                blockOneTimeDueToMonthly: _blockOneTimeDueToMonthly,
                blockMonthlyDueToOneTime: _blockMonthlyDueToOneTime,
                plans: _plans,
                sourceOrderId: widget.sourceOrderId,
              ),
      ),
    );
  }
}

enum _SmartPurchaseMode { monthlyAutoRenew, oneTimePrepay }

class _SmartCheckoutSheetBody extends StatefulWidget {
  const _SmartCheckoutSheetBody({
    required this.booking,
    required this.vehicle,
    required this.checkout,
    required this.gstPercent,
    required this.isWash,
    required this.isExtra,
    this.monthlyBlocked = false,
    this.oneTimeBlocked = false,
    this.blockOneTimeDueToMonthly = false,
    this.blockMonthlyDueToOneTime = false,
    this.plans = const <CheckoutPlan>[],
    this.sourceOrderId,
  });

  final VehicleListArgs booking;
  final VehicleItem vehicle;
  final OneTimeWashCheckout checkout;
  final int gstPercent;
  final bool isWash;
  final bool isExtra;
  final bool monthlyBlocked;
  final bool oneTimeBlocked;
  final bool blockOneTimeDueToMonthly;
  final bool blockMonthlyDueToOneTime;
  final List<CheckoutPlan> plans;
  final String? sourceOrderId;

  @override
  State<_SmartCheckoutSheetBody> createState() =>
      _SmartCheckoutSheetBodyState();
}

class _SmartCheckoutSheetBodyState extends State<_SmartCheckoutSheetBody> {
  int _months = 1;
  String _preferDate = '';
  String _preferTime = '';
  bool _saving = false;
  late _SmartPurchaseMode _purchaseMode;

  @override
  void initState() {
    super.initState();
    if (widget.blockOneTimeDueToMonthly) {
      _purchaseMode = _SmartPurchaseMode.monthlyAutoRenew;
    } else if (widget.blockMonthlyDueToOneTime) {
      _purchaseMode = _SmartPurchaseMode.oneTimePrepay;
    } else {
      _purchaseMode = _SmartPurchaseMode.monthlyAutoRenew;
    }
  }

  bool get _isMonthlyMode =>
      widget.isWash &&
      !widget.blockMonthlyDueToOneTime &&
      _purchaseMode == _SmartPurchaseMode.monthlyAutoRenew;

  bool get _canAddToCart {
    if (widget.blockOneTimeDueToMonthly) return false;
    if (widget.blockMonthlyDueToOneTime) return !_isMonthlyMode;
    return true;
  }

  int get _baseAmount {
    if (_isMonthlyMode) {
      // Monthly autopay charges the Razorpay plan amount (e.g. 999), not the
      // catalog carPrice (e.g. 847). Cart / subscribe already use the plan.
      final planAmt = CheckoutPricing.parseMoney(_matchedPlan?.planAmount ?? '');
      if (planAmt > 0) return planAmt;
      return CheckoutPricing.parseAmount(widget.booking.carPrice);
    }
    final unit = CheckoutPricing.parseAmount(widget.checkout.totalAmount);
    return unit * _months;
  }

  int get _unitPlanAmount {
    if (_isMonthlyMode) {
      final planAmt = CheckoutPricing.parseMoney(_matchedPlan?.planAmount ?? '');
      if (planAmt > 0) return planAmt;
      return CheckoutPricing.parseMoney(widget.booking.carPrice);
    }
    return CheckoutPricing.parseMoney(widget.checkout.totalAmount);
  }

  CheckoutPlan? get _matchedPlan => CheckoutPlanFeeResolver.matchPlan(
        plans: widget.plans,
        planAmount: _isMonthlyMode
            ? widget.booking.carPrice
            : widget.checkout.totalAmount,
        monthly: _isMonthlyMode,
      );

  ({
    int total,
    double subTotal,
    double gstAmount,
    double platformFee,
    double serviceFee,
  }) get _priceBreakdown {
    final unitPlan = _unitPlanAmount;
    final inclusiveTotal = _baseAmount;
    final matched = _matchedPlan;
    return CheckoutPlanFeeResolver.breakdown(
      inclusiveTotal: inclusiveTotal,
      unitPlanAmount: unitPlan > 0 ? unitPlan : inclusiveTotal,
      gstPercent: widget.gstPercent,
      plan: matched,
    );
  }

  int get _finalAmount => _priceBreakdown.total;

  int get _mrpAmount =>
      CheckoutPricing.mrpWithOffer(_finalAmount, months: _months);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(CheckoutConstants.chooseDateTime)),
      );
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

  Future<void> _addToCart() async {
    final needsSchedule = !widget.isWash;
    if (needsSchedule && (_preferDate.isEmpty || _preferTime.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(CheckoutConstants.chooseDateTime)),
      );
      return;
    }

    if (!_canAddToCart) {
      final message = widget.blockOneTimeDueToMonthly
          ? CheckoutBlockReason.monthlyBlocksOneTimeFallback
          : 'This vehicle already has an active plan. Manage it from My Orders.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('customer_id') ?? '';
      final subsType = _isMonthlyMode ? 'Monthly' : 'OneTime';
      final validation = await sl<CheckoutRepository>().validateCheckout(
        customerId: customerId,
        vehicleId: widget.vehicle.id,
        serviceType: apiServiceTypeForValidation(widget.booking.header),
        subsType: subsType,
      );
      if (validation.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validation)),
        );
        return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to validate checkout.')),
      );
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    setState(() => _saving = true);
    final breakdown = _priceBreakdown;
    final action = CheckoutConstants.resolveAction(
      serviceType: widget.booking.header,
      isMonthlyPay: _isMonthlyMode,
      isExtraInteriorName: widget.isExtra,
    );
    final item = CartItem(
      dbType: '$action=${widget.booking.header}',
      action: action,
      serviceType: widget.booking.header,
      carImage: widget.vehicle.image,
      carMakeModel: widget.vehicle.makeModel,
      carNo: widget.vehicle.vehicleNo,
      packAmount: _finalAmount.toString(),
      carId: widget.vehicle.id,
      paidMonths: _isMonthlyMode ? '1' : '$_months',
      fineAmount: widget.checkout.fineAmount,
      subTotal: CheckoutPricing.moneyString(breakdown.subTotal),
      gstPercent: widget.gstPercent.toString(),
      gstAmount: CheckoutPricing.moneyString(breakdown.gstAmount),
      totalAmount: breakdown.total.toString(),
      platformFeeAmt: CheckoutPricing.moneyString(
        breakdown.platformFee + breakdown.gstAmount,
      ),
      serviceFeeAmt: CheckoutPricing.moneyString(breakdown.serviceFee),
      scheduleDate: _preferDate.isNotEmpty ? _preferDate : widget.vehicle.preferredSchedule,
      scheduleTime: _preferTime.isNotEmpty ? _preferTime : widget.vehicle.preferredTime,
      carName: widget.booking.carName,
      carCategory: widget.vehicle.category,
      header: widget.booking.header,
      sourceOrderId: widget.sourceOrderId ?? '',
    );

    final ok = await CartLocalStorage().upsert(item);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added Failed.')),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final packageLabel = widget.isWash
        ? (widget.booking.header == CheckoutConstants.serviceBikeWash
            ? 'Bike Wash'
            : 'Car Wash')
        : widget.booking.header;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Smart Checkout',
                    style: AppTypography.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              widget.vehicle.makeModel,
              style: AppTypography.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            Text(
              widget.vehicle.vehicleNo,
              style: AppTypography.dmSans(
                fontSize: 14,
                color: AppColors.grey600,
              ),
            ),
            const DottedDivider(margin: EdgeInsets.symmetric(vertical: 12)),
            _row('Service', widget.booking.header),
            _row('Package', packageLabel),
            if (widget.isWash) ...<Widget>[
              const SizedBox(height: 8),
              if (widget.blockOneTimeDueToMonthly)
                Text(
                  'One-time prepay is unavailable while a monthly subscription is active for this vehicle.',
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.grey600,
                  ),
                )
              else if (widget.blockMonthlyDueToOneTime)
                Text(
                  'Monthly subscription is unavailable while a one-time plan is active for this vehicle.',
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.grey600,
                  ),
                )
              else if (!widget.blockMonthlyDueToOneTime && !widget.blockOneTimeDueToMonthly)
                SegmentedButton<_SmartPurchaseMode>(
                  segments: const <ButtonSegment<_SmartPurchaseMode>>[
                    ButtonSegment<_SmartPurchaseMode>(
                      value: _SmartPurchaseMode.monthlyAutoRenew,
                      label: Text('Monthly'),
                      icon: Icon(Icons.autorenew, size: 18),
                    ),
                    ButtonSegment<_SmartPurchaseMode>(
                      value: _SmartPurchaseMode.oneTimePrepay,
                      label: Text('One-time'),
                    ),
                  ],
                  selected: <_SmartPurchaseMode>{_purchaseMode},
                  onSelectionChanged: (selected) {
                    if (selected.isEmpty) return;
                    setState(() => _purchaseMode = selected.first);
                  },
                ),
              const SizedBox(height: 8),
              if (_isMonthlyMode && !widget.blockMonthlyDueToOneTime)
                const Text(
                  'Auto-renews each month (same as Subscribe → Monthly).',
                  style: TextStyle(fontSize: 12, height: 1.35),
                )
              else if (widget.isWash && !widget.blockOneTimeDueToMonthly && !_isMonthlyMode)
                DropdownButtonFormField<int>(
                  initialValue: _months,
                  decoration: const InputDecoration(
                    labelText: 'Prepaid months (one-time, no auto-renew)',
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
                    if (value != null) setState(() => _months = value);
                  },
                ),
            ] else ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _pickDate,
                child: Text(
                  _preferDate.isEmpty
                      ? 'Select preferred date'
                      : 'Date: $_preferDate',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _pickTime,
                child: Text(
                  _preferTime.isEmpty
                      ? 'Select preferred time'
                      : 'Time: $_preferTime',
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (widget.gstPercent > 0) ...<Widget>[
              _row('Platform fee', CheckoutPricing.rupee(_priceBreakdown.platformFee)),
              _row(
                'Service provider charges',
                CheckoutPricing.rupee(_priceBreakdown.serviceFee),
              ),
              _row(
                'GST (${widget.gstPercent}% on platform fee)',
                CheckoutPricing.rupee(_priceBreakdown.gstAmount),
              ),
              _row('Offer price', CheckoutPricing.rupee(_finalAmount)),
            ],
            _row(
              'MRP',
              CheckoutPricing.rupee(_mrpAmount),
              strike: true,
            ),
            _row('Total', CheckoutPricing.rupee(_finalAmount), bold: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving || !_canAddToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const DottedLoader(
                        size: DottedLoaderSize.small,
                        color: AppColors.white,
                      )
                    : Text(
                        'Add to Cart',
                        style: AppTypography.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool strike = false}) {
    return BillLineRow(
      label: label,
      amount: value,
      labelStyle: AppTypography.dmSans(
        fontSize: 14,
        color: AppColors.grey600,
      ),
      amountStyle: AppTypography.dmSans(
        fontSize: 14,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: bold ? AppColors.primary : AppColors.grey800,
        fontStyle: strike ? FontStyle.normal : FontStyle.normal,
      ).copyWith(
        decoration: strike ? TextDecoration.lineThrough : null,
        decorationColor: AppColors.grey500,
      ),
    );
  }
}
