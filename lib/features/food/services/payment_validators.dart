/// Pure payment validators with zero Flutter imports.
/// Follows docs/ENGINEERING_RULES.md.

/// UPI ID format: ^[\w.\-]{2,}@[\w]{2,}$
bool isValidUpiId(String value) {
  final trimmed = value.trim();
  final regex = RegExp(r'^[\w.\-]{2,}@[\w]{2,}$');
  return regex.hasMatch(trimmed);
}

/// 16 digits after stripping all whitespace.
bool isValidCardNumber(String value) {
  final sanitized = value.replaceAll(RegExp(r'\s+'), '');
  final regex = RegExp(r'^\d{16}$');
  return regex.hasMatch(sanitized);
}

/// Formats a card number string into space-separated groups of 4.
String formatCardNumber(String value) {
  final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
  final buffer = StringBuffer();
  for (var i = 0; i < digitsOnly.length; i++) {
    if (i > 0 && i % 4 == 0) {
      buffer.write(' ');
    }
    buffer.write(digitsOnly[i]);
  }
  return buffer.toString();
}

/// Expiry validation: MM/YY format, MM between 01 and 12, not in the past.
/// The current month of the current year is considered valid.
bool isValidExpiry(String mmYy, DateTime now) {
  final trimmed = mmYy.trim();
  final parts = trimmed.split('/');
  if (parts.length != 2) return false;
  if (parts[0].length != 2) return false;
  if (parts[1].length != 2 && parts[1].length != 4) return false;

  final month = int.tryParse(parts[0]);
  final yearPart = int.tryParse(parts[1]);
  if (month == null || yearPart == null) return false;
  if (month < 1 || month > 12) return false;

  // Normalize 2-digit or 4-digit year
  final fullYear = yearPart < 100 ? 2000 + yearPart : yearPart;

  if (fullYear < now.year) return false;
  if (fullYear == now.year && month < now.month) return false;

  return true;
}

/// CVV: exactly 3 digits.
bool isValidCvv(String value) {
  final trimmed = value.trim();
  return RegExp(r'^\d{3}$').hasMatch(trimmed);
}

/// Cardholder name: between 2 and 40 characters.
bool isValidName(String value) {
  final trimmed = value.trim();
  return trimmed.length >= 2 && trimmed.length <= 40;
}
