import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_block_reason.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_vehicle_gate.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_service_type_mapper.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';
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
  );
}

/// Android `showCheckoutPopupWash` / `showCheckoutPopupAddon` parity.
Future<bool> showSmartCheckoutSheet({
  required BuildContext context,
  required VehicleListArgs booking,
  required VehicleItem vehicle,
  required String customerId,
  required String token,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final gstPercent =
      int.tryParse(prefs.getString('gst_percentage') ?? '0') ?? 0;

  final isWash = booking.header == CheckoutConstants.serviceWash ||
      booking.header == CheckoutConstants.serviceBikeWash;
  final isExtra = booking.header.toLowerCase() == 'extra interior' ||
      booking.carName.toLowerCase().startsWith('extra');

  final blockReason = await CheckoutVehicleGate.resolve(
    customerId: customerId,
    vehicleId: vehicle.id,
    serviceHeader: booking.header,
  );

  final subscriptionMessage =
      CheckoutVehicleGate.activeSubscriptionMessage(blockReason);
  if (subscriptionMessage != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(subscriptionMessage)),
      );
    }
    return false;
  }

  OneTimeWashCheckout? checkout;
  try {
    checkout = await sl<CheckoutRepository>().fetchOneTimeWashCheckout(
      customerId: customerId,
      packAmount: booking.carPrice,
      vehicleId: vehicle.id,
      serviceType: CheckoutConstants.oneTimeApiService(booking.header),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
    return false;
  }

  if (!context.mounted) return false;
  if (checkout == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checkout unavailable for this vehicle.')),
    );
    return false;
  }

  var monthlyBlocked = false;
  var oneTimeBlocked = false;
  if (isWash && customerId.isNotEmpty) {
    monthlyBlocked = blockReason.blockMonthlyDueToOneTime;
    oneTimeBlocked = blockReason.blockOneTimeDueToMonthly;
  }

  if (!context.mounted) return false;

  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _SmartCheckoutSheetBody(
        booking: booking,
        vehicle: vehicle,
        checkout: checkout!,
        gstPercent: gstPercent,
        isWash: isWash,
        isExtra: isExtra,
        monthlyBlocked: monthlyBlocked,
        oneTimeBlocked: oneTimeBlocked,
        blockOneTimeDueToMonthly: blockReason.blockOneTimeDueToMonthly,
        blockMonthlyDueToOneTime: blockReason.blockMonthlyDueToOneTime,
      );
    },
  );
  return added ?? false;
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
      return CheckoutPricing.parseAmount(widget.booking.carPrice);
    }
    final unit = CheckoutPricing.parseAmount(widget.checkout.totalAmount);
    return unit * _months;
  }

  int get _finalAmount =>
      CheckoutPricing.finalAmount(_baseAmount, widget.gstPercent);

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
    final tax = CheckoutPricing.taxAmount(_baseAmount, widget.gstPercent);
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
      packAmount: _isMonthlyMode
          ? widget.booking.carPrice
          : widget.checkout.totalAmount,
      carId: widget.vehicle.id,
      paidMonths: _isMonthlyMode ? '1' : '$_months',
      fineAmount: widget.checkout.fineAmount,
      subTotal: _baseAmount.toString(),
      gstPercent: widget.gstPercent.toString(),
      gstAmount: tax.toString(),
      totalAmount: _finalAmount.toString(),
      scheduleDate: _preferDate.isNotEmpty ? _preferDate : widget.vehicle.preferredSchedule,
      scheduleTime: _preferTime.isNotEmpty ? _preferTime : widget.vehicle.preferredTime,
      carName: widget.booking.carName,
      carCategory: widget.vehicle.category,
      header: widget.booking.header,
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
                const Expanded(
                  child: Text(
                    'Smart Checkout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.vehicle.vehicleNo,
              style: const TextStyle(color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            _row('Service', widget.booking.header),
            _row('Package', packageLabel),
            if (widget.isWash) ...<Widget>[
              const SizedBox(height: 8),
              if (widget.blockOneTimeDueToMonthly)
                const Text(
                  'One-time prepay is unavailable while a monthly subscription is active for this vehicle.',
                  style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF5D4037)),
                )
              else if (widget.blockMonthlyDueToOneTime)
                const Text(
                  'Monthly subscription is unavailable while a one-time plan is active for this vehicle.',
                  style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF5D4037)),
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
            if (widget.gstPercent > 0)
              _row('Offer price', CheckoutPricing.rupee(_finalAmount)),
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
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Color(0xFF666666))),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              decoration: strike ? TextDecoration.lineThrough : null,
              color: bold ? AppColors.black : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
