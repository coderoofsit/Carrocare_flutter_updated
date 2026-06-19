import 'dart:async';

import 'package:carrocare_flutter/app/router.dart';
import 'package:carrocare_flutter/core/network/connectivity_service.dart';
import 'package:flutter/scheduler.dart';

/// Pushes the offline screen when connectivity is lost and pops it when restored.
class OfflineNavigationHandler {
  OfflineNavigationHandler(this._connectivityService);

  final ConnectivityService _connectivityService;

  static const String offlineRoute = '/offline';

  StreamSubscription<bool>? _subscription;
  bool _offlineRouteVisible = false;

  void start() {
    _subscription?.cancel();
    _subscription = _connectivityService.onConnectivityChanged.listen(
      _handleConnectivity,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_connectivityService.isOnline) {
        _showOfflineScreen();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _handleConnectivity(bool isOnline) {
    if (isOnline) {
      _hideOfflineScreen();
      return;
    }
    _showOfflineScreen();
  }

  void _showOfflineScreen() {
    if (_offlineRouteVisible) return;

    final currentPath = appRouter.state.uri.path;
    if (currentPath == offlineRoute) {
      _offlineRouteVisible = true;
      return;
    }

    _offlineRouteVisible = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (appRouter.state.uri.path != offlineRoute) {
        appRouter.push(offlineRoute);
      }
    });
  }

  void _hideOfflineScreen() {
    if (!_offlineRouteVisible) return;

    final onOfflineRoute = appRouter.state.uri.path == offlineRoute;
    _offlineRouteVisible = false;
    if (onOfflineRoute && appRouter.canPop()) {
      appRouter.pop();
    }
  }
}
