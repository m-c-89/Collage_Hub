import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/core/utils/money.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/domain/cart_pricing.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/providers/checkout_provider.dart';
import 'package:college_canteen/features/food/screens/order_tracking_screen.dart';
import 'package:college_canteen/features/food/screens/qr_scanner_screen.dart';
import 'package:college_canteen/features/food/widgets/location_search_field.dart';
import 'package:college_canteen/features/food/widgets/pricing_summary_card.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CheckoutProvider>().resetLocation();
      }
    });
  }

  Future<void> _sendOrderRequest(int displayedGrandTotal) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();
    final profile = context.read<ProfileProvider>();
    final orderRepo = context.read<OrderRepository>();

    final selectedLoc = checkout.selectedLocation;
    if (selectedLoc == null || cart.items.isEmpty) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final customerId = profile.profile?.id ??
        profile.profile?.mobileNumber ??
        profile.profile?.fullName ??
        'guest';
    final vendorId = cart.currentVendorId ?? AppConfig.defaultVendorId;
    final lines = cart.items.map((i) => (i.item.id, i.quantity)).toList();
    final clientRequestId =
        'REQ-${DateTime.now().millisecondsSinceEpoch}-${1000 + Random().nextInt(9000)}';

    final request = PlaceOrderRequest(
      clientRequestId: clientRequestId,
      customerId: customerId,
      vendorId: vendorId,
      lines: lines,
      locationId: selectedLoc.id,
      expectedTotal: displayedGrandTotal,
    );

    try {
      final placedOrder = await orderRepo.placeOrder(request);
      if (!mounted) return;

      cart.clear();
      checkout.resetLocation();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(initialOrderId: placedOrder.id),
        ),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request sent. Waiting for ${placedOrder.vendorName} to confirm the preparation time.',
          ),
        ),
      );
    } on PriceChangedException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Prices changed'),
          content: Text(
            'Prices changed. New total ${formatRupees(e.newTotal)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        _sendOrderRequest(e.newTotal);
      }
    } on OrderValidationException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Could not place order request. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final selectedLoc = checkout.selectedLocation;

    final pricing = CartPricing.compute(
      subtotal: cart.subtotal,
      itemCount: cart.totalQuantity,
      location: selectedLoc,
    );

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
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Delivery Location Card with LocationSearchField
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
                            Icon(Icons.location_on,
                                size: 20, color: AppTheme.primaryColor),
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
                        LocationSearchField(
                          selectedLocation: selectedLoc,
                          onLocationChanged: (loc) {
                            checkout.selectLocation(loc);
                          },
                          onScanTap: () async {
                            final loc = await Navigator.of(context)
                                .push<DeliveryLocation>(
                              MaterialPageRoute(
                                builder: (_) => const QrScannerScreen(),
                              ),
                            );
                            if (loc != null && mounted) {
                              checkout.selectLocation(loc);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Location set: ${loc.address}'),
                                ),
                              );
                            }
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
                            Icon(Icons.badge_outlined,
                                size: 18, color: AppTheme.primaryColor),
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

                // 3. Pricing Summary Card
                const PricingSummaryCard(),

                const SizedBox(height: 20),

                // 4. Send Order Request Button
                ElevatedButton(
                  onPressed: (pricing.canCheckout && !_isSubmitting)
                      ? () => _sendOrderRequest(pricing.grandTotal)
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
                    elevation: pricing.canCheckout ? 1 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Send Order Request',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pricing.canCheckout
                            ? formatRupees(pricing.grandTotal)
                            : '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),

                // Helper banner when canCheckout is false
                if (!pricing.canCheckout) ...[
                  const SizedBox(height: 8),
                  Text(
                    pricing.banner == CartBanner.minOrder
                        ? 'Add ${formatRupees(pricing.shortfall)} more to meet the minimum.'
                        : 'Select a delivery location to continue.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
