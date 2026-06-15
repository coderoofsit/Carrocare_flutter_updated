import 'package:carrocare_flutter/app/router.dart';
import 'package:carrocare_flutter/core/auth/session_expired_handler.dart';
import 'package:carrocare_flutter/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CarroCareApp extends StatelessWidget {
  const CarroCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Carro Care',
      theme: AppTheme.light(),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: appRouter,
    );
  }
}
