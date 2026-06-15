part of 'my_billing_bloc.dart';

sealed class MyBillingEvent {
  const MyBillingEvent();
}

class MyBillingRequested extends MyBillingEvent {
  const MyBillingRequested({
    required this.token,
    required this.customerId,
  });

  final String token;
  final String customerId;
}
