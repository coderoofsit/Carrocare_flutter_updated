import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onBack,
    this.bodyBackgroundColor = AppColors.loginBody,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onBack;
  final Color bodyBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bool compact = size.width < 380;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 90,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 35,
                      height: 35,
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.all(7),
                      child: Image.asset('assets/images/back.png'),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    margin: EdgeInsets.only(right: compact ? 12 : 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Image.asset(
                      'assets/images/logo50.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
                decoration: BoxDecoration(
                  color: bodyBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: compact ? 18 : 24, bottom: 20),
                  child: Column(
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 22 : 25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: compact ? 16 : 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: compact ? 20 : 30),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
