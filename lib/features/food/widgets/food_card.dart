import 'package:flutter/material.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/widgets/quantity_selector.dart';

/// Green FSSAI-style pure vegetarian symbol:
/// Square outline with a filled green circle in the center.
class VegSymbol extends StatelessWidget {
  final double size;

  const VegSymbol({super.key, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    const greenColor = AppTheme.pureVegGreen;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: greenColor, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.44,
        height: size * 0.44,
        decoration: const BoxDecoration(
          color: greenColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class FoodCard extends StatelessWidget {
  final FoodItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const FoodCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: const BorderSide(color: Color(0xFFF0EBE1), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image with ClipRRect, loadingBuilder, and errorBuilder fallback
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.cardBorderRadius),
            ),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFFF4EFE6),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFFFE0B2), // Coloured fallback box
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 46,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(height: 6),
                          Text(
                            '100% Pure Veg',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Details & Action Section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Veg Symbol + Bold Name + Category Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: VegSymbol(size: 16),
                    ),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Description (max 3 lines, ellipsis)
                Text(
                  item.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Row 3: Price in ₹ & Prep Time + Add/Quantity Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 13,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '⏱ ${item.prepTimeMinutes} min',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    QuantitySelector(
                      quantity: quantity,
                      onAdd: onAdd,
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
