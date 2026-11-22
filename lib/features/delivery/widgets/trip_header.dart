import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/delivery/providers/delivery_provider.dart';

class TripHeader extends StatelessWidget {
  final List<String>? pickupVendorNames;
  final int? stopCount;
  final int? waitingForKitchenCount;

  const TripHeader({
    super.key,
    this.pickupVendorNames,
    this.stopCount,
    this.waitingForKitchenCount,
  });

  @override
  Widget build(BuildContext context) {
    DeliveryProvider? provider;
    try {
      provider = context.watch<DeliveryProvider>();
    } catch (_) {
      provider = null;
    }

    final vendors =
        pickupVendorNames ?? provider?.tripPickupVendorNames ?? const [];
    final stops = stopCount ?? provider?.activeTrip.length ?? 0;
    final waiting =
        waitingForKitchenCount ?? provider?.waitingForKitchenCount ?? 0;

    final vendorsText = vendors.isNotEmpty ? vendors.join(', ') : 'None';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: const Color(0xFFF0EBE1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Collect from: $vendorsText',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$stops ${stops == 1 ? 'stop' : 'stops'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          if (waiting > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.hourglass_top_outlined,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Waiting for kitchen: $waiting order(s) not ready yet',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
