import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/locations_data.dart';
import '../models/campus_location.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bill_summary.dart';
import '../widgets/order_confirmation_dialog.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    // Every time the screen opens, RESET selected location to null.
    // Nothing is preselected, even for repeat orders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CheckoutProvider>().resetLocation();
      }
    });
  }

  Future<void> _handleConfirmOrder() async {
    if (_isConfirming) return; // Prevent double taps

    final checkoutProvider = context.read<CheckoutProvider>();
    final cartProvider = context.read<CartProvider>();
    final profileProvider = context.read<ProfileProvider>();

    final selectedLocation = checkoutProvider.selectedLocation;
    if (selectedLocation == null || cartProvider.items.isEmpty) return;

    setState(() {
      _isConfirming = true;
    });

    // 1-second simulated payment / order processing loading indicator
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isConfirming = false;
    });

    final orderId = 'ORD-${4000 + Random().nextInt(5000)}';
    final totalAmount = checkoutProvider.calculateTotalAmount(
      cartProvider.items,
      selectedLocation,
    );

    // Show Order Confirmation Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => OrderConfirmationDialog(
        orderId: orderId,
        profile: profileProvider.profile,
        location: selectedLocation,
        items: List.from(cartProvider.items),
        totalAmount: totalAmount,
        onDone: () {
          // The "Done" button clears the cart, resets the location, KEEPS profile, and returns to menu.
          cartProvider.clear();
          checkoutProvider.resetLocation();
          Navigator.of(dialogCtx).pop(); // Dismiss dialog
          Navigator.of(context).popUntil((route) => route.isFirst); // Back to menu
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final selectedLoc = checkout.selectedLocation;
    final isLocationChosen = selectedLoc != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTheme.maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Delivery Location Selection Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFF0EBE1), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delivery Location',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Dropdown with hint "Select your delivery spot"
                        DropdownButtonFormField<CampusLocation>(
                          value: selectedLoc,
                          isExpanded: true,
                          hint: const Text(
                            'Select your delivery spot',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          // Zone 1 first, then Zone 2
                          items: campusLocations.map((loc) {
                            final isZone1 = loc.zone == DeliveryZone.zone1;
                            final tagBg = isZone1
                                ? const Color(0xFFFFE0B2) // Warm orange tag
                                : const Color(0xFFE8F5E9); // Fresh green tag
                            final tagColor = isZone1
                                ? AppTheme.primaryColor
                                : AppTheme.pureVegGreen;

                            return DropdownMenuItem<CampusLocation>(
                              value: loc,
                              child: Row(
                                children: [
                                  // Coloured zone tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tagBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      loc.zone.name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: tagColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Location name and fee
                                  Expanded(
                                    child: Text(
                                      '${loc.name} • ${loc.zone.name} • +₹${loc.chargePerItem.toInt()}/item',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (loc) {
                            checkout.selectLocation(loc);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Customer Summary Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFF0EBE1), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Recipient Information',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: Color(0xFFF0EBE1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              profile?.fullName ?? 'Student',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              profile != null
                                  ? '+91 ${profile.mobileNumber}'
                                  : 'No mobile provided',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Live Bill Summary
                BillSummary(
                  items: cart.items,
                  location: selectedLoc,
                ),

                const SizedBox(height: 20),

                // 4. Payment method note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEBE6DC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.payment, size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment: Pay cash/UPI on delivery',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Confirm Order Button
                ElevatedButton(
                  onPressed: isLocationChosen && !_isConfirming
                      ? _handleConfirmOrder
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: isLocationChosen ? 1 : 0,
                  ),
                  child: _isConfirming
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirm Order',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.check_circle_outline, size: 18),
                          ],
                        ),
                ),

                // Helper text when location is not chosen
                if (!isLocationChosen) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Please select a delivery location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
