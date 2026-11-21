import 'package:flutter/material.dart';
import 'package:college_canteen/features/food/models/campus_location.dart';
import 'package:college_canteen/features/food/models/cart_item.dart';
import 'package:college_canteen/features/profile/customer_profile.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/widgets/food_card.dart';

class OrderConfirmationDialog extends StatelessWidget {
  final String orderId;
  final CustomerProfile? profile;
  final CampusLocation location;
  final List<CartItem> items;
  final double totalAmount;
  final VoidCallback onDone;

  const OrderConfirmationDialog({
    super.key,
    required this.orderId,
    required this.profile,
    required this.location,
    required this.items,
    required this.totalAmount,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          maxHeight: 620,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scrollable content area
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Success Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppTheme.pureVegLightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 42,
                          color: AppTheme.pureVegGreen,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Title: "Order Placed Successfully!"
                      const Text(
                        'Order Placed Successfully!',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // 3. Order ID like "ORD-4821"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Order ID: $orderId',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),

                      const Divider(height: 24, color: Color(0xFFEEEEEE)),

                      // 4. Student Name, Roll Number and Mobile
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF0EBE1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoLine(
                              Icons.person_outline,
                              'Student Name',
                              profile?.fullName ?? 'Campus Student',
                            ),
                            const SizedBox(height: 6),
                            _buildInfoLine(
                              Icons.phone_outlined,
                              'Mobile',
                              profile != null
                                  ? '+91 ${profile!.mobileNumber}'
                                  : 'Not provided',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 5. Delivery Location and Zone
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF0EBE1)),
                        ),
                        child: _buildInfoLine(
                          Icons.location_on_outlined,
                          'Delivery Location',
                          '${location.name} (${location.zone.name} • +₹${location.chargePerItem.toStringAsFixed(0)}/item)',
                          highlight: true,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 6. Itemized list
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF0EBE1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Items Ordered:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...items.map(
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const VegSymbol(size: 11),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${i.item.name} × ${i.quantity}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${(i.item.price * i.quantity).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 7. Total Cash/UPI Amount Payable on Delivery callout
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.pureVegLightGreen,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.pureVegGreen.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total Cash/UPI Amount Payable on Delivery:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.pureVegGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.pureVegGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 8. "Done" button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoLine(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: highlight ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
