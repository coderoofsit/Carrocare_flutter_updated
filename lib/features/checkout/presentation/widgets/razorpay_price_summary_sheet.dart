import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:flutter/material.dart';

/// In-app price breakdown shown immediately before Razorpay opens.
Future<bool> showRazorpayPriceSummarySheet({
  required BuildContext context,
  required RazorpayPriceSummary summary,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Payment summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.serviceLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                  const Divider(height: 24),
                  _summaryRow(
                    'Subtotal',
                    CheckoutPricing.rupee(summary.subTotal),
                  ),
                  if (summary.gstPercent > 0 && summary.gstAmount > 0)
                    _summaryRow(
                      'GST (${summary.gstPercent}%)',
                      CheckoutPricing.rupee(summary.gstAmount),
                    ),
                  const Divider(height: 16),
                  _summaryRow(
                    'Total payable',
                    CheckoutPricing.rupee(summary.total),
                    bold: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                          child: const Text('Pay with Razorpay'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

Widget _summaryRow(String label, String value, {bool bold = false}) {
  final style = TextStyle(
    fontSize: 15,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    color: AppColors.black,
  );
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: style),
        Text(value, style: style),
      ],
    ),
  );
}
