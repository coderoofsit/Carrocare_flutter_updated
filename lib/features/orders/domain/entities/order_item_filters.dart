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
