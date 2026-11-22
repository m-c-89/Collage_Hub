import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/vendor/providers/vendor_provider.dart';

class VendorOrdersTab extends StatefulWidget {
  final String? vendorId;

  const VendorOrdersTab({super.key, this.vendorId});

  @override
  State<VendorOrdersTab> createState() => _VendorOrdersTabState();
}

class _VendorOrdersTabState extends State<VendorOrdersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VendorProvider>().markOrdersSeen();
    });
  }

  void _checkAndShowError(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<VendorProvider>();
      final error = provider.lastError;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade800,
          ),
        );
        provider.clearLastError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _checkAndShowError(context);

    final provider = context.watch<VendorProvider>();
    final isAccepting = provider.profile?.isAcceptingOrders ?? true;
    final isSettingAccepting = provider.isSettingAccepting;
    final incoming = provider.incoming;
    final inProgress = provider.inProgress;
    final completed = provider.completed;

    final entries = <_OrdersListEntry>[
      _HeaderEntry(
        isAccepting: isAccepting,
        isSettingAccepting: isSettingAccepting,
      ),
      _SectionHeaderEntry(
        title: 'Incoming',
        count: incoming.length,
        badge: provider.newOrderBadge,
      ),
      if (incoming.isEmpty)
        const _EmptySectionEntry(message: 'No incoming orders')
      else
        ...incoming.map((o) => _OrderCardEntry(order: o)),
      _SectionHeaderEntry(
        title: 'In progress',
        count: inProgress.length,
      ),
      if (inProgress.isEmpty)
        const _EmptySectionEntry(message: 'No orders in progress')
      else
        ...inProgress.map((o) => _OrderCardEntry(order: o)),
      _SectionHeaderEntry(
        title: 'Completed',
        count: completed.length,
      ),
      if (completed.isEmpty)
        const _EmptySectionEntry(message: 'No completed orders')
      else
        ...completed.map((o) => _OrderCardEntry(order: o)),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          _HeaderEntry(:final isAccepting, :final isSettingAccepting) =>
            _AcceptingOrdersSwitchHeader(
              isAccepting: isAccepting,
              isSettingAccepting: isSettingAccepting,
            ),
          _SectionHeaderEntry(:final title, :final count, :final badge) =>
            _SectionHeaderWidget(title: title, count: count, badge: badge),
          _EmptySectionEntry(:final message) =>
            _EmptySectionWidget(message: message),
          _OrderCardEntry(:final order) => _VendorOrderCard(
              key: ValueKey(order.id),
              order: order,
            ),
        };
      },
    );
  }
}

sealed class _OrdersListEntry {
  const _OrdersListEntry();
}

class _HeaderEntry extends _OrdersListEntry {
  final bool isAccepting;
  final bool isSettingAccepting;

  const _HeaderEntry({
    required this.isAccepting,
    required this.isSettingAccepting,
  });
}

class _SectionHeaderEntry extends _OrdersListEntry {
  final String title;
  final int count;
  final int badge;

  const _SectionHeaderEntry({
    required this.title,
    required this.count,
    this.badge = 0,
  });
}

class _EmptySectionEntry extends _OrdersListEntry {
  final String message;

  const _EmptySectionEntry({required this.message});
}

class _OrderCardEntry extends _OrdersListEntry {
  final Order order;

  const _OrderCardEntry({required this.order});
}

class _AcceptingOrdersSwitchHeader extends StatelessWidget {
  final bool isAccepting;
  final bool isSettingAccepting;

  const _AcceptingOrdersSwitchHeader({
    required this.isAccepting,
    required this.isSettingAccepting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAccepting ? AppTheme.pureVegGreen.withOpacity(0.3) : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isAccepting ? Icons.storefront : Icons.storefront_outlined,
            color: isAccepting ? AppTheme.pureVegGreen : AppTheme.textSecondary,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accepting orders',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAccepting
                      ? 'Customers can place new orders'
                      : 'Store is paused / closed for new orders',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAccepting,
            activeColor: AppTheme.primaryColor,
            onChanged: isSettingAccepting
                ? null
                : (value) => context.read<VendorProvider>().setAccepting(value),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderWidget extends StatelessWidget {
  final String title;
  final int count;
  final int badge;

  const _SectionHeaderWidget({
    required this.title,
    required this.count,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          if (badge > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge new',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptySectionWidget extends StatelessWidget {
  final String message;

  const _EmptySectionWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _VendorOrderCard extends StatelessWidget {
  final Order order;

  const _VendorOrderCard({super.key, required this.order});

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:$minute $period';
  }

  Future<void> _confirmReject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order?'),
        content: Text(
          'Are you sure you want to reject order #${order.id}? This will cancel the order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<VendorProvider>().reject(order.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorProvider>();
    final isInFlight = provider.isOrderInFlight(order.id);

    final paymentLabel = order.paymentMethod == PaymentMethod.cod
        ? 'Collect on delivery'
        : 'Paid';
    final isPaid = paymentLabel == 'Paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID, placed time, and payment status chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '#${order.id}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(order.placedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paymentLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPaid
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Itemized list (name × qty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} × ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '₹${item.lineTotal}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Status action buttons or read-only text
            _buildStatusArea(context, isInFlight),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusArea(BuildContext context, bool isInFlight) {
    switch (order.status) {
      case OrderStatus.placed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isInFlight ? null : () => _confirmReject(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: isInFlight
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Reject',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: isInFlight
                    ? null
                    : () => context.read<VendorProvider>().accept(order.id),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: isInFlight
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Accept',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        );

      case OrderStatus.accepted:
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isInFlight
                ? null
                : () => context.read<VendorProvider>().startPreparing(order.id),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: isInFlight
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Start preparing',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        );

      case OrderStatus.preparing:
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isInFlight
                ? null
                : () => context.read<VendorProvider>().markReady(order.id),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: isInFlight
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Mark ready',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        );

      case OrderStatus.readyForPickup:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Ready for pickup',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),
        );

      case OrderStatus.outForDelivery:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Out for delivery',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        );

      case OrderStatus.delivered:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Delivered',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        );

      case OrderStatus.cancelled:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Cancelled',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC62828),
            ),
          ),
        );
    }
  }
}
