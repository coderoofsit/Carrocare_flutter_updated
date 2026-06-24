import 'package:carrocare_flutter/app/app.dart';
import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/connectivity_service.dart';
import 'package:carrocare_flutter/core/network/offline_navigation_handler.dart';
import 'package:carrocare_flutter/core/notifications/fcm_service.dart';
import 'package:carrocare_flutter/core/notifications/push_registration_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await sl<FcmService>().initialize();
  sl<PushRegistrationService>().startTokenRefreshListener(() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? prefs.getString('useremail') ?? '';
  });
  await sl<ConnectivityService>().start();
  sl<OfflineNavigationHandler>().start();
  runApp(const CarroCareApp());
}
