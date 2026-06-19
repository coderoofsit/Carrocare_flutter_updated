import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int minPauseDays = 7;
const int maxPauseDays = 90;

Future<int?> showPauseSubscriptionDialog(
  BuildContext context, {
  bool isUpiAutopay = false,
}) {
  final controller = TextEditingController(text: minPauseDays.toString());
  return showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Pause subscription',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose between $minPauseDays and $maxPauseDays days.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.black.withValues(alpha: 0.7),
                ),
              ),
              if (isUpiAutopay) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Text(
                    'UPI autopay note: Your UPI mandate will pause and no debits '
                    'will happen during this period. Your Carro Care validity will '
                    'be extended for the days you select. Razorpay does not adjust '
                    'UPI debit dates — your app will use the extended service date.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Pause days ($minPauseDays–$maxPauseDays)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final pauseDays = int.tryParse(controller.text.trim());
                        if (pauseDays == null ||
                            pauseDays < minPauseDays ||
                            pauseDays > maxPauseDays) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Enter a value between $minPauseDays and $maxPauseDays days.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop(pauseDays);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
