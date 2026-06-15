/// Parses [validate_checkout.php] messages into distinct block reasons.
class CheckoutBlockReason {
  const CheckoutBlockReason({
    this.blockMonthlyDueToOneTime = false,
    this.blockOneTimeDueToMonthly = false,
    this.monthlyMessage = '',
    this.oneTimeMessage = '',
  });

  final bool blockMonthlyDueToOneTime;
  final bool blockOneTimeDueToMonthly;
  final String monthlyMessage;
  final String oneTimeMessage;

  static const String oneTimeBlocksMonthlyPhrase = 'one-time plan is already active';
  static const String monthlyBlocksOneTimePhrase =
      'monthly subscription already exists';
  static const String monthlyBlocksOneTimeFallback =
      'An active monthly subscription already exists for this vehicle. '
      'Cancel it in My Orders before making a one-time purchase.';

  static CheckoutBlockReason fromValidations({
    required String monthlyValidation,
    required String oneTimeValidation,
  }) {
    final monthlyLower = monthlyValidation.toLowerCase();
    final blockMonthlyDueToOneTime =
        monthlyLower.contains(oneTimeBlocksMonthlyPhrase);
    final monthlyDuplicate =
        monthlyLower.contains(monthlyBlocksOneTimePhrase);
    final blockOneTimeDueToMonthly =
        oneTimeValidation.isNotEmpty || monthlyDuplicate;

    var oneTimeMessage = oneTimeValidation;
    if (oneTimeMessage.isEmpty && blockOneTimeDueToMonthly) {
      oneTimeMessage = monthlyDuplicate
          ? monthlyBlocksOneTimeFallback
          : oneTimeValidation;
    }

    return CheckoutBlockReason(
      blockMonthlyDueToOneTime: blockMonthlyDueToOneTime,
      blockOneTimeDueToMonthly: blockOneTimeDueToMonthly,
      monthlyMessage: monthlyValidation,
      oneTimeMessage: oneTimeMessage,
    );
  }
}
