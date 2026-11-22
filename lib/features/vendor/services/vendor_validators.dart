import 'package:college_canteen/features/vendor/models/vendor_profile.dart';

String? validateBusinessName(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.length < 2 || trimmed.length > 40) {
    return 'Business name must be between 2 and 40 characters';
  }
  return null;
}

String? validatePhone(String? phone) {
  final trimmed = phone?.trim() ?? '';
  final regex = RegExp(r'^[6-9]\d{9}$');
  if (!regex.hasMatch(trimmed)) {
    return 'Enter a valid 10-digit mobile number starting with 6-9';
  }
  return null;
}

String? validateFssai(String? value, BusinessType type) {
  final trimmed = value?.trim() ?? '';
  final digit14Regex = RegExp(r'^\d{14}$');
  if (type.fssaiRequired) {
    if (trimmed.isEmpty) {
      return 'FSSAI number is required for ${type.label}';
    }
    if (!digit14Regex.hasMatch(trimmed)) {
      return 'FSSAI number must be exactly 14 digits';
    }
    return null;
  } else {
    if (trimmed.isEmpty) {
      return null;
    }
    if (!digit14Regex.hasMatch(trimmed)) {
      return 'FSSAI number must be exactly 14 digits';
    }
    return null;
  }
}

String? validateItemName(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.length < 2 || trimmed.length > 40) {
    return 'Item name must be between 2 and 40 characters';
  }
  return null;
}

String? validatePrice(int? price) {
  if (price == null || price < 1 || price > 10000) {
    return 'Price must be between ₹1 and ₹10,000';
  }
  return null;
}

String? validateDiscount({
  required int originalPrice,
  required int discountedPrice,
}) {
  if (discountedPrice < 1 || discountedPrice >= originalPrice) {
    return 'Discounted price must be at least ₹1 and less than original price';
  }
  return null;
}

String? validateCustomMessage(String? message) {
  if (message == null || message.isEmpty) {
    return null;
  }
  if (message.length > 60) {
    return 'Custom message cannot exceed 60 characters';
  }
  return null;
}

String? validatePrep({required int min, required int max}) {
  if (min < 1 || min > max || max > 180) {
    return 'Preparation time must be between 1 and 180 minutes, with min <= max';
  }
  return null;
}
