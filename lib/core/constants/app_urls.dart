/// App-wide URLs. Update [devLanHost] when your machine's Wi‑Fi IP changes (`ifconfig` / `ip addr`).
class AppUrls {
  /// LAN IP of the machine running `npm run dev:api` (phone must be on the same Wi‑Fi).
  static const String devLanHost = '172.19.18.49';

  /// Production: `https://car-ro-care.onrender.com`
  /// USB-only dev: `http://127.0.0.1:4000` + `adb reverse tcp:4000 tcp:4000`
  static const String apiHost = 'http://$devLanHost:4000';

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
        url.contains(devLanHost) ||
        url.contains('127.0.0.1') ||
        url.contains('localhost') ||
        _isPrivateLanHost(url);
  }

  static bool _isPrivateLanHost(String url) {
    final match = RegExp(r'https?://(\d+\.\d+\.\d+\.\d+)').firstMatch(url);
    if (match == null) return false;
    final parts = match.group(1)!.split('.').map(int.parse).toList();
    if (parts.length != 4) return false;
    if (parts[0] == 10) return true;
    if (parts[0] == 192 && parts[1] == 168) return true;
    if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;
    return false;
  }
}
