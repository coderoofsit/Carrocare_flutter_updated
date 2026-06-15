import 'package:carrocare_flutter/features/internal_wash/domain/entities/internal_wash_form.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/wash_calendar_models.dart';

abstract class OrdersRepository {
  Future<List<OrderItem>> getOrders({
    required String token,
    required String customerId,
  });

  Future<List<OrderItem>> getInternalOrders({
    required String token,
    required String customerId,
  });

  Future<InternalWashForm> getInternalWashForm({
    required String token,
    required String customerId,
    required String vehicleId,
    required String orderId,
  });

  Future<WashCalendarData> getWashCalendar({
    required String token,
    required String customerId,
    required String vehicleId,
    required String orderId,
  });

  Future<ExtraInteriorCalendarData> getExtraInteriorCalendar({
    required String token,
    required String customerId,
    required String vehicleId,
  });

  Future<String> cancelSubscription({
    required String token,
    required String vehicleId,
    required String orderId,
  });

  Future<String> cancelCodOrder({
    required String orderId,
    required String customerId,
    required String reason,
  });

  Future<String> scheduleInternalCleanNew({
    required String token,
    required String customerId,
    required String vehicleId,
    required String orderId,
    required String scheduleDate1,
    required String scheduleTime1,
    required String comment1,
    required String scheduleDate2,
    required String scheduleTime2,
    required String comment2,
    required String id,
  });

  Future<String> scheduleInternalClean({
    required String token,
    required String customerId,
    required String vehicleId,
    required String orderId,
    required String scheduleDate,
    required String scheduleTime,
    required String comment,
    required String dateType,
    required String id,
  });
}
