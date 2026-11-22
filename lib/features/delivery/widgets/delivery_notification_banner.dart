import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/delivery/models/delivery_order.dart';
import 'package:college_canteen/features/delivery/providers/delivery_provider.dart';
import 'package:college_canteen/features/delivery/services/delivery_formatters.dart';
import 'package:college_canteen/features/delivery/services/order_batching_engine.dart';

class DeliveryNotificationBanner extends StatelessWidget {
  final DeliveryBatch? batch;
  final DeliveryOrder? order;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;

  const DeliveryNotificationBanner({
    super.key,
    this.batch,
    this.order,
    this.onAccept,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    DeliveryProvider? provider;
    try {
      provider = context.watch<DeliveryProvider>();
    } catch (_) {
      provider = null;
    }

    if (provider != null &&
        !provider.isOnline &&
        batch == null &&
        order == null) {
      return const SizedBox.shrink();
    }

    final effectiveBatch = batch ?? provider?.newBatchAlert;
    final effectiveOrder = order ??
        (effectiveBatch != null && effectiveBatch.stops.isNotEmpty
            ? _earliestStop(effectiveBatch.stops)
            : null);

    if (effectiveOrder == null) {
      return const SizedBox.shrink();
    }

    final additionalStops =
        effectiveBatch != null ? effectiveBatch.stops.length - 1 : 0;
    final addressText = effectiveOrder.address.isNotEmpty
        ? effectiveOrder.address
        : '${effectiveOrder.room}, Floor ${effectiveOrder.floor}, ${effectiveOrder.block}, ${effectiveOrder.building}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: AppTheme.primaryColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
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
                  addressText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (additionalStops > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+$additionalStops more',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  formatTimeWindow(
                    effectiveOrder.windowStart,
                    effectiveOrder.windowEnd,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.fastfood_outlined,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  effectiveOrder.itemsSummary,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss ??
                    (provider != null ? () =>provider?.dismissAlert(): null),
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAccept ??
                    (provider != null &&
                            effectiveBatch != null &&
                            !provider.isActionInProgress
                        ? () => provider?.acceptBatch(effectiveBatch.id)
                        : null),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DeliveryOrder _earliestStop(List<DeliveryOrder> stops) {
    return stops
        .reduce((a, b) => a.windowStart.isBefore(b.windowStart) ? a : b);
  }
}
