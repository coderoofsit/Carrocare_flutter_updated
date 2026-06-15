import 'package:carrocare_flutter/app/router.dart';
import 'package:carrocare_flutter/core/network/auth_token_service.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clears local session and navigates to login once when auth can no longer be renewed.
class SessionExpiredHandler {
  SessionExpiredHandler(this._authTokens);

  final AuthTokenService _authTokens;

  static const String expiredMessage =
      'Session expired. Please sign in again.';

  static const List<String> _publicRoutes = <String>[
    '/login',
    '/signup',
    '/forgot-password',
    '/splash',
    '/introduction',
  ];

  bool _isHandling = false;

  /// Wired from [AuthTokenService] when JWT refresh fails.
  Future<void> handle() => _redirectToLogin();

  /// API legacy session (`code: 203`) or Bearer retry exhausted.
  Future<void> handleFromApi() => _redirectToLogin();

  Future<void> _redirectToLogin() async {
    if (_isHandling) return;
    if (_isOnPublicRoute()) return;
    _isHandling = true;
    try {
      await _clearLocalSession();
      if (_isOnPublicRoute()) return;
      appRouter.go('/login');
      _showMessage();
    } finally {
      Future<void>.delayed(const Duration(seconds: 2), () {
        _isHandling = false;
      });
    }
  }

  Future<void> _clearLocalSession() async {
    await CartLocalStorage().clear();
    await _authTokens.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  bool _isOnPublicRoute() {
    final path = appRouter.state.uri.path;
    return _publicRoutes.any(
      (route) => path == route || path.startsWith('$route/'),
    );
  }

  void _showMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text(expiredMessage)),
      );
    });
  }
}

/// Global messenger for session-expired snackbars outside widget trees.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
