import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/bill_summary_card.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:flutter/material.dart';

/// In-app price breakdown shown immediately before Razorpay opens.
Future<bool> showRazorpayPriceSummarySheet({
  required BuildContext context,
  required RazorpayPriceSummary summary,
  Future<void> Function()? onConfirmPay,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _RazorpayPriceSummarySheet(
        summary: summary,
        onConfirmPay: onConfirmPay,
      );
    },
  );
  return result ?? false;
}

class _RazorpayPriceSummarySheet extends StatefulWidget {
  const _RazorpayPriceSummarySheet({
    required this.summary,
    this.onConfirmPay,
  });

  final RazorpayPriceSummary summary;
  final Future<void> Function()? onConfirmPay;

  @override
  State<_RazorpayPriceSummarySheet> createState() =>
      _RazorpayPriceSummarySheetState();
}

class _RazorpayPriceSummarySheetState
    extends State<_RazorpayPriceSummarySheet> {
  bool _processing = false;

  Future<void> _onPayPressed() async {
    if (_processing) return;

    final onConfirmPay = widget.onConfirmPay;
    if (onConfirmPay == null) {
      Navigator.pop(context, true);
      return;
    }

    setState(() => _processing = true);
    try {
      await onConfirmPay();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Timeout')
                ? 'Timeout.Try after sometime'
                : e.toString(),
          ),
        ),
      );
    }
  }

  List<BillLine> get _lines {
    final lines = <BillLine>[
      BillLine(
        label: 'Subtotal',
        amount: CheckoutPricing.rupee(widget.summary.subTotal),
      ),
    ];
    if (widget.summary.gstPercent > 0 && widget.summary.gstAmount > 0) {
      lines.add(
        BillLine(
          label: 'GST (${widget.summary.gstPercent}%)',
          amount: CheckoutPricing.rupee(widget.summary.gstAmount),
          muted: true,
        ),
      );
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
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
                  'Payment Summary',
                  style: AppTypography.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.summary.serviceLabel,
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 16),
                BillSummaryCard(
                  title: 'Charges',
                  lines: _lines,
                  totalLabel: 'Total Payable',
                  totalAmount: CheckoutPricing.rupee(widget.summary.total),
                  padding: const EdgeInsets.all(14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processing ? null : _onPayPressed,
                    child: _processing
                        ? const DottedLoader(
                            size: DottedLoaderSize.small,
                            color: AppColors.white,
                          )
                        : Text(
                            'Pay with Razorpay',
                            style: AppTypography.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _processing
                        ? null
                        : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDecorations.buttonRadius),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
