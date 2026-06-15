import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Temporary debug helper — remove when no longer needed.
abstract final class SessionDebug {
  static Future<void> logCustomerId({String tag = 'SessionDebug'}) async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id') ?? '';
    debugPrint('[$tag] customer_id=$customerId');
  }
}
