import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';

extension OrderItemCategory on OrderItem {
  /// Recurring monthly / autopay orders from [payment_type].
  bool get isSubscription => paymentType.toLowerCase() == 'monthly';

  /// Prepaid and other non-subscription orders.
  bool get isOneTimeOrder => !isSubscription;
}

List<OrderItem> subscriptionOrders(List<OrderItem> orders) =>
    orders.where((o) => o.isSubscription).toList();

List<OrderItem> oneTimeOrders(List<OrderItem> orders) =>
    orders.where((o) => o.isOneTimeOrder).toList();

/// Subscription chips — match raw [OrderItem.status] from the API.
enum SubscriptionStatusFilter {
  all,
  active,
  overDue,
  paused,
  completed,
  cancelled,
}

/// One-time chips — match customer-facing [OrderItem.displayStatus].
enum OneTimeStatusFilter {
  all,
  paid,
  notCompleted,
  completed,
  cancelRequested,
  cancelled,
}

bool matchesSubscriptionStatusFilter(
  OrderItem order,
  SubscriptionStatusFilter filter,
) {
  final s = order.status.trim().toLowerCase();
  switch (filter) {
    case SubscriptionStatusFilter.all:
      return true;
    case SubscriptionStatusFilter.active:
      return s == 'active' || s == 'created' || s == 'authenticated';
    case SubscriptionStatusFilter.overDue:
      return s == 'over due';
    case SubscriptionStatusFilter.paused:
      return s == 'paused';
    case SubscriptionStatusFilter.completed:
      return s == 'completed';
    case SubscriptionStatusFilter.cancelled:
      return s == 'cancelled' || s == 'closed' || s == 'refunded';
  }
}

bool matchesOneTimeStatusFilter(
  OrderItem order,
  OneTimeStatusFilter filter,
) {
  final display = order.displayStatus.trim().toLowerCase();
  final raw = order.status.trim().toLowerCase();
  switch (filter) {
    case OneTimeStatusFilter.all:
      return true;
    case OneTimeStatusFilter.paid:
      return display == 'paid';
    case OneTimeStatusFilter.notCompleted:
      return display == 'not completed' || raw == 'not yet done!';
    case OneTimeStatusFilter.completed:
      return display == 'completed';
    case OneTimeStatusFilter.cancelRequested:
      return display == 'cancel requested';
    case OneTimeStatusFilter.cancelled:
      return display == 'cancelled';
  }
}

List<OrderItem> filterSubscriptionOrders(
  List<OrderItem> orders,
  SubscriptionStatusFilter filter,
) {
  if (filter == SubscriptionStatusFilter.all) return orders;
  return orders
      .where((o) => matchesSubscriptionStatusFilter(o, filter))
      .toList();
}

List<OrderItem> filterOneTimeOrders(
  List<OrderItem> orders,
  OneTimeStatusFilter filter,
) {
  if (filter == OneTimeStatusFilter.all) return orders;
  return orders.where((o) => matchesOneTimeStatusFilter(o, filter)).toList();
}

String emptyMessageForSubscriptionFilter(SubscriptionStatusFilter filter) {
  switch (filter) {
    case SubscriptionStatusFilter.all:
      return '';
    case SubscriptionStatusFilter.active:
      return 'No active subscriptions';
    case SubscriptionStatusFilter.overDue:
      return 'No overdue subscriptions';
    case SubscriptionStatusFilter.paused:
      return 'No paused subscriptions';
    case SubscriptionStatusFilter.completed:
      return 'No completed subscriptions';
    case SubscriptionStatusFilter.cancelled:
      return 'No cancelled subscriptions';
  }
}

String emptyMessageForOneTimeFilter(OneTimeStatusFilter filter) {
  switch (filter) {
    case OneTimeStatusFilter.all:
      return '';
    case OneTimeStatusFilter.paid:
      return 'No paid orders';
    case OneTimeStatusFilter.notCompleted:
      return 'No not-completed orders';
    case OneTimeStatusFilter.completed:
      return 'No completed orders';
    case OneTimeStatusFilter.cancelRequested:
      return 'No cancel-requested orders';
    case OneTimeStatusFilter.cancelled:
      return 'No cancelled orders';
  }
}
