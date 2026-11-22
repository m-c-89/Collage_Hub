abstract final class DeliveryValidators {
  static final RegExp _phoneRegExp = RegExp(r'^[6-9]\d{9}$');

  static String? validatePartnerName(String? name) {
    if (name == null) {
      return 'Name is required';
    }
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 40) {
      return 'Name must be between 2 and 40 characters';
    }
    return null;
  }

  static String? validatePartnerPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }
    final trimmed = phone.trim();
    if (!_phoneRegExp.hasMatch(trimmed)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }
}

String? validatePartnerName(String? name) =>
    DeliveryValidators.validatePartnerName(name);

String? validatePartnerPhone(String? phone) =>
    DeliveryValidators.validatePartnerPhone(phone);
