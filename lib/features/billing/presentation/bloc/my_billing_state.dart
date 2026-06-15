part of 'my_billing_bloc.dart';

sealed class MyBillingState {
  const MyBillingState();
}

class MyBillingInitial extends MyBillingState {
  const MyBillingInitial();
}

class MyBillingLoading extends MyBillingState {
  const MyBillingLoading();
}

class MyBillingLoaded extends MyBillingState {
  const MyBillingLoaded(this.billings);

  final List<BillingItem> billings;
}

class MyBillingFailure extends MyBillingState {
  const MyBillingFailure(this.message);

  final String message;
}
