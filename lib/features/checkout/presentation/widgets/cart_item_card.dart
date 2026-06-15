import 'package:carrocare_flutter/core/theme/app_colors.dart';
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.carMakeModel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.carNo,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          serviceLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (showMonth) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            CartDisplayHelper.periodLabel(item),
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                        if (showSchedule &&
                            item.scheduleDate.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Schedule Date : ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${item.scheduleDate} ${item.scheduleTime}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete,
                    color: AppColors.primary,
                    size: 25,
                  ),
                  padding: const EdgeInsets.all(5),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 150,
                  height: 100,
                  child: _CartVehicleImage(imageUrl: item.carImage),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: <Widget>[
                        _PriceRow(
                          label: 'Pack price :',
                          value: CartDisplayHelper.formatRupeeFromString(
                            item.packAmount.isNotEmpty
                                ? item.packAmount
                                : amount,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _PriceRow(
                          label: 'Total :',
                          value: CartDisplayHelper.formatRupeeFromString(amount),
                          bold: true,
                        ),
                      ],
                    ),
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
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 18,
      color: bold ? AppColors.black : Colors.grey.shade700,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
