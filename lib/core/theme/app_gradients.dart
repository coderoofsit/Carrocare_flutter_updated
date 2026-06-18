import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  /// Soft diagonal red wash for the home dashboard.
  /// Uses opaque pastel reds — transparent stops composite with the scaffold
  /// and appear dark/muddy at the top-left.
  static const LinearGradient homeBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFFECEC),
      Color.fromARGB(255, 252, 167, 167),
      Color.fromARGB(255, 246, 143, 143),
      AppColors.white,
      AppColors.grey50,
    ],
    stops: <double>[0.0, 0.28, 0.52, 0.8, 1.0],
  );

  /// Constant light gradient for all non-home screens.
  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppColors.white,
      AppColors.grey50,
    ],
  );

  /// Soft light-red background for wash listing screens.
  static const LinearGradient washScreenBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFFFF3F3),
      Color(0xFFFFF8F8),
      Color.fromARGB(255, 255, 220, 220),
    ],
    stops: <double>[0.0, 0.24, 0.72],
  );

  /// Soft red tint for promo banners.
  static const LinearGradient promoBanner = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.primaryTintStrong,
      AppColors.white,
    ],
  );
}
