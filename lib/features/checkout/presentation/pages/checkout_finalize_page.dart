import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/checkout/core/autopay_checkout_helper.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_gst_config.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:carrocare_flutter/features/checkout/presentation/pages/payment_web_page.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/razorpay_checkout_service.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/razorpay_price_summary_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutFinalizePage extends StatefulWidget {
  const CheckoutFinalizePage({super.key, required this.args});

  final CheckoutFinalizeArgs args;

  @override
  State<CheckoutFinalizePage> createState() => _CheckoutFinalizePageState();
}

class _CheckoutFinalizePageState extends State<CheckoutFinalizePage> {
  final RazorpayCheckoutService _razorpay = RazorpayCheckoutService();
  WebViewController? _webController;
  bool _showWeb = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startMonthlyRazorpay();
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  Future<void> _startMonthlyRazorpay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      final mobile =
          prefs.getString('mobile') ?? prefs.getString('usermobile') ?? '';
      final amountInr = (double.tryParse(widget.args.amount) ?? 0).round();
      final gstPercent = CheckoutGstConfig.resolvePercent(prefs);
      final priceSummary = RazorpayPriceSummary.fromInclusive(
        serviceLabel: widget.args.serviceType,
        inclusiveTotal: amountInr,
        gstPercent: gstPercent,
      );
      if (!mounted) return;
      final confirmed = await showRazorpayPriceSummarySheet(
        context: context,
        summary: priceSummary,
        onConfirmPay: () async {
          final keys = await sl<CheckoutRepository>().getRazorpayKeys();
          if (!mounted) return;

          _razorpay.open(
            keyId: keys.keyId,
            amountPaise: amountInr * 100,
            description: widget.args.serviceType,
            email: email,
            contact: mobile,
            orderId: widget.args.razorpayOrderId,
            customerId: widget.args.razorpayCustomerId,
            enableRecurring: widget.args.enableAutopay,
            priceSummary: priceSummary,
            onSuccess: _loadFinalizeWeb,
            onError: (message) {
              if (!mounted) return;
              setState(() => _error = message);
            },
          );
        },
      );
      if (!confirmed) {
        if (!mounted) return;
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _loadFinalizeWeb(String paymentId) {
    final packageType = widget.args.packageType;
    final autopay =
        AutopayCheckoutHelper.autopayQueryValue(widget.args.enableAutopay);
    final url =
        '${AppUrls.webviewCheckout}?p_type=$packageType'
        '&v_type=${Uri.encodeComponent(widget.args.vehicleType)}'
        '&su_type=Monthly'
        '&se_type=${Uri.encodeComponent(widget.args.serviceType)}'
        '&v_id=${widget.args.vehicleId}'
        '&customer_id=${widget.args.customerId}'
        '&razorpay_customer_id=${widget.args.razorpayCustomerId}'
        '&razorpay_payment_id=$paymentId'
        '&razorpay_order_id=${widget.args.razorpayOrderId}'
        '&payment_type=${Uri.encodeComponent(widget.args.paymentType)}'
        '&autopay=$autopay';

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (url.contains('success') ||
                url.contains('Congrats') ||
                url.contains('payment_success')) {
              context.go('/payment-success');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    setState(() => _showWeb = true);
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Checkout',
      onBack: () => context.pop(),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : _showWeb && _webController != null
              ? WebViewWidget(controller: _webController!)
              : const CarroCareLoadingOverlay(),
    );
  }
}
