/// App-wide URLs. Update [apiHost] when the backend base URL changes.
class AppUrls {
    /// Production API (Render). For local dev: `http://127.0.0.1:4000` with `adb reverse tcp:4000 tcp:4000`.
  static const String apiHost = 'http://10.0.2.2:4000';
  /// Local API via USB: `adb reverse tcp:4000 tcp:4000` then use 127.0.0.1.
  /// Wi‑Fi only: use your machine LAN IP, e.g. `http://10.37.175.49:4000`.
  // static const String apiHost = 'http://127.0.0.1:4000';
  // static const String apiHost = 'https://car-ro-care.onrender.com';
  /// REST API (login, orders, prices, save_order, etc.)
  static const String apiBaseUrl = '$apiHost/Android_API/api-1.2.11/';

  /// Web checkout / autopay mandate flow.
  static const String webviewCheckout =
      '$apiHost/Android_API/webview_checkout.php';

  static const String privacyPolicy =
      '$apiHost/Android_API/privacy-policy.php';
  static const String termsAndConditions =
      '$apiHost/Android_API/terms-and-conditions.php';
  static const String faq = '$apiHost/Android_API/faq.php';
  static const String aboutUs = '$apiHost/Android_API/about-us.php';

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
        url.contains('localhost');
  }
}
