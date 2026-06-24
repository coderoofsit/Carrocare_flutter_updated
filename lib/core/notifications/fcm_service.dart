import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Initializes Firebase Messaging and exposes the device FCM token.
class FcmService {
  FcmService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _cachedToken;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    await Firebase.initializeApp();
    await _requestPermission();
    _cachedToken = await _messaging.getToken();
    _isInitialized = true;
  }

  Future<void> _requestPermission() async {
    if (Platform.isIOS || Platform.isAndroid) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<String> getToken() async {
    if (!_isInitialized) {
      await initialize();
    }
    _cachedToken ??= await _messaging.getToken();
    return _cachedToken ?? '';
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
