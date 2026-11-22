import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/core/widgets/countdown_text.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/services/order_timeouts.dart';
import 'package:college_canteen/features/vendor/providers/vendor_provider.dart';
import 'package:college_canteen/features/vendor/services/proposal_defaults.dart';

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
    final needsAction = provider.needsAction;
    final waiting = provider.waiting;
    final inProgress = provider.inProgress;
    final completed = provider.completed;

    final entries = <_OrdersListEntry>[
      _HeaderEntry(
        isAccepting: isAccepting,
        isSettingAccepting: isSettingAccepting,
      ),
      _SectionHeaderEntry(
        title: 'Needs your action',
        count: needsAction.length,
        badge: provider.newOrderBadge,
      ),
      if (needsAction.isEmpty)
        const _EmptySectionEntry(message: 'No orders needing action')
      else
        ...needsAction.map((o) => _OrderCardEntry(order: o)),
      _SectionHeaderEntry(
        title: 'Waiting for customer',
        count: waiting.length,
      ),
      if (waiting.isEmpty)
        const _EmptySectionEntry(message: 'No orders waiting for customer')
      else
        ...waiting.map((o) => _OrderCardEntry(order: o)),
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
          color: isAccepting
              ? AppTheme.pureVegGreen.withOpacity(0.3)
              : Colors.grey.shade300,
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
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
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

  Future<void> _confirmCancel(BuildContext context, {required bool isPaid}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: Text(
          isPaid
              ? 'Are you sure you want to cancel order #${order.id}? Since this order is paid, it will be marked refund pending.'
              : 'Are you sure you want to cancel order #${order.id}?',
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
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<VendorProvider>().cancelOrder(order.id);
    }
  }

  Future<void> _showEtaSheet(BuildContext context) async {
    List<int> prepMaxList = [];
    try {
      final menuRepo = context.read<MenuRepository>();
      final catalog = menuRepo.currentItems;
      prepMaxList = order.items.map((oi) {
        final item = catalog.cast<MenuItem?>().firstWhere(
              (m) => m?.id == oi.itemId,
              orElse: () => null,
            );
        return item?.prepMaxMinutes ?? 10;
      }).toList();
    } catch (_) {}

    final defaultMinutes = defaultProposedPrepMinutes(prepMaxList);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _EtaProposalSheet(
        order: order,
        defaultMinutes: defaultMinutes,
        onSend: (minutes) {
          Navigator.of(sheetContext).pop();
          context.read<VendorProvider>().proposeEta(order.id, minutes);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorProvider>();
    final isInFlight = provider.isOrderInFlight(order.id);

    final paymentLabel = switch (order.paymentStatus) {
      PaymentStatus.paid => 'Paid',
      PaymentStatus.payOnDelivery => 'Collect on delivery',
      PaymentStatus.refundPending => 'Refund pending',
      PaymentStatus.unpaid => 'Awaiting payment',
    };

    final isPaid = order.paymentStatus == PaymentStatus.paid;
    final isCod = order.paymentStatus == PaymentStatus.payOnDelivery;
    final isRefund = order.paymentStatus == PaymentStatus.refundPending;

    final Color badgeBg;
    final Color badgeText;
    if (isPaid || isCod) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = const Color(0xFF2E7D32);
    } else if (isRefund) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = const Color(0xFFC62828);
    } else {
      badgeBg = const Color(0xFFFFF3E0);
      badgeText = const Color(0xFFE65100);
    }

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
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paymentLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeText,
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
    final deadline = OrderTimeouts.deadlineFor(order);

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
                onPressed: isInFlight ? null : () => _showEtaSheet(context),
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
                        'Send time',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        );

      case OrderStatus.etaProposed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Waiting for customer',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF57F17),
                  ),
                ),
              ),
              if (deadline != null) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Color(0xFFF57F17),
                    ),
                    const SizedBox(width: 4),
                    CountdownText(
                      deadline,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF57F17),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );

      case OrderStatus.etaAgreed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (deadline != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Customer agreed to wait',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.pureVegGreen,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        CountdownText(
                          deadline,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        isInFlight ? null : () => _confirmReject(context),
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
                            'Accept order',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );

      case OrderStatus.accepted:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Waiting for payment',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                  if (deadline != null) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Color(0xFFE65100),
                        ),
                        const SizedBox(width: 4),
                        CountdownText(
                          deadline,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: isInFlight
                  ? null
                  : () => _confirmCancel(context, isPaid: false),
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
                      'Cancel order',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        );

      case OrderStatus.preparing:
        final isPaid = order.paymentStatus == PaymentStatus.paid;
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isInFlight
                    ? null
                    : () => _confirmCancel(context, isPaid: isPaid),
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
                        'Cancel order',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
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
            ),
          ],
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
        final reasonLabel = order.cancelReason?.label;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            reasonLabel != null ? 'Cancelled ($reasonLabel)' : 'Cancelled',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC62828),
            ),
          ),
        );
    }
  }
}

class _EtaProposalSheet extends StatefulWidget {
  final Order order;
  final int defaultMinutes;
  final ValueChanged<int> onSend;

  const _EtaProposalSheet({
    required this.order,
    required this.defaultMinutes,
    required this.onSend,
  });

  @override
  State<_EtaProposalSheet> createState() => _EtaProposalSheetState();
}

class _EtaProposalSheetState extends State<_EtaProposalSheet> {
  static const _chipOptions = [10, 15, 20, 30, 45, 60];
  late int _selectedMinutes;
  late TextEditingController _customController;
  String? _customError;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.defaultMinutes;
    final isPreset = _chipOptions.contains(_selectedMinutes);
    _customController = TextEditingController(
      text: isPreset ? '' : '$_selectedMinutes',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _onChipSelected(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _customController.clear();
      _customError = null;
    });
  }

  void _onCustomChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _customError = null;
      });
      return;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null ||
        parsed < AppConfig.minProposedPrepMinutes ||
        parsed > AppConfig.maxProposedPrepMinutes) {
      setState(() {
        _customError =
            'Must be between ${AppConfig.minProposedPrepMinutes} and ${AppConfig.maxProposedPrepMinutes} min';
      });
    } else {
      setState(() {
        _selectedMinutes = parsed;
        _customError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isValid = _customError == null &&
        _selectedMinutes >= AppConfig.minProposedPrepMinutes &&
        _selectedMinutes <= AppConfig.maxProposedPrepMinutes;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Preparation time for #${widget.order.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select or enter how many minutes you need to prepare this order after payment:',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chipOptions.map((minutes) {
                final isSelected = _selectedMinutes == minutes &&
                    _customController.text.trim().isEmpty;
                return ChoiceChip(
                  label: Text('$minutes min'),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _onChipSelected(minutes);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Custom time (minutes)',
                hintText: '5–120',
                errorText: _customError,
                border: const OutlineInputBorder(),
                suffixText: 'min',
              ),
              onChanged: _onCustomChanged,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isValid ? () => widget.onSend(_selectedMinutes) : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Send $_selectedMinutes min to customer',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
