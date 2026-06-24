import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase Messaging and exposes the device FCM token.
class FcmService {
  FcmService();

  late FirebaseMessaging _messaging;
  String? _cachedToken;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    _messaging = FirebaseMessaging.instance;
    await _requestPermission();
    _cachedToken = await _fetchFcmToken();
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

  Future<void> _waitForApnsToken() async {
    if (!Platform.isIOS) {
      return;
    }
    for (var attempt = 0; attempt < 10; attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<String?> _fetchFcmToken() async {
    try {
      await _waitForApnsToken();
      return await _messaging.getToken();
    } on FirebaseException catch (error) {
      if (error.code == 'apns-token-not-set') {
        debugPrint(
          'FCM: APNS token not ready yet. Push token will be fetched later.',
        );
        return null;
      }
      rethrow;
    }
  }

  Future<String> getToken() async {
    if (!_isInitialized) {
      await initialize();
    }
    _cachedToken ??= await _fetchFcmToken();
    return _cachedToken ?? '';
  }

  Stream<String> get onTokenRefresh {
    if (!_isInitialized) {
      throw StateError('FcmService.initialize() must be called first.');
    }
    return _messaging.onTokenRefresh;
  }
}
