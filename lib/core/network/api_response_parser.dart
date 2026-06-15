import 'dart:convert';

/// PHP APIs often prepend notices/HTML before JSON. Android Gson still parses
/// the payload; Dio with [ResponseType.json] fails at the first `<`.
class ApiResponseParser {
  static dynamic decode(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty API response');
    }
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return jsonDecode(trimmed);
    }
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw FormatException('No JSON object in API response', body, 0);
    }
    return jsonDecode(trimmed.substring(start, end + 1));
  }
}
