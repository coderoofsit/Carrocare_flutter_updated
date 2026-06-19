import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Observes device network availability for offline UI handling.
class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Stream<bool> get onConnectivityChanged => _onlineController.stream;

  Future<void> start() async {
    _isOnline = _hasConnection(await _connectivity.checkConnectivity());
    _onlineController.add(_isOnline);

    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _hasConnection(results);
      if (online == _isOnline) return;
      _isOnline = online;
      _onlineController.add(online);
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _onlineController.close();
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any(
      (result) =>
          result != ConnectivityResult.none &&
          result != ConnectivityResult.bluetooth,
    );
  }
}
