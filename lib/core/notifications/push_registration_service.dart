import 'package:carrocare_flutter/core/device/device_info_service.dart';
import 'package:carrocare_flutter/core/notifications/fcm_service.dart';
import 'package:carrocare_flutter/features/auth/data/datasources/auth_remote_data_source.dart';

/// Syncs the FCM token and device metadata to the backend (login-verify.php).
class PushRegistrationService {
  PushRegistrationService(
    this._fcmService,
    this._deviceInfoService,
    this._authRemote,
  );

  final FcmService _fcmService;
  final DeviceInfoService _deviceInfoService;
  final AuthRemoteDataSource _authRemote;

  Future<void> syncForEmail(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return;
    }
    final token = await _fcmService.getToken();
    if (token.isEmpty) {
      return;
    }
    final device = await _deviceInfoService.getRegistrationInfo();
    await _authRemote.loginVerify(
      email: trimmedEmail,
      firebaseInstanceId: token,
      deviceName: device.deviceName,
      deviceModel: device.deviceModel,
      osVersion: device.osVersion,
    );
  }

  void startTokenRefreshListener(Future<String> Function() emailProvider) {
    _fcmService.onTokenRefresh.listen((token) async {
      if (token.isEmpty) {
        return;
      }
      final email = (await emailProvider()).trim();
      if (email.isEmpty) {
        return;
      }
      try {
        await syncForEmail(email);
      } catch (_) {}
    });
  }
}
