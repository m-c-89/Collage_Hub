import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/delivery/providers/delivery_provider.dart';
import 'package:college_canteen/features/delivery/services/delivery_formatters.dart';
import 'package:college_canteen/features/delivery/services/trip_rules.dart';
import 'package:college_canteen/features/delivery/widgets/minimal_order_card.dart';
import 'package:college_canteen/features/delivery/widgets/trip_header.dart';

class ActiveTripTab extends StatefulWidget {
  const ActiveTripTab({super.key});

  @override
  State<ActiveTripTab> createState() => _ActiveTripTabState();
}

class _ActiveTripTabState extends State<ActiveTripTab> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final lastError = provider.lastError;

    if (lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lastError)),
        );
        context.read<DeliveryProvider>().clearError();
      });
    }

    if (!provider.isOnline && provider.activeTrip.isEmpty) {
      return _buildOfflineEmptyState();
    }

    if (provider.isOnline && provider.activeTrip.isEmpty) {
      return _buildPendingBatchesView(context, provider);
    }

    return _buildActiveTripView(context, provider);
  }

  Widget _buildOfflineEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EBE1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_outlined,
                size: 32,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Go online to receive orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toggle the switch in the top bar to start receiving delivery batches.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBatchesView(
    BuildContext context,
    DeliveryProvider provider,
  ) {
    final batches = provider.pendingBatches;

    if (batches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0EBE1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  size: 32,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No orders right now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'New batch requests will appear here when ready.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: batches.length,
      itemBuilder: (context, index) {
        final batch = batches[index];
        final canAccept = TripRules.canTakeOrders(
          activeCount: provider.activeTrip.length,
          adding: batch.stops.length,
        );
        final firstItemSummary = batch.stops.isNotEmpty
            ? batch.stops.first.itemsSummary
            : 'No items';

        return Card(
          key: ValueKey(batch.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${batch.block}, ${batch.building}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${batch.stops.length} ${batch.stops.length == 1 ? 'stop' : 'stops'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
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
                        formatTimeWindow(batch.windowStart, batch.windowEnd),
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
                        firstItemSummary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: AppTheme.pureVegGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ready: ${batch.readyCount}/${batch.stops.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.pureVegGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!canAccept) ...[
                      const Text(
                        'Trip limit reached',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton(
                      onPressed: canAccept && !provider.isActionInProgress
                          ? () => provider.acceptBatch(batch.id)
                          : null,
                      child: Text(
                        canAccept ? 'Accept batch' : 'Trip limit reached',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTripView(
    BuildContext context,
    DeliveryProvider provider,
  ) {
    final activeTrip = provider.activeTrip;
    final canConfirm = provider.canConfirmPickup;
    final waitingCount = provider.waitingForKitchenCount;
    final canAddNearby = TripRules.canTakeOrders(
      activeCount: activeTrip.length,
      adding: 1,
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: activeTrip.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const TripHeader();
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: canConfirm && !provider.isActionInProgress
                      ? () => provider.confirmPickup()
                      : null,
                  child: Text(
                    canConfirm
                        ? 'Confirm pickup'
                        : 'Waiting for kitchen: $waitingCount order(s) not ready yet',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text(
                    'Active Order Request (+ Add Nearby Orders)',
                  ),
                  onPressed: canAddNearby && !provider.isActionInProgress
                      ? () => _showNearbyOrdersSheet(context)
                      : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Stops',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        final stopIndex = index - 2;
        final order = activeTrip[stopIndex];

        return MinimalOrderCard(
          key: ValueKey(order.orderId),
          order: order,
          stopNumber: stopIndex + 1,
          action: FilledButton(
            onPressed: order.status == OrderStatus.outForDelivery &&
                    !provider.isActionInProgress
                ? () => provider.markDelivered(order.orderId)
                : null,
            child: const Text('Mark Delivered'),
          ),
        );
      },
    );
  }

  void _showNearbyOrdersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return ChangeNotifierProvider<DeliveryProvider>.value(
          value: context.read<DeliveryProvider>(),
          child: const _NearbyOrdersBottomSheet(),
        );
      },
    );
  }
}

class _NearbyOrdersBottomSheet extends StatelessWidget {
  const _NearbyOrdersBottomSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final activeTrip = provider.activeTrip;

    if (activeTrip.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No active trip'),
      );
    }

    final nearby = provider.nearbyOrdersForActiveTrip;
    final canAddMore = TripRules.canTakeOrders(
      activeCount: activeTrip.length,
      adding: 1,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nearby Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (!canAddMore)
                    const Text(
                      'Trip limit reached',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (nearby.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No nearby orders right now',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: nearby.length,
                  itemBuilder: (context, index) {
                    final order = nearby[index];
                    return MinimalOrderCard(
                      key: ValueKey('nearby-${order.orderId}'),
                      order: order,
                      action: FilledButton(
                        onPressed: canAddMore && !provider.isActionInProgress
                            ? () => provider.addOrderToActiveTrip(order.orderId)
                            : null,
                        child: const Text('Add'),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
