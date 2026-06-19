import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Consent UI for optional auto-renewal at checkout (parity with native cart).
class AutopayConsentPanel extends StatelessWidget {
  const AutopayConsentPanel({
    super.key,
    required this.enableAutopay,
    required this.acceptedTerms,
    required this.onAutopayChanged,
    required this.onTermsChanged,
    this.renewalAmount,
    this.showAutopayToggle = true,
  });

  final bool enableAutopay;
  final bool acceptedTerms;
  final ValueChanged<bool> onAutopayChanged;
  final ValueChanged<bool> onTermsChanged;
  final String? renewalAmount;
  final bool showAutopayToggle;

  static String get termsUrl => AppUrls.termsAndConditions;

  @override
  Widget build(BuildContext context) {
    final amountHint = renewalAmount != null && renewalAmount!.isNotEmpty
        ? ' We will charge $renewalAmount on your renewal date.'
        : ' We will charge the same plan amount on your renewal date.';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showAutopayToggle)
              CheckboxListTile(
                value: enableAutopay,
                onChanged: (value) => onAutopayChanged(value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Enable autopay',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.black,
                  ),
                ),
                subtitle: Text(
                  'Renew automatically when your subscription ends.$amountHint',
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            if (!showAutopayToggle)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(
                  'Monthly subscriptions renew automatically each billing cycle.$amountHint',
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            CheckboxListTile(
              value: acceptedTerms,
              onChanged: (value) => onTermsChanged(value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.black,
                  ),
                  children: <TextSpan>[
                    const TextSpan(text: 'I accept the '),
                    TextSpan(
                      text: 'terms and conditions',
                      style: const TextStyle(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                              Uri.parse(termsUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
