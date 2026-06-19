import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:flutter/material.dart';

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppGradients.homeBackground,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: <Widget>[
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/images/logo512.png',
                    width: size.width * 0.34,
                    height: size.width * 0.34,
                  ),
                  const SizedBox(height: 36),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    decoration: AppDecorations.card(),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Oops! You're offline",
                          textAlign: TextAlign.center,
                          style: AppTypography.quicksand(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No internet connection found. Please check your '
                          'network settings and we will bring you right back.',
                          textAlign: TextAlign.center,
                          style: AppTypography.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey600,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const DottedLoader(size: DottedLoaderSize.medium),
                        const SizedBox(height: 12),
                        Text(
                          'Waiting for connection…',
                          style: AppTypography.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
