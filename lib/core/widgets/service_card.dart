import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/remote_image_with_fallback.dart';
import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.imageAsset,
    this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String imageAsset;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        child: Ink(
          decoration: AppDecorations.card(),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDecorations.cardRadius),
                    topRight: Radius.circular(AppDecorations.cardRadius),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: RemoteImageWithFallback(
                      imageUrl: imageUrl,
                      fallbackAsset: imageAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.grey200),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppDecorations.cardRadius),
                    bottomRight: Radius.circular(AppDecorations.cardRadius),
                  ),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
