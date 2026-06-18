import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_app_bar.dart';
import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onBack,
    this.bodyBackgroundColor = AppColors.grey200,
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.screenBackground,
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              CarroCareAppBar(
                title: title,
                leading: CarroCareAppBarLeading.back,
                onLeadingTap: onBack,
                showBorder: true,
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
                  padding: EdgeInsets.only(top: compact ? 18 : 24, bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppDecorations.bannerRadius),
                      topRight: Radius.circular(AppDecorations.bannerRadius),
                    ),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTypography.quicksand(
                            fontSize: compact ? 22 : 25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: AppTypography.dmSans(
                            fontSize: compact ? 15 : 17,
                            color: AppColors.grey600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: compact ? 20 : 28),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
