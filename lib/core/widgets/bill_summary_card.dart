import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/bill_line_row.dart';
import 'package:carrocare_flutter/core/widgets/dotted_divider.dart';
import 'package:flutter/material.dart';

class BillLine {
  const BillLine({
    required this.label,
    required this.amount,
    this.muted = false,
  });

  final String label;
  final String amount;
  final bool muted;
}

class BillSummaryCard extends StatelessWidget {
  const BillSummaryCard({
    super.key,
    this.title = 'Charges',
    required this.lines,
    required this.totalLabel,
    required this.totalAmount,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final List<BillLine> lines;
  final String totalLabel;
  final String totalAmount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey800,
            ),
          ),
          const DottedDivider(margin: EdgeInsets.symmetric(vertical: 10)),
          ...lines.map(
            (line) => BillLineRow(
              label: line.label,
              amount: line.amount,
              muted: line.muted,
            ),
          ),
          const DottedDivider(margin: EdgeInsets.symmetric(vertical: 10)),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  totalLabel,
                  style: AppTypography.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
              ),
              Text(
                totalAmount,
                style: AppTypography.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
