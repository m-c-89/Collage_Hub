import 'package:college_canteen/core/config/app_config.dart';

enum ItemModule { food, stationery }

enum FoodCategory {
  snacks('Snacks'),
  meals('Meals'),
  beverages('Beverages'),
  desserts('Desserts');

  final String displayName;
  const FoodCategory(this.displayName);

  static FoodCategory? fromString(String categoryName) {
    for (final cat in FoodCategory.values) {
      if (cat.displayName.toLowerCase() == categoryName.toLowerCase()) {
        return cat;
      }
    }
    return null;
  }
}

class MenuItem {
  final String _id;
  final String name;
  final FoodCategory category;
  final String description;
  final String vendorId;
  final String vendorName;
  final int price;
  final int? originalPrice;
  final double rating;
  final int ratingCount;
  final int prepMinMinutes;
  final int prepMaxMinutes;
  final bool isAvailable;
  final String? customCustomerMessage;
  final ItemModule module;
  final String imageUrl;

  const MenuItem({
    String? id,
    required this.name,
    this.category = FoodCategory.snacks,
    this.description = '',
    this.vendorId = AppConfig.defaultVendorId,
    this.vendorName = AppConfig.defaultVendorName,
    required this.price,
    this.originalPrice,
    this.rating = 4.5,
    this.ratingCount = 50,
    this.prepMinMinutes = 5,
    this.prepMaxMinutes = 10,
    this.isAvailable = true,
    this.customCustomerMessage,
    this.module = ItemModule.food,
    this.imageUrl = '',
    int? prepTimeMinutes,
  })  : _id = id ?? '',
        super();

  /// Stable ID. If not explicitly provided, derived as a slug from [name].
  String get id => _id.isNotEmpty ? _id : _deriveSlug(name);

  /// Backward-compatible prep time in minutes.
  int get prepTimeMinutes => prepMinMinutes;

  /// Formatted prep duration, e.g. "20-25 mins" or "10 mins".
  String get prepLabel {
    if (prepMinMinutes == prepMaxMinutes) {
      return '$prepMinMinutes mins';
    }
    return '$prepMinMinutes-$prepMaxMinutes mins';
  }

  /// True when an original price exists and exceeds the current price.
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  /// Percentage discount rounded to nearest integer; 0 if no discount.
  int get discountPercent {
    if (!hasDiscount || originalPrice == null || originalPrice! <= 0) {
      return 0;
    }
    return (((originalPrice! - price) * 100) / originalPrice!).round();
  }

  static String _deriveSlug(String input) {
    final buffer = StringBuffer();
    var prevIsHyphen = false;
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final isAlphaNum =
          (rune >= 97 && rune <= 122) || (rune >= 48 && rune <= 57);
      if (isAlphaNum) {
        buffer.write(char);
        prevIsHyphen = false;
      } else if (!prevIsHyphen && buffer.isNotEmpty) {
        buffer.write('-');
        prevIsHyphen = true;
      }
    }
    final result = buffer.toString();
    return result.endsWith('-')
        ? result.substring(0, result.length - 1)
        : result;
  }

  MenuItem copyWith({
    String? id,
    String? name,
    FoodCategory? category,
    String? description,
    String? vendorId,
    String? vendorName,
    int? price,
    int? originalPrice,
    double? rating,
    int? ratingCount,
    int? prepMinMinutes,
    int? prepMaxMinutes,
    bool? isAvailable,
    String? customCustomerMessage,
    ItemModule? module,
    String? imageUrl,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      prepMinMinutes: prepMinMinutes ?? this.prepMinMinutes,
      prepMaxMinutes: prepMaxMinutes ?? this.prepMaxMinutes,
      isAvailable: isAvailable ?? this.isAvailable,
      customCustomerMessage:
          customCustomerMessage ?? this.customCustomerMessage,
      module: module ?? this.module,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Backward compatibility alias for existing code referencing [FoodItem].
typedef FoodItem = MenuItem;
