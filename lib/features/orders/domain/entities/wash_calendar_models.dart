enum CalendarEventKind { wash, internalSchedule, extraInterior }

class CalendarMarkedDay {
  const CalendarMarkedDay({
    required this.date,
    required this.kind,
    this.title = '',
    this.subtitle = '',
    this.imageUrl = '',
    this.status = '',
  });

  final DateTime date;
  final CalendarEventKind kind;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String status;
}

class WashCalendarData {
  const WashCalendarData({
    required this.washDays,
    required this.internalDays,
    this.pendingInternalId,
    this.canScheduleDate1 = false,
    this.canScheduleDate2 = false,
  });

  final List<CalendarMarkedDay> washDays;
  final List<CalendarMarkedDay> internalDays;
  final String? pendingInternalId;
  final bool canScheduleDate1;
  final bool canScheduleDate2;
}

class ExtraInteriorCalendarData {
  const ExtraInteriorCalendarData({required this.days});

  final List<CalendarMarkedDay> days;
}
