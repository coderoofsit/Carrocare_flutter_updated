import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/checkout/core/autopay_checkout_helper.dart';
import 'package:carrocare_flutter/features/checkout/core/cart_display_helper.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_block_reason.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_gst_config.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_plan_params.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_service_type_mapper.dart';
import 'package:carrocare_flutter/features/checkout/core/monthly_subscription_checkout.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/autopay_consent_panel.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/razorpay_checkout_service.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/cart_checkout_footer.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/cart_item_card.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/razorpay_price_summary_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Matches Android [CartActivity] / `activity_cart.xml`.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartLocalStorage _storage = CartLocalStorage();
  final RazorpayCheckoutService _razorpay = RazorpayCheckoutService();

  List<CartItem> _items = <CartItem>[];
  bool _loading = true;
  bool _checkingOut = false;
  bool _enableAutopay = true;
  bool _acceptedTerms = false;

  String _token = '';
  String _customerId = '';
  String _email = '';
  String _mobile = '';

  int get _cartTotal => _items.fold<int>(
        0,
        (sum, item) => sum + CartDisplayHelper.parseAmount(item.totalAmount),
      );

  RazorpayPriceSummary _cartPriceSummary() {
    final subTotal = _items.fold<int>(
      0,
      (sum, item) => sum + CheckoutPricing.parseAmount(item.subTotal),
    );
    final gstAmount = _items.fold<int>(
      0,
      (sum, item) => sum + CheckoutPricing.parseAmount(item.gstAmount),
    );
    final rawGst = _items.isEmpty
        ? 0
        : int.tryParse(_items.first.gstPercent) ?? 0;
    final gstPercent =
        rawGst > 0 ? rawGst : CheckoutGstConfig.defaultGstPercent;
    final label = _items.length == 1
        ? CartDisplayHelper.serviceLabel(_items.first)
        : 'Cart (${_items.length} items)';
    return RazorpayPriceSummary(
      serviceLabel: label,
      total: _cartTotal,
      subTotal: subTotal,
      gstAmount: gstAmount,
      gstPercent: gstPercent,
    );
  }

  bool get _showAutopayPanel =>
      AutopayCheckoutHelper.cartHasAutopayEligibleItems(_items) &&
      !_isSingleMonthlyCart;

  bool get _showMonthlyTermsPanel => _isSingleMonthlyCart;

  bool get _isSingleMonthlyCart =>
      _items.length == 1 &&
      _items.first.action == CheckoutConstants.actionMonthly;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _customerId = prefs.getString('customer_id') ?? '';
    _email = prefs.getString('email') ?? '';
    _mobile = prefs.getString('mobile') ?? prefs.getString('usermobile') ?? '';
    _items = await _storage.getItems();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _confirmRemove(CartItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove'),
        content: Text('Are you remove to ( ${item.carMakeModel} )?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _storage.removeByVehicleId(item.carId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed')),
    );
    await _load();
  }

  Future<void> _checkout() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose at least one product')),
      );
      return;
    }

    if ((_showAutopayPanel || _showMonthlyTermsPanel) && !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    if (_items.any(
      (item) => item.action == CheckoutConstants.actionMonthly,
    )) {
      if (!_isSingleMonthlyCart) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Checkout monthly subscriptions one vehicle at a time.',
            ),
          ),
        );
        return;
      }
      await _checkoutMonthlySubscription(_items.first);
      return;
    }

    for (final CartItem item in _items) {
      if (item.scheduleDate.isEmpty &&
          (item.serviceType == CheckoutConstants.serviceAddon ||
              item.serviceType == CheckoutConstants.serviceExtraInterior ||
              item.serviceType == CheckoutConstants.serviceDisinfection)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(CheckoutConstants.chooseDateTime)),
        );
        return;
      }
    }

    final repo = sl<CheckoutRepository>();
    for (final CartItem item in _items) {
      final monthlyValidation = await repo.validateCheckout(
        customerId: _customerId,
        vehicleId: item.carId,
        serviceType: apiServiceTypeForValidation(item.serviceType),
        subsType: 'Monthly',
      );
      final oneTimeValidation = await repo.validateCheckout(
        customerId: _customerId,
        vehicleId: item.carId,
        serviceType: apiServiceTypeForValidation(item.serviceType),
        subsType: 'OneTime',
      );
      final blockReason = CheckoutBlockReason.fromValidations(
        monthlyValidation: monthlyValidation,
        oneTimeValidation: oneTimeValidation,
      );
      if (blockReason.blockOneTimeDueToMonthly) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              blockReason.oneTimeMessage.isNotEmpty
                  ? blockReason.oneTimeMessage
                  : CheckoutBlockReason.monthlyBlocksOneTimeFallback,
            ),
          ),
        );
        return;
      }
    }

    setState(() => _checkingOut = true);
    try {
      final keys = await repo.getRazorpayKeys();
      final total = _cartTotal;
      final orderId = await repo.createCartRazorpayOrderId(cartTotal: total);

      await repo.createTempOrdersForCart(
        items: _items,
        razorpayOrderId: orderId,
        customerId: _customerId,
        token: _token,
        cartTotal: total.toString(),
      );

      if (!mounted) return;

      final priceSummary = _cartPriceSummary();
      if (!await showRazorpayPriceSummarySheet(
        context: context,
        summary: priceSummary,
      )) {
        return;
      }
      if (!mounted) return;

      final useRecurring =
          _enableAutopay && AutopayCheckoutHelper.cartItemSupportsAutopay(
            _items.first,
          );

      _razorpay.open(
        keyId: keys.keyId,
        amountPaise: total * 100,
        description: orderId,
        email: _email,
        contact: _mobile,
        orderId: orderId,
        enableRecurring: useRecurring && _items.length == 1,
        priceSummary: priceSummary,
        onSuccess: (_) async {
          await _storage.clear();
          if (!mounted) return;
          context.go('/payment-success');
        },
        onError: (message) async {
          await _storage.clear();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          context.go('/home');
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Timeout')
                ? 'Timeout.Try after sometime'
                : e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<void> _checkoutMonthlySubscription(CartItem item) async {
    setState(() => _checkingOut = true);
    try {
      final repo = sl<CheckoutRepository>();
      final validation = await repo.validateCheckout(
        customerId: _customerId,
        vehicleId: item.carId,
        serviceType: apiServiceTypeForValidation(item.serviceType),
        subsType: 'Monthly',
      );
      if (validation.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validation)),
        );
        return;
      }

      final packType = CheckoutPlanParams.packageType(
        category: item.carCategory,
        carName: item.carName,
      );
      final vehicleType = CheckoutPlanParams.apiVehicleType(
        vehicleType: item.carCategory,
        category: item.carCategory,
        carName: item.carName,
      );
      final serviceType = apiServiceTypeForSubscription(item.serviceType);
      final gstPercent = int.tryParse(item.gstPercent) ?? 0;
      final inclusiveTotal = CheckoutPricing.parseAmount(item.totalAmount);
      final priceSummary = RazorpayPriceSummary.fromInclusive(
        serviceLabel: apiServiceTypeForSubscription(item.serviceType),
        inclusiveTotal: inclusiveTotal,
        gstPercent: gstPercent,
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
        vehicleId: item.carId,
        packType: packType,
        vehicleType: vehicleType,
        serviceType: serviceType,
        packAmount: item.packAmount,
        gstPercent: gstPercent,
        priceSummary: priceSummary,
        onError: (message) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
        onSuccess: () async {
          await _storage.clear();
          if (!mounted) return;
          context.go('/payment-success');
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasItems = _items.isNotEmpty;

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
                      'CART',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
                    : !hasItems
                        ? _EmptyCart()
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return CartItemCard(
                                item: item,
                                onDelete: () => _confirmRemove(item),
                              );
                            },
                          ),
              ),
            ),
            if (hasItems)
              CartCheckoutFooter(
                itemCount: _items.length,
                total: _cartTotal,
                checkingOut: _checkingOut,
                onCheckout: _checkout,
                consentSection: _showAutopayPanel || _showMonthlyTermsPanel
                    ? AutopayConsentPanel(
                        enableAutopay: _enableAutopay,
                        showAutopayToggle: !_showMonthlyTermsPanel,
                        acceptedTerms: _acceptedTerms,
                        onAutopayChanged: (value) =>
                            setState(() => _enableAutopay = value),
                        onTermsChanged: (value) =>
                            setState(() => _acceptedTerms = value),
                        renewalAmount:
                            CheckoutPricing.rupee(_cartTotal),
                      )
                    : null,
              ),
            if (_checkingOut)
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            'assets/images/tyre.png',
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'No vehicles added yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
