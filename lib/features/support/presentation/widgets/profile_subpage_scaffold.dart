import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Red header + grey body shell used on profile sub-screens (Android parity).
class ProfileSubpageScaffold extends StatelessWidget {
  const ProfileSubpageScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.body,
    this.footer,
  });

  final String title;
  final VoidCallback onBack;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 35,
                      height: 35,
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(5),
                      child: Image.asset('assets/images/back.png'),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 45),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEDEFF1),
                child: body,
              ),
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}
