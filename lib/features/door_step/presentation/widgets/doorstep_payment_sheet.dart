import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:flutter/material.dart';

enum DoorstepPaymentMethod { cod, online }

Future<DoorstepPaymentMethod?> showDoorstepPaymentSheet({
  required BuildContext context,
  required String serviceLabel,
  required int totalAmount,
}) async {
  return showModalBottomSheet<DoorstepPaymentMethod>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          color: AppColors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Choose Payment Method',
                    style: AppTypography.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    serviceLabel,
                    style: AppTypography.dmSans(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${CheckoutPricing.rupee(totalAmount)}',
                    style: AppTypography.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PaymentOptionTile(
                    icon: Icons.payments_outlined,
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when the service is completed',
                    onTap: () =>
                        Navigator.pop(sheetContext, DoorstepPaymentMethod.cod),
                  ),
                  const SizedBox(height: 12),
                  _PaymentOptionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Pay Online',
                    subtitle: 'UPI, card, or net banking via Razorpay',
                    onTap: () => Navigator.pop(
                      sheetContext,
                      DoorstepPaymentMethod.online,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey600),
          ],
        ),
      ),
    );
  }
}
