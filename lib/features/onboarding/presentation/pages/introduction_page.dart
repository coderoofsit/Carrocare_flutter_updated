import 'dart:async';

import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/auth_token_service.dart';
import 'package:carrocare_flutter/core/utils/profile_prefs_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _handleRedirection();
  }

  void _handleRedirection() {
    _navigationTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final authTokens = sl<AuthTokenService>();
      final hasSession = await authTokens.hasStoredSession();
      if (!hasSession) {
        if (!mounted) return;
        context.go('/splash');
        return;
      }
      final accessToken = await authTokens.bearerAccessToken();
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString('token') ?? '';
      final customerId = prefs.getString('customer_id') ?? '';
      if ((accessToken == null || accessToken.isEmpty) &&
          (legacyToken.isEmpty || customerId.isEmpty)) {
        return;
      }
      await syncProfileFromServer(
        token: legacyToken,
        customerId: customerId,
      );
      if (!mounted) return;
      context.go('/home');
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/logo512.png',
              width: size.width * 0.34,
              height: size.width * 0.34,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
