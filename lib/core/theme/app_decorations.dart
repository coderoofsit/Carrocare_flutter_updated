import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppDecorations {
  AppDecorations._();

  static const double cardRadius = 16;
  static const double inputRadius = 12;
  static const double buttonRadius = 12;
  static const double bannerRadius = 20;

  static BoxDecoration card({Color? color, bool showShadow = true}) => BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AppColors.grey200),
        boxShadow: showShadow
            ? const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      );

  static BoxDecoration inputField() => BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(inputRadius),
        border: Border.all(color: AppColors.grey300),
      );

  static OutlineInputBorder inputBorder({bool focused = false}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(
          color: focused ? AppColors.primary : AppColors.grey300,
          width: focused ? 1.5 : 1,
        ),
      );
}
