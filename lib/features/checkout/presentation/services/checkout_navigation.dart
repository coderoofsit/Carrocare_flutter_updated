import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// Navigate after Razorpay returns from the native activity.
void goToPaymentSuccess(GoRouter router) {
  void navigate() {
    if (router.state.uri.path == '/payment-success') return;
    router.go('/payment-success');
  }

  SchedulerBinding.instance.addPostFrameCallback((_) => navigate());
  Future<void>.delayed(const Duration(milliseconds: 150), navigate);
}

void goToMyOrders(GoRouter router) {
  router.go('/my-orders');
}
