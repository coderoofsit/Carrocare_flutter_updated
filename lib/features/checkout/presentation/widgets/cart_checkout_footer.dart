import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/checkout/core/cart_display_helper.dart';
import 'package:flutter/material.dart';

/// Matches Android `activity_cart.xml` bottom `lyttotal` section.
class CartCheckoutFooter extends StatelessWidget {
  const CartCheckoutFooter({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onCheckout,
    this.checkingOut = false,
    this.consentSection,
  });

  final int itemCount;
  final int total;
  final VoidCallback onCheckout;
  final bool checkingOut;
  final Widget? consentSection;

  @override
  Widget build(BuildContext context) {
    final totalText = CartDisplayHelper.formatRupee(total);
    return Material(
      elevation: 8,
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Subtotal',
                      style: TextStyle(fontSize: 12, color: AppColors.black),
                    ),
                  ),
                  Text(
                    totalText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Text(
                    totalText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              if (consentSection != null) ...<Widget>[
                const SizedBox(height: 8),
                consentSection!,
              ],
              const SizedBox(height: 8),
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(5),
                child: InkWell(
                  onTap: checkingOut ? null : onCheckout,
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 10,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '$itemCount Items  $totalText',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Text(
                          'Checkout',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/images/checkout.png',
                          width: 24,
                          height: 24,
                          color: AppColors.white,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.logout,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
