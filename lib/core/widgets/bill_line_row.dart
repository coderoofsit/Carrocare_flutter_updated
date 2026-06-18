import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class BillLineRow extends StatelessWidget {
  const BillLineRow({
    super.key,
    required this.label,
    required this.amount,
    this.muted = false,
    this.labelStyle,
    this.amountStyle,
  });

  final String label;
  final String amount;
  final bool muted;
  final TextStyle? labelStyle;
  final TextStyle? amountStyle;

  @override
  Widget build(BuildContext context) {
    final defaultLabel = AppTypography.dmSans(
      fontSize: muted ? 12 : 14,
      fontWeight: FontWeight.w400,
      color: muted ? AppColors.grey500 : AppColors.grey600,
    );
    final defaultAmount = AppTypography.dmSans(
      fontSize: muted ? 12 : 14,
      fontWeight: FontWeight.w600,
      color: muted ? AppColors.grey500 : AppColors.grey800,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: labelStyle ?? defaultLabel,
            ),
          ),
          Text(
            amount,
            style: amountStyle ?? defaultAmount,
          ),
        ],
      ),
    );
  }
}
