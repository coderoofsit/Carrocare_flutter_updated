import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Initializes Firebase Messaging and exposes the device FCM token.
class FcmService {
  FcmService();

  FirebaseMessaging? _messaging;
  String? _cachedToken;
  bool _isInitialized = false;

  FirebaseMessaging get _messagingInstance =>
      _messaging ?? FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    _messaging = FirebaseMessaging.instance;
    try {
      await _requestPermission();
    } catch (_) {}
    _cachedToken = await _fetchToken();
    _isInitialized = true;
  }

  Future<String?> _fetchToken() async {
    try {
      return await _messagingInstance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _requestPermission() async {
    if (Platform.isIOS || Platform.isAndroid) {
      await _messagingInstance.requestPermission(
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
    _cachedToken ??= await _fetchToken();
    return _cachedToken ?? '';
  }

  Stream<String> get onTokenRefresh => _messagingInstance.onTokenRefresh;
}
