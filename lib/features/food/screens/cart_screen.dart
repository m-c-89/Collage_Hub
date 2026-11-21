import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/widgets/food_card.dart';
import 'package:college_canteen/features/food/screens/checkout_screen.dart';
import 'package:college_canteen/features/profile/profile_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final isEmpty = cart.items.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Your Cart',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              if (!isEmpty)
                TextButton.icon(
                  onPressed: () {
                    _showClearConfirmation(context, cart);
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: isEmpty
              ? _buildEmptyState(context)
              : _buildCartList(context, cart),
          bottomNavigationBar: isEmpty
              ? null
              : _buildBottomSummaryBar(context, cart),
        );
      },
    );
  }

  /// Empty state when cart has no items
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppTheme.maxContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large cart icon inside soft circular badge
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 56,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explore our 100% vegetarian snacks, meals, beverages & desserts to add your favorite items.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              // Browse Menu button that pops back to the menu
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.restaurant_menu, size: 18),
                label: const Text(
                  'Browse Menu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// List of items in the cart with line total, (− qty +), and swipe/icon remove
  Widget _buildCartList(BuildContext context, CartProvider cart) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppTheme.maxContentWidth,
        ),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: cart.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final cartItem = cart.items[index];
            final food = cartItem.item;
            final lineTotal = food.price * cartItem.quantity;

            return Dismissible(
              key: ValueKey<String>('cart_dismissible_${food.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.delete_outline, color: Colors.white, size: 22),
                  ],
                ),
              ),
              onDismissed: (_) {
                cart.remove(food.id);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${food.name} removed from cart'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppTheme.primaryLight,
                      onPressed: () {
                        for (var i = 0; i < cartItem.quantity; i++) {
                          cart.add(food);
                        }
                      },
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 1,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFF0EBE1), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Food thumbnail inside ClipRRect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 58,
                          height: 58,
                          child: Image.network(
                            food.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFFFE0B2),
                              child: const Icon(
                                Icons.restaurant,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Food Details: Veg symbol, Name, Unit price, and Line Total
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const VegSymbol(size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    food.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '₹${food.price.toStringAsFixed(0)} each',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('•', style: TextStyle(color: Colors.black26)),
                                const SizedBox(width: 8),
                                Text(
                                  'Line Total: ₹${lineTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // (− qty +) Counter
                      _buildInlineCounter(context, cart, food.id, cartItem.quantity),

                      // Remove icon button
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red.shade400,
                        ),
                        tooltip: 'Remove',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          cart.remove(food.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Compact inline (− qty +) selector for cart item row
  Widget _buildInlineCounter(
    BuildContext context,
    CartProvider cart,
    String id,
    int quantity,
  ) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          InkWell(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            onTap: () => cart.decrement(id),
            child: const SizedBox(
              width: 28,
              height: 32,
              child: Icon(Icons.remove, size: 14, color: AppTheme.primaryColor),
            ),
          ),

          // Quantity text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          // Increment button
          InkWell(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
            onTap: () => cart.increment(id),
            child: const SizedBox(
              width: 28,
              height: 32,
              child: Icon(Icons.add, size: 14, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky Bottom Bar with "Base Food Price" subtotal and "Proceed to Order" button
  Widget _buildBottomSummaryBar(BuildContext context, CartProvider cart) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTheme.maxContentWidth,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0EBE1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subtotal / Base Food Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Base Food Price',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${cart.totalQuantity} ${cart.totalQuantity == 1 ? 'item' : 'items'} in order',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${cart.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Proceed to Order button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final hasProfile =
                          context.read<ProfileProvider>().hasProfile;
                      if (!hasProfile) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProfileScreen(isMandatory: true),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Proceed to Order',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text(
          'Are you sure you want to remove all items from your canteen cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () {
              cart.clear();
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
