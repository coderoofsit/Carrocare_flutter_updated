import 'package:flutter/foundation.dart';

/// App-wide URLs. Override with `--dart-define=API_HOST=http://192.168.x.x:4000`.
class AppUrls {
  static const String productionHost = 'https://car-ro-care.onrender.com';
  static const String localHost = 'http://127.0.0.1:4000';

  static String get apiHost {
    const override = String.fromEnvironment('API_HOST');
    if (override.isNotEmpty) {
      return override;
    }
    if (kDebugMode) {
      return localHost;
    }
    return productionHost;
  }

  /// REST API (login, orders, prices, save_order, etc.)
  static String get apiBaseUrl => '$apiHost/Android_API/api-1.2.11/';

  /// Web checkout / autopay mandate flow.
  static String get webviewCheckout =>
      '$apiHost/Android_API/webview_checkout.php';

  static String get privacyPolicy =>
      '$apiHost/Android_API/privacy-policy.php';
  static String get termsAndConditions =>
      '$apiHost/Android_API/terms-and-conditions.php';
  static String get faq => '$apiHost/Android_API/faq.php';
  static String get aboutUs => '$apiHost/Android_API/about-us.php';
  static String get mobileAssets => '${apiBaseUrl}mobile-assets.php';

  static const String muviereck = 'https://www.muvierecktech.com/';
  static const String playStore =
      'https://play.google.com/store/apps/details?id=com.muvierecktech.carrocare';
  static const String whatsAppNumber = '+917904015630';
  static const String whatsAppMessage = 'Hi Carrocare team ';

  static bool isAppBackendUrl(String url) {
    return url.contains('car-ro-care.onrender.com') ||
        url.contains('carrocare.in') ||
        url.contains('yetloapps.com') ||
        url.contains('192.168.29.250') ||
        url.contains('127.0.0.1') ||
        url.contains('localhost') ||
        url.contains('10.0.2.2');
  }
}
