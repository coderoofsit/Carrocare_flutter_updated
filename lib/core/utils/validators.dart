class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[_A-Za-z0-9-]+(\.[_A-Za-z0-9-]+)*@[A-Za-z0-9]+(\.[A-Za-z0-9]+)*(\.[A-Za-z]{2,})$',
  );

  static bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

  static bool isValidMobile(String mobile) {
    final trimmed = mobile.trim();
    return trimmed.length == 10 && RegExp(r'^\d{10}$').hasMatch(trimmed);
  }
}
