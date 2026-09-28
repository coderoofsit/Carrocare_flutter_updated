import 'dart:io';

import 'package:carrocare_flutter/core/device/device_info_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// App build + device details sent on every API call so server logs show
/// which app version made each request (X-App-* headers).
class AppClientHeaders {
  AppClientHeaders._();

  static Future<Map<String, String>>? _cached;
  static String _versionTag = '';

  /// Short form like `1.7.15+50 android`, empty until [headers] resolves.
  static String get versionTag => _versionTag;

  static Future<Map<String, String>> headers() {
    return _cached ??= _load();
  }

  static Future<Map<String, String>> _load() async {
    final result = <String, String>{};
    try {
      final package = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid
          ? 'android'
          : (Platform.isIOS ? 'ios' : Platform.operatingSystem);
      result['X-App-Version'] = package.version;
      result['X-App-Build'] = package.buildNumber;
      result['X-App-Platform'] = platform;
      _versionTag = package.buildNumber.isNotEmpty
          ? '${package.version}+${package.buildNumber} $platform'
          : '${package.version} $platform';
    } catch (_) {}
    try {
      final device = await const DeviceInfoService().getRegistrationInfo();
      result['X-Device-Model'] = _headerSafe(device.deviceModel);
      result['X-OS-Version'] = _headerSafe(device.osVersion);
    } catch (_) {}
    return result;
  }

  static String _headerSafe(String value) {
    return value.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
  }
}
