import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class ContentSectionHeader extends StatelessWidget {
  const ContentSectionHeader({
    super.key,
    required this.title,
    this.fontSize = 22,
  });

  final String title;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppTypography.quicksand(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 3,
              color: AppColors.grey900,
            ),
            Container(
              width: 72,
              height: 3,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
