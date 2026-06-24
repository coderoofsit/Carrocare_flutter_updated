import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Device metadata sent with login-verify / register for push targeting.
class DeviceRegistrationInfo {
  const DeviceRegistrationInfo({
    required this.deviceName,
    required this.deviceModel,
    required this.osVersion,
  });

  final String deviceName;
  final String deviceModel;
  final String osVersion;
}

class DeviceInfoService {
  const DeviceInfoService();

  Future<DeviceRegistrationInfo> getRegistrationInfo() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return DeviceRegistrationInfo(
        deviceName: info.brand,
        deviceModel: info.model,
        osVersion: 'Android ${info.version.release}',
      );
    }
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return DeviceRegistrationInfo(
        deviceName: info.name,
        deviceModel: info.utsname.machine,
        osVersion: 'iOS ${info.systemVersion}',
      );
    }
    return const DeviceRegistrationInfo(
      deviceName: 'unknown',
      deviceModel: 'unknown',
      osVersion: 'unknown',
    );
  }
}
