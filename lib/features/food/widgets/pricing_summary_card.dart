import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/core/utils/money.dart';
import 'package:college_canteen/features/food/domain/cart_pricing.dart';
import 'package:college_canteen/features/food/providers/cart_provider.dart';
import 'package:college_canteen/features/food/providers/checkout_provider.dart';
import 'package:college_canteen/features/food/widgets/food_card.dart';

/// Reads [CartProvider] and [CheckoutProvider] via context.select to rebuild
/// only when pricing inputs change. Computes [PricingResult] inline.
class PricingSummaryCard extends StatelessWidget {
  const PricingSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final subtotal = context.select<CartProvider, int>((c) => c.subtotal);
    final itemCount = context.select<CartProvider, int>((c) => c.totalQuantity);
    final location =
        context.select<CheckoutProvider, dynamic>((c) => c.selectedLocation);
    final pricing = CartPricing.compute(
      subtotal: subtotal,
      itemCount: itemCount,
      location: location,
    );

    if (pricing.itemCount == 0) {
      // Empty — caller hides or shows empty state; card shows nothing
      return const SizedBox.shrink();
    }

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
            // Header
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 20, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Bill Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF0EBE1)),

            // Banner
            if (pricing.banner == CartBanner.minOrder) ...[
              _BannerBox(
                icon: Icons.info_outline_rounded,
                color: const Color(0xFFFFF3CD),
                borderColor: const Color(0xFFFFCF77),
                iconColor: const Color(0xFFB36B00),
                text:
                    'Order requires more food — add items worth '
                    '${formatRupees(pricing.shortfall)} more to meet the '
                    '${formatRupees(AppConfig.minOrderSubtotal)} minimum order requirement.',
              ),
              const SizedBox(height: 12),
            ] else if (pricing.banner == CartBanner.selectLocation) ...[
              const _BannerBox(
                icon: Icons.location_off_outlined,
                color: Color(0xFFFFF3CD),
                borderColor: Color(0xFFFFCF77),
                iconColor: Color(0xFFB36B00),
                text: 'Select a delivery location to continue.',
              ),
              const SizedBox(height: 12),
            ],

            // Item Subtotal
            _PriceRow(
              label: 'Item Subtotal',
              value: formatRupees(pricing.subtotal),
            ),
            const SizedBox(height: 8),

            // Delivery Fee
            _buildDeliveryFeeRow(pricing),
            const SizedBox(height: 8),

            // Tax & Service Charge (always shown)
            _PriceRow(
              label: 'Tax & Service Charge',
              value: formatRupees(pricing.taxAndServiceCharge),
              muted: true,
            ),

            const Divider(height: 20, color: Color(0xFFF0EBE1)),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  formatRupees(pricing.grandTotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),

            // Selected address
            if (pricing.location != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pricing.location!.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryFeeRow(PricingResult pricing) {
    if (pricing.meetsMinimum && pricing.hasLocation) {
      return _PriceRow(
        label: 'Delivery Fee',
        value: formatRupees(pricing.deliveryFee),
      );
    } else if (!pricing.meetsMinimum) {
      // 0 < subtotal < 50
      return const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Delivery Fee',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          Text(
            '— (applies from ₹50)',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else {
      // meetsMinimum but no location
      return const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Delivery Fee',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          Text(
            'Select location',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      );
    }
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;

  const _PriceRow({
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      color: muted ? AppTheme.textSecondary : AppTheme.textPrimary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value,
            style: style.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BannerBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final String text;

  const _BannerBox({
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: iconColor,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Veg symbol re-export helper so other files can import from one place.
export 'package:college_canteen/features/food/widgets/food_card.dart'
    show VegSymbol;
