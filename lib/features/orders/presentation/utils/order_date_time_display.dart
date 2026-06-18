import 'package:intl/intl.dart';

/// Converts API order timestamps to Indian Standard Time (+05:30).
class OrderDateTimeDisplay {
  OrderDateTimeDisplay._();

  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  static final List<DateFormat> _dateTimeFormats = <DateFormat>[
    DateFormat('dd-MM-yyyy hh:mm:ss a'),
    DateFormat('d-M-yyyy h:mm:ss a'),
    DateFormat('dd-MM-yyyy HH:mm:ss'),
    DateFormat('d-M-yyyy H:mm:ss'),
    DateFormat('yyyy-MM-dd HH:mm:ss'),
    DateFormat('yyyy-MM-dd hh:mm:ss a'),
  ];

  static DateTime? _parseDateTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    for (final format in _dateTimeFormats) {
      try {
        return format.parse(trimmed);
      } catch (_) {}
    }
    return DateTime.tryParse(trimmed);
  }

  static DateTime? toIst(String raw) {
    final parsed = _parseDateTime(raw);
    if (parsed == null) return null;
    return parsed.add(_istOffset);
  }

  static String formatDate(String raw) {
    final ist = toIst(raw);
    if (ist == null) return raw.trim();
    return DateFormat('dd-MM-yyyy').format(ist);
  }

  static String formatTime(String raw) {
    final ist = toIst(raw);
    if (ist == null) return raw.trim();
    return DateFormat('hh:mm:ss a').format(ist);
  }

  static String formatDateTime(String raw) {
    final ist = toIst(raw);
    if (ist == null) return raw.trim();
    return DateFormat('dd-MM-yyyy hh:mm:ss a').format(ist);
  }
}
