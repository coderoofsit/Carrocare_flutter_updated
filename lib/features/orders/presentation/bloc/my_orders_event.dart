part of 'my_orders_bloc.dart';

sealed class MyOrdersEvent {
  const MyOrdersEvent();
}

class MyOrdersStarted extends MyOrdersEvent {
  const MyOrdersStarted();
}

class MyOrdersRequested extends MyOrdersEvent {
  const MyOrdersRequested({
    required this.token,
    required this.customerId,
  });

  final String token;
  final String customerId;
}
