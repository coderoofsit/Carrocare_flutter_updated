import 'package:shared_preferences/shared_preferences.dart';

/// GST rate used for checkout (prices shown to customers are GST-inclusive).
abstract final class CheckoutGstConfig {
  static const int defaultGstPercent = 18;
  static const String prefsKey = 'gst_percentage';

  static int resolvePercent(SharedPreferences prefs) {
    final stored = int.tryParse(prefs.getString(prefsKey) ?? '') ?? 0;
    return stored > 0 ? stored : defaultGstPercent;
  }

  static Future<void> persistPercent(SharedPreferences prefs, int gstPercent) async {
    if (gstPercent <= 0) return;
    await prefs.setString(prefsKey, gstPercent.toString());
  }
}
