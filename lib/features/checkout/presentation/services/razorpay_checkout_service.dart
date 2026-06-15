import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayCheckoutService {
  Razorpay? _razorpay;
  void Function(String paymentId)? _onSuccess;
  void Function(String message)? _onError;

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  void open({
    required String keyId,
    required int amountPaise,
    required String description,
    required String email,
    required String contact,
    String? orderId,
    String? customerId,
    bool enableRecurring = false,
    RazorpayPriceSummary? priceSummary,
    required void Function(String paymentId) onSuccess,
    required void Function(String message) onError,
  }) {
    dispose();
    _onSuccess = onSuccess;
    _onError = onError;
    _razorpay = Razorpay();
    _razorpay!
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final options = <String, dynamic>{
      'key': keyId,
      'amount': amountPaise,
      'name': 'Carro Care',
      'description': priceSummary?.description ?? description,
      'currency': 'INR',
      'prefill': <String, String>{
        'email': email,
        'contact': contact,
      },
    };
    if (priceSummary != null) {
      options['notes'] = priceSummary.notes;
    }
    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }
    if (customerId != null && customerId.isNotEmpty) {
      options['customer_id'] = customerId;
    }
    if (enableRecurring && orderId != null && orderId.isNotEmpty) {
      options['recurring'] = '1';
    }

    try {
      _razorpay!.open(options);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Razorpay subscription checkout (monthly plans).
  Future<void> openSubscription({
    required String keyId,
    required String subscriptionId,
    required String description,
    required String email,
    required String contact,
    RazorpayPriceSummary? priceSummary,
    required void Function(String paymentId) onSuccess,
    required void Function(String message) onError,
  }) async {
    dispose();
    _onSuccess = onSuccess;
    _onError = onError;
    _razorpay = Razorpay();
    _razorpay!
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final options = <String, dynamic>{
      'key': keyId,
      'subscription_id': subscriptionId,
      'name': 'Carro Care',
      'description': priceSummary?.description ?? description,
      'currency': 'INR',
      'prefill': <String, String>{
        'email': email,
        'contact': contact,
      },
    };
    if (priceSummary != null) {
      options['notes'] = priceSummary.notes;
    }

    try {
      _razorpay!.open(options);
    } catch (e) {
      onError(e.toString());
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId ?? '';
    if (paymentId.isEmpty) {
      _onError?.call('Payment id missing');
      return;
    }
    _onSuccess?.call(paymentId);
  }

  void _handleError(PaymentFailureResponse response) {
    _onError?.call(response.message ?? 'Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onError?.call('External wallet: ${response.walletName}');
  }
}
