import 'dart:convert';

/// Helpers for OTP values returned by Carrocare APIs (`OTP` JSON field).
class OtpUtils {
  /// Reads OTP from API response (`OTP`, `otp`, etc.) as a normalized string.
  static String? parseFromResponse(Map<String, dynamic> data) {
    final dynamic raw = data['OTP'] ??
        data['otp'] ??
        data['Otp'] ??
        data['sign_up_otp'] ??
        data['forgot_pass_otp'];
    if (raw == null) return null;

    if (raw is int) return raw.toString();
    if (raw is double) return raw.toInt().toString();

    final normalized = raw.toString().trim();
    if (normalized.isEmpty) return null;

    final decoded = _decodeBase64Otp(normalized);
    if (decoded != null) return decoded;

    final asInt = int.tryParse(normalized);
    if (asInt != null) return asInt.toString();

    return normalized;
  }

  static String? _decodeBase64Otp(String value) {
    try {
      final decoded = utf8.decode(base64.decode(value));
      final trimmed = decoded.trim();
      if (trimmed.isEmpty) return null;
      final asInt = int.tryParse(trimmed);
      return asInt?.toString() ?? trimmed;
    } catch (_) {
      return null;
    }
  }

  /// User-entered OTP shape (Carrocare sends 5-digit codes).
  static bool isValidFormat(String entered) {
    final value = entered.trim();
    return RegExp(r'^\d{4,6}$').hasMatch(value);
  }

  /// Compares user input with server OTP (trim + numeric normalization).
  static bool matches(String entered, String expected) {
    final a = entered.trim();
    final b = expected.trim();
    if (a.isEmpty || b.isEmpty) return false;

    final aNum = int.tryParse(a);
    final bNum = int.tryParse(b);
    if (aNum != null && bNum != null) return aNum == bNum;

    return a == b;
  }

  /// True when OTP can be accepted on the verify step.
  static bool verify(String entered, String serverOtp) {
    if (serverOtp.isNotEmpty) {
      return matches(entered, serverOtp);
    }
    return isValidFormat(entered);
  }
}
