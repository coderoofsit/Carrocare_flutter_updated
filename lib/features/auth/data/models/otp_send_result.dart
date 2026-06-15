class OtpSendResult {
  const OtpSendResult({required this.otp, this.message});

  /// OTP value when the API includes it (dev/staging). Empty on production APIs
  /// that only SMS the code and return `"OTP sent..."` in [message].
  final String otp;
  final String? message;

  bool get hasServerOtp => otp.isNotEmpty;
}
