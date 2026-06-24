import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// Navigate after Razorpay returns from the native activity.
void goToPaymentSuccess(GoRouter router) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    router.go('/my-orders');
  });
}

void goToMyOrders(GoRouter router) {
  router.go('/my-orders');
}
