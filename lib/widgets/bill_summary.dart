import 'package:flutter/material.dart';
import '../models/campus_location.dart';
import '../models/cart_item.dart';
import '../theme/app_theme.dart';
import 'food_card.dart';

class BillSummary extends StatelessWidget {
  final List<CartItem> items;
  final CampusLocation? location;

  const BillSummary({
    super.key,
    required this.items,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final foodSubtotal = items.fold(
      0.0,
      (sum, item) => sum + (item.item.price * item.quantity),
    );
    final totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
    final zoneChargePerItem = location?.chargePerItem ?? 0.0;
    final zoneExtraTotal = location != null ? (zoneChargePerItem * totalQuantity) : 0.0;
    final finalTotal = items.isEmpty ? 0.0 : (foodSubtotal + zoneExtraTotal);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: const BorderSide(color: Color(0xFFF0EBE1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bill Header
            const Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Order Bill Breakdown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF0EBE1)),

            // 1. Itemized list: name × qty = ₹line total
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No items in cart',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              )
            else
              ...items.map((cartItem) {
                final lineTotal = cartItem.item.price * cartItem.quantity;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const VegSymbol(size: 13),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${cartItem.item.name} × ${cartItem.quantity}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '₹${lineTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const Divider(height: 20, color: Color(0xFFF0EBE1)),

            // 2. Base Food Price (Subtotal)
            _buildRow(
              'Base Food Price (Subtotal)',
              '₹${foodSubtotal.toStringAsFixed(0)}',
              isMuted: false,
            ),
            const SizedBox(height: 8),

            // 3. Delivery Location: <name> (Zone X)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Location',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                if (location != null)
                  Text(
                    '${location!.name} (${location!.zone.name})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  )
                else
                  const Text(
                    'Not selected',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 4. Zone Extra Charge: ₹<per item> × <total quantity> = ₹<extra>
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Zone Extra Charge',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                if (location != null)
                  Text(
                    '₹${zoneChargePerItem.toStringAsFixed(0)} × $totalQuantity = ₹${zoneExtraTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  )
                else
                  const Text(
                    'Select location',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // 5. Final Total Amount to Pay: ₹<total> (large, bold, highlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0), // Highlighted warm orange tint
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Final Total Amount to Pay',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '₹${finalTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isMuted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isMuted ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
