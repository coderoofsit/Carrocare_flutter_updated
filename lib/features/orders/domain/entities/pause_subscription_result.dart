class PauseSubscriptionResult {
  const PauseSubscriptionResult({
    required this.message,
    this.resumeAt,
    this.nextDue,
    this.warning,
  });

  final String message;
  final String? resumeAt;
  final String? nextDue;
  final String? warning;
}
