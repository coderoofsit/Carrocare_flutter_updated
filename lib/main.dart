import 'package:carrocare_flutter/app/app.dart';
import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/connectivity_service.dart';
import 'package:carrocare_flutter/core/network/offline_navigation_handler.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await sl<ConnectivityService>().start();
  sl<OfflineNavigationHandler>().start();
  runApp(const CarroCareApp());
}
