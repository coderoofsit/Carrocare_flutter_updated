import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/checkout/core/autopay_checkout_helper.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebArgs {
  const PaymentWebArgs({
    required this.packageType,
    required this.vehicleType,
    required this.serviceType,
    required this.vehicleId,
    required this.customerId,
    required this.amount,
    this.enableAutopay = true,
  });

  final String packageType;
  final String vehicleType;
  final String serviceType;
  final String vehicleId;
  final String customerId;
  final String amount;
  final bool enableAutopay;
}

class PaymentWebPage extends StatefulWidget {
  const PaymentWebPage({super.key, required this.args});

  final PaymentWebArgs args;

  @override
  State<PaymentWebPage> createState() => _PaymentWebPageState();
}

class _PaymentWebPageState extends State<PaymentWebPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final packageType =
        CheckoutConstants.normalizePackageType(widget.args.packageType);
    final autopay =
        AutopayCheckoutHelper.autopayQueryValue(widget.args.enableAutopay);
    final url =
        '${AppUrls.webviewCheckout}?p_type=$packageType'
        '&v_type=${Uri.encodeComponent(widget.args.vehicleType)}'
        '&su_type=Monthly'
        '&se_type=${Uri.encodeComponent(widget.args.serviceType)}'
        '&v_id=${widget.args.vehicleId}'
        '&customer_id=${widget.args.customerId}'
        '&autopay=$autopay';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (url) {
            setState(() => _loading = false);
            _handleUrl(url);
          },
          onNavigationRequest: (request) {
            _handleUrl(request.url);
            if (AppUrls.isAppBackendUrl(request.url)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _handleUrl(String url) {
    if (!url.contains('emandate_authentication.php')) return;
    final uri = Uri.parse(url);
    final razorpayCustomerId = uri.queryParameters['razorpay_customer_id'] ?? '';
    final orderId = uri.queryParameters['order_id'] ?? '';
    final paymentType = uri.queryParameters['payment_type'] ?? '';
    if (orderId.isEmpty) return;

    context.pushReplacement(
      '/checkout-finalize',
      extra: CheckoutFinalizeArgs(
        packageType: widget.args.packageType,
        vehicleType: widget.args.vehicleType,
        serviceType: widget.args.serviceType,
        vehicleId: widget.args.vehicleId,
        customerId: widget.args.customerId,
        amount: widget.args.amount,
        razorpayCustomerId: razorpayCustomerId,
        razorpayOrderId: orderId,
        paymentType: paymentType,
        enableAutopay: widget.args.enableAutopay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Payment',
      onBack: () => context.pop(),
      body: Stack(
        children: <Widget>[
          WebViewWidget(controller: _controller),
          if (_loading) const CarroCareLoadingOverlay(),
        ],
      ),
    );
  }
}

class CheckoutFinalizeArgs {
  const CheckoutFinalizeArgs({
    required this.packageType,
    required this.vehicleType,
    required this.serviceType,
    required this.vehicleId,
    required this.customerId,
    required this.amount,
    required this.razorpayCustomerId,
    required this.razorpayOrderId,
    required this.paymentType,
    this.enableAutopay = true,
  });

  final String packageType;
  final String vehicleType;
  final String serviceType;
  final String vehicleId;
  final String customerId;
  final String amount;
  final String razorpayCustomerId;
  final String razorpayOrderId;
  final String paymentType;
  final bool enableAutopay;
}
