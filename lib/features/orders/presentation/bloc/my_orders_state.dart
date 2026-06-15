part of 'my_orders_bloc.dart';

sealed class MyOrdersState {
  const MyOrdersState();
}

class MyOrdersInitial extends MyOrdersState {
  const MyOrdersInitial();
}

class MyOrdersLoading extends MyOrdersState {
  const MyOrdersLoading();
}

class MyOrdersLoaded extends MyOrdersState {
  const MyOrdersLoaded(this.orders);

  final List<OrderItem> orders;
}

class MyOrdersFailure extends MyOrdersState {
  const MyOrdersFailure(this.message);

  final String message;
}
