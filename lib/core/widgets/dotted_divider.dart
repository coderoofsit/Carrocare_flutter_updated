import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DottedDivider extends StatelessWidget {
  const DottedDivider({
    super.key,
    this.color = AppColors.grey300,
    this.height = 1,
    this.dashWidth = 4,
    this.dashGap = 4,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  final Color color;
  final double height;
  final double dashWidth;
  final double dashGap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount =
              (constraints.maxWidth / (dashWidth + dashGap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              dashCount,
              (_) => Container(
                width: dashWidth,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
