import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/features/food/data/menu_data.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/widgets/category_filter_bar.dart';
import 'package:college_canteen/features/food/widgets/food_card.dart';
import 'package:college_canteen/features/food/screens/cart_screen.dart';
import 'package:college_canteen/features/food/screens/checkout_screen.dart';
import 'package:college_canteen/features/profile/profile_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';

  List<FoodItem> get _filteredItems {
    if (_selectedCategory == 'All') {
      return canteenMenuItems;
    }
    return canteenMenuItems
        .where((item) => item.category.displayName == _selectedCategory)
        .toList();
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'College Canteen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            // 100% Pure Veg leaf badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.pureVegLightGreen,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.pureVegGreen,
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco,
                    size: 11,
                    color: AppTheme.pureVegGreen,
                  ),
                  SizedBox(width: 3),
                  Text(
                    '100% Pure Veg',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.pureVegGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Live Cart Badge Icon
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Badge(
                isLabelVisible: cart.totalQuantity > 0,
                backgroundColor: AppTheme.primaryColor,
                label: Text(
                  '${cart.totalQuantity}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                offset: const Offset(-4, 4),
                child: IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  tooltip: 'Cart (${cart.totalQuantity} items)',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Profile Icon (opens pre-filled profile to edit details)
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(isMandatory: false),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTheme.maxContentWidth,
          ),
          child: Column(
            children: [
              // Horizontally scrollable ChoiceChip bar directly below AppBar
              CategoryFilterBar(
                selectedCategory: _selectedCategory,
                onSelected: _onCategorySelected,
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFEDE8E0)),

              // AnimatedSwitcher for instant list filtering
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: ListView.builder(
                        key: ValueKey<String>(_selectedCategory),
                        padding: const EdgeInsets.only(top: 8, bottom: 90),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final qty = cart.quantityOf(item.id);

                          return FoodCard(
                            item: item,
                            quantity: qty,
                            onAdd: () => cart.add(item),
                            onIncrement: () => cart.increment(item.id),
                            onDecrement: () => cart.decrement(item.id),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Sticky Bottom Bar when cart is not empty
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.totalQuantity == 0) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.maxContentWidth,
                ),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.pureVegGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Subtotal info
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.totalQuantity} ${cart.totalQuantity == 1 ? 'item' : 'items'} | ₹${cart.subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Pure veg canteen order',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Proceed to Order Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.pureVegGreen,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Proceed to Order',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
