class CustomerScheduleVehicle {
  const CustomerScheduleVehicle({
    required this.vehicleId,
    required this.vehicleNo,
    this.make = '',
    this.model = '',
  });

  final String vehicleId;
  final String vehicleNo;
  final String make;
  final String model;

  String get label {
    if (vehicleNo.isNotEmpty) return vehicleNo;
    final parts = [make, model].where((s) => s.isNotEmpty).join(' ');
    return parts.isEmpty ? vehicleId : parts;
  }

  factory CustomerScheduleVehicle.fromJson(Map<String, dynamic> json) {
    return CustomerScheduleVehicle(
      vehicleId: (json['vehicle_id'] ?? '').toString(),
      vehicleNo: (json['vehicle_no'] ?? '').toString(),
      make: (json['make'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
    );
  }
}

class CustomerScheduleEvent {
  const CustomerScheduleEvent({
    required this.date,
    required this.eventType,
    required this.title,
    required this.vehicleId,
    required this.vehicleNo,
    this.status = 'No',
    this.notes = '',
    this.reportType = '',
    this.reportNote = '',
    this.completedAt,
    this.startedAt,
    this.reportedAt,
    this.beforeImageUrls = const [],
    this.washedImageUrls = const [],
    this.reportImageUrls = const [],
    this.scheduleTime = '',
  });

  final DateTime date;
  final String eventType;
  final String title;
  final String vehicleId;
  final String vehicleNo;
  final String status;
  final String notes;
  final String reportType;
  final String reportNote;
  final DateTime? completedAt;
  final DateTime? startedAt;
  final DateTime? reportedAt;
  final List<String> beforeImageUrls;
  final List<String> washedImageUrls;
  final List<String> reportImageUrls;
  final String scheduleTime;

  bool get isCompleted {
    final s = status.toLowerCase();
    return s == 'yes' || s == 'cleaned' || s == 'completed';
  }

  bool get isReported {
    final s = status.toLowerCase();
    return s == 'reported' || s.contains('issue');
  }

  factory CustomerScheduleEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(Object? value) {
      final raw = (value ?? '').toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    DateTime parseDay(Object? value) {
      final raw = (value ?? '').toString().trim();
      final dt = DateTime.tryParse(raw);
      if (dt != null) return DateTime(dt.year, dt.month, dt.day);
      return DateTime.now();
    }

    List<String> urls(Object? value) {
      if (value is! List) return const [];
      return value
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }

    return CustomerScheduleEvent(
      date: parseDay(json['date']),
      eventType: (json['event_type'] ?? '').toString(),
      title: (json['title'] ?? 'Service').toString(),
      vehicleId: (json['vehicle_id'] ?? '').toString(),
      vehicleNo: (json['vehicle_no'] ?? '').toString(),
      status: (json['status'] ?? 'No').toString(),
      notes: (json['notes'] ?? '').toString(),
      reportType: (json['report_type'] ?? '').toString(),
      reportNote: (json['report_note'] ?? '').toString(),
      completedAt: parseDt(json['completed_at']),
      startedAt: parseDt(json['started_at']),
      reportedAt: parseDt(json['reported_at']),
      beforeImageUrls: urls(json['before_image_urls']),
      washedImageUrls: urls(json['washed_image_urls']),
      reportImageUrls: urls(json['report_image_urls']),
      scheduleTime: (json['schedule_time'] ?? '').toString(),
    );
  }
}

class CustomerFullSchedule {
  const CustomerFullSchedule({
    required this.vehicles,
    required this.subscriptionEvents,
    required this.extraInteriorEvents,
  });

  final List<CustomerScheduleVehicle> vehicles;
  final List<CustomerScheduleEvent> subscriptionEvents;
  final List<CustomerScheduleEvent> extraInteriorEvents;
}
