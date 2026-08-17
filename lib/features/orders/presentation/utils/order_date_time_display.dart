import 'package:intl/intl.dart';

/// Formats order timestamps from the Android API (`date_and_time`, etc.).
///
/// API values are Indian wall-clock times. Never apply a second timezone offset.
class OrderDateTimeDisplay {
  OrderDateTimeDisplay._();

  static final RegExp _legacyApiDateTime = RegExp(
    r'^(\d{1,2})-(\d{1,2})-(\d{4}) (\d{1,2}):(\d{2}):(\d{2}) (AM|PM)$',
    caseSensitive: false,
  );

  static final RegExp _mySqlDateTime = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
  );

  static final List<DateFormat> _dateTimeFormats = <DateFormat>[
    DateFormat('dd-MM-yyyy hh:mm:ss a'),
    DateFormat('d-M-yyyy h:mm:ss a'),
    DateFormat('dd-MM-yyyy HH:mm:ss'),
    DateFormat('d-M-yyyy H:mm:ss'),
    DateFormat('yyyy-MM-dd HH:mm:ss'),
    DateFormat('yyyy-MM-dd hh:mm:ss a'),
  ];

  /// Legacy API stored 12-hour digits without AM/PM — pick closest to now.
  static int _resolveLegacyPhpDateTimeHour({
    required int storedHour,
    required int year,
    required int month,
    required int day,
    required int minute,
    required int second,
  }) {
    if (storedHour == 0 || storedHour >= 13) return storedHour;

    final candidates = storedHour == 12
        ? <int>[0, 12]
        : <int>[storedHour, storedHour + 12];
    final referenceNow = DateTime.now();

    var best = candidates.first;
    var bestDist = double.infinity;
    for (final candidate in candidates) {
      final dt = DateTime(year, month, day, candidate, minute, second);
      final dist = (dt.difference(referenceNow).inSeconds).abs().toDouble();
      if (dist < bestDist) {
        bestDist = dist;
        best = candidate;
      }
    }
    return best;
  }

  static DateTime? _parseWallClock(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final mysql = _mySqlDateTime.firstMatch(trimmed);
    if (mysql != null) {
      final year = int.parse(mysql.group(1)!);
      final month = int.parse(mysql.group(2)!);
      final day = int.parse(mysql.group(3)!);
      final minute = int.parse(mysql.group(5)!);
      final second = int.parse(mysql.group(6)!);
      final hour24 = _resolveLegacyPhpDateTimeHour(
        storedHour: int.parse(mysql.group(4)!),
        year: year,
        month: month,
        day: day,
        minute: minute,
        second: second,
      );
      return DateTime(year, month, day, hour24, minute, second);
    }

    for (final format in _dateTimeFormats) {
      try {
        return format.parse(trimmed);
      } catch (_) {}
    }
    return DateTime.tryParse(trimmed);
  }

  static String? _normalizeLegacyApiDateTime(String raw) {
    final match = _legacyApiDateTime.firstMatch(raw.trim());
    if (match == null) return null;
    final day = match.group(1)!.padLeft(2, '0');
    final month = match.group(2)!.padLeft(2, '0');
    final year = match.group(3)!;
    final hour = match.group(4)!.padLeft(2, '0');
    final minute = match.group(5)!;
    final second = match.group(6)!;
    final meridiem = match.group(7)!.toUpperCase();
    return '$day-$month-$year $hour:$minute:$second $meridiem';
  }

  static String _formatWallClock(DateTime value) {
    return DateFormat('dd-MM-yyyy hh:mm:ss a').format(value);
  }

  static String formatDate(String raw) {
    final legacy = _normalizeLegacyApiDateTime(raw);
    if (legacy != null) {
      return legacy.split(' ').first;
    }
    final parsed = _parseWallClock(raw);
    if (parsed == null) return raw.trim();
    return DateFormat('dd-MM-yyyy').format(parsed);
  }

  static String formatTime(String raw) {
    final legacy = _normalizeLegacyApiDateTime(raw);
    if (legacy != null) {
      final parts = legacy.split(' ');
      if (parts.length >= 3) {
        return '${parts[1]} ${parts[2]}';
      }
    }
    final parsed = _parseWallClock(raw);
    if (parsed == null) return raw.trim();
    return DateFormat('hh:mm:ss a').format(parsed);
  }

  static String formatDateTime(String raw) {
    final trimmed = raw.trim();
    final legacy = _normalizeLegacyApiDateTime(trimmed);
    if (legacy != null) return legacy;

    final parsed = _parseWallClock(trimmed);
    if (parsed == null) return trimmed;

    return _formatWallClock(parsed);
  }

  /// Combines schedule date + preferred time for order detail rows.
  static String formatSchedule({
    required String date,
    required String time,
  }) {
    final d = date.trim();
    final t = time.trim();
    if (d.isEmpty && t.isEmpty) return '';
    if (d.isEmpty) return t;
    if (t.isEmpty) return d;
    return '$d · $t';
  }

  static DateTime? parseWallClock(String raw) => _parseWallClock(raw);
}
