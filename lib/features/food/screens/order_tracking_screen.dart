import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/core/utils/money.dart';
import 'package:college_canteen/features/food/data/feedback_repository.dart';
import 'package:college_canteen/features/food/models/feedback.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/providers/orders_provider.dart';
import 'package:college_canteen/features/food/services/order_timeline.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String? initialOrderId;

  const OrderTrackingScreen({
    super.key,
    this.initialOrderId,
  });

  @override
  Widget build(BuildContext context) {
    // Select comma-separated list of order IDs so this screen only rebuilds when
    // orders are added/removed/reordered, not when an individual order's status changes.
    final orderIdsString = context.select<OrdersProvider, String>(
      (p) => p.orders.map((o) => o.id).join(','),
    );

    final orderIds = orderIdsString.isEmpty
        ? const <String>[]
        : orderIdsString.split(',');

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'My Orders',
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
          child: orderIds.isEmpty
              ? const _EmptyOrdersView()
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: orderIds.length,
                  itemBuilder: (context, index) {
                    final id = orderIds[index];
                    return _OrderTrackingCard(
                      key: ValueKey(id),
                      orderId: id,
                      initiallyExpanded: id == initialOrderId,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you place an order, it will appear here so you can track its progress live.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Browse Menu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTrackingCard extends StatefulWidget {
  final String orderId;
  final bool initiallyExpanded;

  const _OrderTrackingCard({
    super.key,
    required this.orderId,
    this.initiallyExpanded = false,
  });

  @override
  State<_OrderTrackingCard> createState() => _OrderTrackingCardState();
}

class _OrderTrackingCardState extends State<_OrderTrackingCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month, $hour:$minute';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildStatusChip(OrderStatus status) {
    final (Color bgColor, Color textColor, IconData icon) = switch (status) {
      OrderStatus.placed => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
          Icons.schedule_rounded
        ),
      OrderStatus.accepted => (
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          Icons.thumb_up_alt_outlined
        ),
      OrderStatus.preparing => (
          const Color(0xFFEDE7F6),
          const Color(0xFF5E35B1),
          Icons.soup_kitchen_outlined
        ),
      OrderStatus.readyForPickup => (
          const Color(0xFFE0F2F1),
          const Color(0xFF00695C),
          Icons.check_circle_outline_rounded
        ),
      OrderStatus.outForDelivery => (
          const Color(0xFFE1F5FE),
          const Color(0xFF0277BD),
          Icons.delivery_dining_outlined
        ),
      OrderStatus.delivered => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.done_all_rounded
        ),
      OrderStatus.cancelled => (
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          Icons.cancel_outlined
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledState(Order order) {
    DateTime? cancelledTime;
    for (final (status, time) in order.statusHistory.reversed) {
      if (status == OrderStatus.cancelled) {
        cancelledTime = time;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFC62828), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cancelledTime != null
                      ? 'Cancelled at ${_formatTime(cancelledTime)}'
                      : 'This order has been cancelled.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Order order) {
    final steps = buildTimeline(order);
    if (steps.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            final nextReached = !isLast && steps[index + 1].reached;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.isCurrent
                            ? AppTheme.primaryColor
                            : (step.reached
                                ? AppTheme.pureVegGreen
                                : Colors.transparent),
                        border: Border.all(
                          color: step.isCurrent
                              ? AppTheme.primaryColor
                              : (step.reached
                                  ? AppTheme.pureVegGreen
                                  : Colors.grey.shade400),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: step.isCurrent
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              )
                            : (step.reached
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 22,
                        color: nextReached
                            ? AppTheme.pureVegGreen
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: step.isCurrent
                                  ? FontWeight.bold
                                  : (step.reached
                                      ? FontWeight.w600
                                      : FontWeight.normal),
                              color: step.isCurrent
                                  ? AppTheme.primaryColor
                                  : (step.reached
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary),
                            ),
                          ),
                        ),
                        if (step.time != null)
                          Text(
                            _formatTime(step.time!),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, Order order) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD32F2F),
          side: const BorderSide(color: Color(0xFFEF9A9A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        ),
        icon: const Icon(Icons.close_rounded, size: 16),
        label: const Text(
          'Cancel Order',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('Cancel Order'),
              content: const Text(
                'Are you sure you want to cancel this order? This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Keep Order'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            try {
              await context.read<OrdersProvider>().cancelOrder(order.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                final message = e is AppException
                    ? e.userMessage
                    : (e is StateError ? e.message : e.toString());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: const Color(0xFFD32F2F),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (order, _, _) =
        context.select<OrdersProvider, (Order?, OrderStatus?, int)>((p) {
      final o = p.orders.cast<Order?>().firstWhere(
            (o) => o?.id == widget.orderId,
            orElse: () => null,
          );
      return (o, o?.status, o?.statusHistory.length ?? 0);
    });

    if (order == null) {
      return const SizedBox.shrink();
    }

    final itemSummary =
        order.items.map((i) => '${i.name} × ${i.quantity}').join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF0EBE1), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Order ID & Status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.id,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(order.status),
                ],
              ),

              const SizedBox(height: 8),

              // Vendor and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.vendorName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(order.placedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Item summary
              Text(
                itemSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 10),

              // Grand Total & Details toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatRupees(order.grandTotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'Hide Details' : 'View Details',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),

              // Expanded Details
              if (_isExpanded) ...[
                const Divider(height: 20, color: Color(0xFFF0EBE1)),

                // Itemized list
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
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
                        const SizedBox(width: 8),
                        Text(
                          formatRupees(item.lineTotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 16, color: Color(0xFFF0EBE1)),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.address,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Payment Method
                Row(
                  children: [
                    const Icon(
                      Icons.payment_outlined,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${order.paymentMethod.label} • ${order.paymentStatus.label}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Timeline or Cancelled State
                if (order.status == OrderStatus.cancelled)
                  _buildCancelledState(order)
                else
                  _buildTimeline(order),

                // Cancel button (placed only)
                if (order.status == OrderStatus.placed)
                  _buildCancelButton(context, order),

                // Rate this order (delivered only)
                if (order.status == OrderStatus.delivered)
                  _OrderRatingWidget(order: order),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderRatingWidget extends StatefulWidget {
  final Order order;

  const _OrderRatingWidget({required this.order});

  @override
  State<_OrderRatingWidget> createState() => _OrderRatingWidgetState();
}

class _OrderRatingWidgetState extends State<_OrderRatingWidget> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackRepo =
        Provider.of<FeedbackRepository?>(context, listen: false);
    if (feedbackRepo == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<OrderFeedback>>(
      stream: feedbackRepo.watchFeedback(),
      builder: (context, snapshot) {
        final existing = feedbackRepo.forOrder(widget.order.id) ??
            snapshot.data?.cast<OrderFeedback?>().firstWhere(
                  (f) => f?.orderId == widget.order.id,
                  orElse: () => null,
                );

        if (existing != null) {
          // Read-only "Thanks for your feedback"
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppTheme.pureVegGreen, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Thanks for your feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppTheme.pureVegGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < existing.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFFFB300),
                      size: 22,
                    );
                  }),
                ),
                if (existing.comment != null &&
                    existing.comment!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"${existing.comment!.trim()}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // Interactive Rating Form
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDE7).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFF59D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate this order',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  final isSelected = starVal <= _selectedRating;
                  return GestureDetector(
                    onTap: _isSubmitting
                        ? null
                        : () => setState(() => _selectedRating = starVal),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isSelected
                            ? const Color(0xFFFFB300)
                            : Colors.grey.shade400,
                        size: 30,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLength: 200,
                maxLines: 2,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Leave a comment (optional)...',
                  hintStyle: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (_selectedRating >= 1 &&
                          _selectedRating <= 5 &&
                          !_isSubmitting)
                      ? () => _submitRating(context, feedbackRepo)
                      : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRating(
    BuildContext context,
    FeedbackRepository repo,
  ) async {
    if (_isSubmitting || _selectedRating < 1 || _selectedRating > 5) return;

    setState(() => _isSubmitting = true);
    final commentText = _commentController.text.trim();

    final feedback = OrderFeedback(
      orderId: widget.order.id,
      vendorId: widget.order.vendorId,
      itemIds: widget.order.items.map((i) => i.itemId).toList(),
      rating: _selectedRating,
      comment: commentText.isEmpty ? null : commentText,
      at: DateTime.now(),
    );

    try {
      await repo.submit(feedback);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for your feedback!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
