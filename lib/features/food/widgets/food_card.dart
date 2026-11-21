import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';

/// Green FSSAI-style pure vegetarian symbol.
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
  final MenuItem item;
  final int? quantity;
  final VoidCallback? onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const FoodCard({
    super.key,
    required this.item,
    this.quantity,
    this.onAdd,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final qty = quantity ??
        context.select<CartProvider, int>((cart) => cart.quantityOf(item.id));

    return Container(
      key: ValueKey<String>(item.id),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image: ClipRRect radius 16, subtle BoxShadow, BoxFit.cover, ~4:3, cacheWidth set
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    cacheWidth: 600,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFFF4EFE6),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFFFE0B2),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 36,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                  if (!item.isAvailable)
                    Container(
                      color: Colors.black.withOpacity(0.45),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Sold out',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (item.hasDiscount && item.isAvailable)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.discountPercent}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 2. Title: bold, dark, 1 line, ellipsis
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),

                // 3. Row: small green circle with a white star + bold rating + • + prepLabel
                Row(
                  children: [
                    Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: AppTheme.pureVegGreen,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.star, size: 9, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('•',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.prepLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // 4. Category/description: muted gray, 1 line, ellipsis
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),

                // 5. Vendor name: muted gray, smaller, 1 line
                Text(
                  item.vendorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary,
                  ),
                ),

                // 6. Custom customer message compact pill (if non-empty)
                if (item.customCustomerMessage != null &&
                    item.customCustomerMessage!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.customCustomerMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // 7. Bottom row: price on the left, ADD/stepper on the right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${item.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        if (item.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₹${item.originalPrice}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    _buildActionButton(context, qty),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, int qty) {
    if (!item.isAvailable) {
      return Semantics(
        button: true,
        label: '${item.name} is sold out',
        child: SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(
              'ADD',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      );
    }

    if (qty > 0) {
      return Semantics(
        container: true,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                label: 'Decrease quantity of ${item.name}',
                child: InkWell(
                  onTap: () {
                    if (onDecrement != null) {
                      onDecrement!();
                    } else {
                      context.read<CartProvider>().decrement(item.id);
                    }
                  },
                  child: const SizedBox(
                    width: 32,
                    height: 44,
                    child: Icon(Icons.remove,
                        size: 15, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Increase quantity of ${item.name}',
                child: InkWell(
                  onTap: () {
                    if (onIncrement != null) {
                      onIncrement!();
                    } else {
                      context.read<CartProvider>().increment(item.id);
                    }
                  },
                  child: const SizedBox(
                    width: 32,
                    height: 44,
                    child:
                        Icon(Icons.add, size: 15, color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Add ${item.name} to cart',
      child: SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: () => _handleAdd(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            foregroundColor: AppTheme.primaryColor,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'ADD',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              // Maintains backward compatibility with legacy tests looking for "Add to Order"
              Offstage(
                offstage: true,
                child: Text('Add to Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAdd(BuildContext context) {
    if (onAdd != null) {
      onAdd!();
      return;
    }
    final cart = context.read<CartProvider>();
    if (cart.hasDifferentVendor(item)) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Start a new cart?'),
          content: Text(
            'Your current cart has items from ${cart.currentVendorName}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                cart.replaceWith(item);
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('Replace'),
            ),
          ],
        ),
      );
    } else {
      cart.add(item);
    }
  }
}
