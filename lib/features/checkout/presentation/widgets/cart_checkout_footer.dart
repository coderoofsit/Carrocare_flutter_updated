import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/bill_summary_card.dart';
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
    this.platformFee,
    this.serviceFee,
    this.gstAmount,
    this.gstPercent,
  });

  final int itemCount;
  final int total;
  final VoidCallback onCheckout;
  final bool checkingOut;
  final Widget? consentSection;
  final int? platformFee;
  final int? serviceFee;
  final int? gstAmount;
  final int? gstPercent;

  @override
  Widget build(BuildContext context) {
    final totalText = CartDisplayHelper.formatRupee(total);
    return Material(
      elevation: 0,
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              BillSummaryCard(
                title: 'Order Summary',
                lines: <BillLine>[
                  BillLine(label: 'Items ($itemCount)', amount: totalText),
                  if (platformFee != null && platformFee! > 0)
                    BillLine(
                      label: 'Platform fee',
                      amount: CartDisplayHelper.formatRupee(platformFee!),
                    ),
                  if (serviceFee != null && serviceFee! > 0)
                    BillLine(
                      label: 'Service provider charges',
                      amount: CartDisplayHelper.formatRupee(serviceFee!),
                      muted: true,
                    ),
                  if (gstAmount != null && gstAmount! > 0)
                    BillLine(
                      label: 'GST (${gstPercent ?? 18}% on platform fee)',
                      amount: CartDisplayHelper.formatRupee(gstAmount!),
                      muted: true,
                    ),
                ],
                totalLabel: 'Total',
                totalAmount: totalText,
                padding: const EdgeInsets.all(14),
              ),
              if (consentSection != null) ...<Widget>[
                const SizedBox(height: 10),
                consentSection!,
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: checkingOut ? null : onCheckout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDecorations.buttonRadius),
                    ),
                  ),
                  child: checkingOut
                      ? const SizedBox(
                          height: 22,
                          width: 80,
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '$itemCount Items  $totalText',
                              style: AppTypography.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Checkout',
                              style: AppTypography.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Image.asset(
                              'assets/images/checkout.png',
                              width: 22,
                              height: 22,
                              color: AppColors.white,
                              colorBlendMode: BlendMode.srcIn,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.arrow_forward,
                                color: AppColors.white,
                                size: 20,
                              ),
                            ),
                          ],
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
