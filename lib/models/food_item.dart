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

class FoodItem {
  final String id;
  final String name;
  final FoodCategory category;
  final String description;
  final int prepTimeMinutes;
  final double price;
  final String imageUrl;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.prepTimeMinutes,
    required this.price,
    required this.imageUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
