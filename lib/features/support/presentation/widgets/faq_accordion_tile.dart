import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/features/support/presentation/constants/faq_content.dart';
import 'package:flutter/material.dart';

class FaqAccordionTile extends StatelessWidget {
  const FaqAccordionTile({
    super.key,
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final FaqItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = expanded ? AppColors.primary : AppColors.grey800;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _QuestionMarkIcon(color: activeColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.question,
                      style: AppTypography.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: activeColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.remove : Icons.add,
                    color: activeColor,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...<Widget>[
            const Divider(height: 1, color: AppColors.grey300),
            Container(
              width: double.infinity,
              color: AppColors.grey50,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Text(
                item.answer,
                style: AppTypography.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey700,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionMarkIcon extends StatelessWidget {
  const _QuestionMarkIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '?',
        style: AppTypography.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}
