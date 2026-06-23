import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.onTap,
  });

  static const double _cardRadius = 20;

  final String title;
  final String imageAsset;
  final VoidCallback onTap;

  static BoxDecoration get neoCardDecoration => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F9E9E9E),
            offset: Offset(5, 5),
            blurRadius: 14,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Color(0x14B0B0B0),
            offset: Offset(3, 6),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0x40FFFFFF),
            offset: Offset(-3, -3),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_cardRadius),
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: Ink(
              decoration: neoCardDecoration,
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.local_car_wash_outlined,
                      size: 48,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
