import 'dart:async';

import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/auth_token_service.dart';
import 'package:carrocare_flutter/core/notifications/push_registration_service.dart';
import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:carrocare_flutter/core/utils/profile_prefs_sync.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_handleRedirection());
  }

  Future<void> _handleRedirection() async {
    var targetRoute = '/splash';
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final authTokens = sl<AuthTokenService>();
      final hasSession = await authTokens.hasStoredSession();
      if (!hasSession) {
        targetRoute = '/splash';
      } else {
        String? accessToken;
        try {
          accessToken = await authTokens.bearerAccessToken().timeout(
            const Duration(seconds: 8),
            onTimeout: () => null,
          );
        } catch (_) {
          accessToken = null;
        }
        if (!mounted) return;
        final prefs = await SharedPreferences.getInstance();
        final legacyToken = prefs.getString('token') ?? '';
        final customerId = prefs.getString('customer_id') ?? '';
        final canOpenHome =
            (accessToken != null && accessToken.isNotEmpty) ||
            (legacyToken.isNotEmpty && customerId.isNotEmpty);
        if (canOpenHome) {
          targetRoute = '/home';
          final email =
              prefs.getString('email') ?? prefs.getString('useremail') ?? '';
          if (email.isNotEmpty) {
            unawaited(sl<PushRegistrationService>().syncForEmail(email));
          }
          unawaited(
            syncProfileFromServer(
              token: legacyToken,
              customerId: customerId,
            ),
          );
        } else {
          targetRoute = '/splash';
        }
      }
    } catch (_) {
      targetRoute = '/splash';
    }
    if (!mounted) return;
    context.go(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.homeBackground,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/logo512.png',
                width: size.width * 0.34,
                height: size.width * 0.34,
              ),
              const SizedBox(height: 32),
              const DottedLoader(size: DottedLoaderSize.large),
            ],
          ),
        ),
      ),
    );
  }
}
