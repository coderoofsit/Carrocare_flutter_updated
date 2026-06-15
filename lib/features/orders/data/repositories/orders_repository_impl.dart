import 'package:carrocare_flutter/features/internal_wash/domain/entities/internal_wash_form.dart';
import 'package:carrocare_flutter/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/wash_calendar_models.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';
import 'package:intl/intl.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._remoteDataSource);

  final OrdersRemoteDataSource _remoteDataSource;

  @override
  Future<List<OrderItem>> getOrders({
    required String token,
    required String customerId,
  }) async {
    if (token.isEmpty || customerId.isEmpty) {
      throw Exception('Session missing. Please login again.');
    }
    final data = await _remoteDataSource.getOrders(
      token: token,
      customerId: customerId,
    );
    final code = (data['code'] ?? '').toString();
    if (code == '203') {
      throw Exception('Session expired');
    }
    if (code == '201') {
      return <OrderItem>[];
    }
    if (code != '200') {
      throw Exception((data['message'] ?? 'Failed to load orders').toString());
    }
    final orders = data['orders'];
    if (orders is! List) return <OrderItem>[];

    final parsed = <OrderItem>[];
    for (final raw in orders) {
      if (raw is! Map) continue;
      try {
        parsed.add(
          OrderItem.fromJson(
            raw.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return parsed;
  }

  @override
  Future<List<OrderItem>> getInternalOrders({
    required String token,
    required String customerId,
  }) async {
    if (token.isEmpty || customerId.isEmpty) {
      throw Exception('Session missing. Please login again.');
    }
    final data = await _remoteDataSource.getInternalOrders(
      token: token,
      customerId: customerId,
    );
    final code = (data['code'] ?? '').toString();
    if (code == '203') {
      throw Exception('Session expired');
    }
    if (code == '201') {
      return <OrderItem>[];
    }
    if (code != '200') {
      throw Exception(
        (data['message'] ?? 'Failed to load internal orders').toString(),
      );
    }
    final orders = data['orders'];
    if (orders is! List) return <OrderItem>[];

    final parsed = <OrderItem>[];
    for (final raw in orders) {
      if (raw is! Map) continue;
      try {
        parsed.add(
          OrderItem.fromJson(
            raw.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return parsed;
  }

  @override
  Future<InternalWashForm> getInternalWashForm({
    required String token,
    required String customerId,
    required String vehicleId,
    required String orderId,
  }) async {
    final data = await _remoteDataSource.getWashDetails(
      token: token,
      customerId: customerId,
      vehicleId: vehicleId,
      orderId: orderId,
    );
    _throwOnSession(data);
    final code = (data['code'] ?? '').toString();
    if (code == '201') {
      throw Exception((data['message'] ?? 'No internal wash data').toString());
    }
    if (code != '200') {
      throw Exception(
        (data['message'] ?? 'Failed to load internal wash').toString(),
      );
    }

    final internalList = data['internal_details'];
    if (internalList is! List || internalList.isEmpty) {
      throw Exception('No internal wash schedule found');
    }

    final detailsMaps = <Map<String, dynamic>>[];
    for (final raw in internalList) {
      if (raw is Map) {
        detailsMaps.add(
          raw.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }
    if (detailsMaps.isEmpty) {
      throw Exception('No internal wash schedule found');
    }

    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    var position = detailsMaps.length - 1;
    for (var i = 0; i < detailsMaps.length; i++) {
      final from = _formatRangeDate((detailsMaps[i]['from_date'] ?? '').toString());
      final to = _formatRangeDate((detailsMaps[i]['to_date'] ?? '').toString());
      if (from.isNotEmpty && to.isNotEmpty && _isBetween(today, from, to)) {
        position = i;
      }
    }
    return InternalWashForm.fromJson(detailsMaps[position]);
  }

  @override
  Future<WashCalendarData> getWashCalendar({
    required String token,
    required String customerId,
    required String vehicleId,
    required String orderId,
  }) async {
    final data = await _remoteDataSource.getWashDetails(
      token: token,
      customerId: customerId,
      vehicleId: vehicleId,
      orderId: orderId,
    );
    _throwOnSession(data);
    final code = (data['code'] ?? '').toString();
    if (code == '201') {
      throw Exception((data['message'] ?? 'No wash details').toString());
    }
    if (code != '200') {
      throw Exception((data['message'] ?? 'Failed to load calendar').toString());
    }

    final washDays = <CalendarMarkedDay>[];
    final internalDays = <CalendarMarkedDay>[];
    String? pendingId;
    var canSchedule1 = false;
    var canSchedule2 = false;

    final washList = data['wash_details'];
    if (washList is List) {
      for (final raw in washList) {
        if (raw is! Map) continue;
        final map = raw.map((k, v) => MapEntry(k.toString(), v));
        final date = _parseDate((map['date'] ?? '').toString());
        if (date == null) continue;
        washDays.add(
          CalendarMarkedDay(
            date: date,
            kind: CalendarEventKind.wash,
            title: 'External Wash',
            subtitle: (map['vehicle_image_dateandtime'] ?? '').toString(),
            imageUrl: (map['vehicle_image'] ?? '').toString(),
            status: (map['wash_status'] ?? '').toString(),
          ),
        );
      }
    }

    final internalList = data['internal_details'];
    if (internalList is List) {
      for (final raw in internalList) {
        if (raw is! Map) continue;
        final map = raw.map((k, v) => MapEntry(k.toString(), v));
        pendingId = (map['id'] ?? '').toString();
        final d1 = (map['schedule_date1'] ?? '').toString();
        final d2 = (map['schedule_date2'] ?? '').toString();
        if (d1.isEmpty && d2.isEmpty) {
          canSchedule1 = true;
        } else if (d1.isNotEmpty && d2.isEmpty) {
          canSchedule2 = true;
        }
        final date1 = _parseDate(d1);
        if (date1 != null) {
          internalDays.add(
            CalendarMarkedDay(
              date: date1,
              kind: CalendarEventKind.internalSchedule,
              title: 'Internal Wash',
              subtitle:
                  'Wash Date : ${(map['vehicle_image1_dateandtime'] ?? '').toString()}',
              imageUrl: (map['vehicle_image1'] ?? '').toString(),
              status: (map['schedule_work_status1'] ?? '').toString(),
            ),
          );
        }
        final date2 = _parseDate(d2);
        if (date2 != null) {
          internalDays.add(
            CalendarMarkedDay(
              date: date2,
              kind: CalendarEventKind.internalSchedule,
              title: 'Internal Wash',
              subtitle:
                  'Wash Date : ${(map['vehicle_image2_dateandtime'] ?? '').toString()}',
              imageUrl: (map['vehicle_image2'] ?? '').toString(),
              status: (map['schedule_work_status2'] ?? '').toString(),
            ),
          );
        }
      }
    }

    return WashCalendarData(
      washDays: washDays,
      internalDays: internalDays,
      pendingInternalId: pendingId,
      canScheduleDate1: canSchedule1,
      canScheduleDate2: canSchedule2,
    );
  }

  @override
  Future<ExtraInteriorCalendarData> getExtraInteriorCalendar({
    required String token,
    required String customerId,
    required String vehicleId,
  }) async {
    final data = await _remoteDataSource.getExtraInteriorDetails(
      token: token,
      customerId: customerId,
      vehicleId: vehicleId,
    );
    _throwOnSession(data);
    final code = (data['code'] ?? '').toString();
    if (code == '201') {
      throw Exception((data['message'] ?? 'No extra interior data').toString());
    }
    if (code != '200') {
      throw Exception((data['message'] ?? 'Failed to load calendar').toString());
    }

    final days = <CalendarMarkedDay>[];
    final list = data['extra_interior'];
    if (list is List) {
      for (final raw in list) {
        if (raw is! Map) continue;
        final map = raw.map((k, v) => MapEntry(k.toString(), v));
        final date = _parseDate((map['schedule_date'] ?? '').toString());
        if (date == null) continue;
        days.add(
          CalendarMarkedDay(
            date: date,
            kind: CalendarEventKind.extraInterior,
            title: 'Internal Clean',
            subtitle: 'Wash Date : ${(map['schedule_date'] ?? '').toString()}',
            imageUrl: (map['vehicle_image'] ?? '').toString(),
            status: (map['schedule_work_status'] ?? '').toString(),
          ),
        );
      }
    }
    return ExtraInteriorCalendarData(days: days);
  }

  @override
  Future<String> cancelSubscription({
    required String token,
    required String vehicleId,
    required String orderId,
  }) async {
    final data = await _remoteDataSource.cancelSubscription(
      token: token,
      vehicleId: vehicleId,
      orderId: orderId,
    );
    _throwOnSession(data);
    final code = (data['code'] ?? '').toString();
    if (code == '200') {
      return (data['result'] ?? data['message'] ?? 'Subscription cancelled')
          .toString();
    }
    throw Exception((data['message'] ?? 'Cancel failed').toString());
  }

  @override
  Future<String> cancelCodOrder({
    required String orderId,
    required String customerId,
    required String reason,
  }) async {
    final data = await _remoteDataSource.cancelCodOrder(
      orderId: orderId,
      customerId: customerId,
      reason: reason,
    );
    final code = (data['code'] ?? '').toString();
    if (code == '200' || code == '201') {
      return (data['message'] ?? 'Order cancelled').toString();
    }
    throw Exception((data['message'] ?? 'Cancel failed').toString());
  }

  @override
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
  }) async {
    final data = await _remoteDataSource.scheduleInternalCleanNew(
      token: token,
      customerId: customerId,
      vehicleId: vehicleId,
      orderId: orderId,
      scheduleDate1: scheduleDate1,
      scheduleTime1: scheduleTime1,
      comment1: comment1,
      scheduleDate2: scheduleDate2,
      scheduleTime2: scheduleTime2,
      comment2: comment2,
      id: id,
    );
    _throwOnSession(data);
    final code = (data['code'] ?? '').toString();
    if (code == '200') {
      return (data['message'] ?? 'Scheduled').toString();
    }
    throw Exception((data['message'] ?? 'Schedule failed').toString());
  }

  @override
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
  }) async {
    final data = await _remoteDataSource.scheduleInternalClean(
      token: token,
      customerId: customerId,
      vehicleId: vehicleId,
      orderId: orderId,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      comment: comment,
      dateType: dateType,
      id: id,
    );
    _throwOnSession(data);
    final code = (data['code'] ?? '').toString();
    if (code == '200') {
      return (data['message'] ?? 'Scheduled').toString();
    }
    throw Exception((data['message'] ?? 'Schedule failed').toString());
  }

  void _throwOnSession(Map<String, dynamic> data) {
    if ((data['code'] ?? '').toString() == '203') {
      throw Exception('Session expired');
    }
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    for (final pattern in <String>['yyyy-MM-dd', 'yyyy-M-d']) {
      try {
        return DateFormat(pattern).parse(value);
      } catch (_) {}
    }
    return null;
  }

  String _formatRangeDate(String value) {
    if (value.isEmpty) return '';
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(value);
      return DateFormat('dd-MMM-yyyy').format(parsed);
    } catch (_) {
      return '';
    }
  }

  bool _isBetween(String dateToCheck, String startDate, String endDate) {
    try {
      final request = DateFormat('dd/MM/yyyy').parse(dateToCheck);
      final from = DateFormat('dd-MMM-yyyy').parse(startDate);
      final to = DateFormat('dd-MMM-yyyy').parse(endDate);
      return !request.isBefore(from) && !request.isAfter(to);
    } catch (_) {
      return false;
    }
  }
}
