import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/bill_line_row.dart';
import 'package:carrocare_flutter/core/widgets/dotted_divider.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/checkout/core/cart_display_helper.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';
import 'package:flutter/material.dart';

/// Matches Android `item_cart.xml`.
class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final CartItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final serviceLabel = CartDisplayHelper.serviceLabel(item);
    final showMonth = CartDisplayHelper.showMonthLabel(item);
    final showSchedule = CartDisplayHelper.showSchedule(item);
    final amount = item.totalAmount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppDecorations.card(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.carMakeModel.toUpperCase(),
                        style: AppTypography.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.carNo,
                        style: AppTypography.dmSans(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        serviceLabel.toUpperCase(),
                        style: AppTypography.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (showMonth) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          CartDisplayHelper.periodLabel(item),
                          style: AppTypography.dmSans(
                            fontSize: 14,
                            color: AppColors.grey700,
                          ),
                        ),
                      ],
                      if (showSchedule &&
                          item.scheduleDate.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: AppTypography.dmSans(
                              fontSize: 13,
                              color: AppColors.grey700,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Schedule Date : ',
                                style: AppTypography.dmSans(
                                  fontSize: 13,
                                  color: AppColors.grey500,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '${item.scheduleDate} ${item.scheduleTime}',
                                style: AppTypography.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const DottedDivider(margin: EdgeInsets.symmetric(vertical: 10)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 120,
                  height: 80,
                  child: _CartVehicleImage(imageUrl: item.carImage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      BillLineRow(
                        label: 'Pack price',
                        amount: CartDisplayHelper.formatRupeeFromString(
                          item.packAmount.isNotEmpty
                              ? item.packAmount
                              : amount,
                        ),
                      ),
                      BillLineRow(
                        label: 'Total',
                        amount: CartDisplayHelper.formatRupeeFromString(amount),
                        amountStyle: AppTypography.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartVehicleImage extends StatelessWidget {
  const _CartVehicleImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/placeholder.png',
        fit: BoxFit.contain,
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/placeholder.png',
        fit: BoxFit.contain,
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: DottedLoader(size: DottedLoaderSize.small),
        );
      },
    );
  }
}
