import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  static const double _barHeight = 60;
  static const double _iconSlotSize = 28;
  static const double _iconRenderSize = 60;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: List<Widget>.generate(items.length, (index) {
              final item = items[index];
              final selected = currentIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: _iconSlotSize,
                        height: _iconSlotSize,
                        child: OverflowBox(
                          maxWidth: _iconRenderSize,
                          maxHeight: _iconRenderSize,
                          alignment: Alignment.center,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              selected ? AppColors.primary : AppColors.grey500,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              item.iconAsset,
                              width: _iconRenderSize,
                              height: _iconRenderSize,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.circle_outlined,
                                size: _iconRenderSize,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.grey500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: selected
                            ? AppTypography.quicksand(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              )
                            : AppTypography.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey500,
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.iconAsset,
    required this.label,
  });

  final String iconAsset;
  final String label;
}
