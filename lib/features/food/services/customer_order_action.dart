import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/services/order_timeouts.dart';

enum CustomerPrimaryAction {
  none,
  agree,
  pay;

  String get label => switch (this) {
        CustomerPrimaryAction.agree => 'Agree & continue',
        CustomerPrimaryAction.pay => 'Pay now',
        CustomerPrimaryAction.none => '',
      };
}

enum CustomerSecondaryAction {
  none,
  decline,
  cancel;

  String get label => switch (this) {
        CustomerSecondaryAction.decline => 'Decline: wait is too long',
        CustomerSecondaryAction.cancel => 'Cancel Order',
        CustomerSecondaryAction.none => '',
      };
}

class CustomerOrderAction {
  final String headline;
  final String subtitle;
  final CustomerPrimaryAction primary;
  final CustomerSecondaryAction secondary;
  final DateTime? deadline;

  const CustomerOrderAction({
    required this.headline,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    this.deadline,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOrderAction &&
          runtimeType == other.runtimeType &&
          headline == other.headline &&
          subtitle == other.subtitle &&
          primary == other.primary &&
          secondary == other.secondary &&
          deadline == other.deadline;

  @override
  int get hashCode =>
      Object.hash(headline, subtitle, primary, secondary, deadline);

  @override
  String toString() =>
      'CustomerOrderAction(headline: $headline, subtitle: $subtitle, primary: $primary, secondary: $secondary, deadline: $deadline)';
}

String _formatTime(DateTime dt) {
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

CustomerOrderAction describe(Order order, DateTime now) {
  switch (order.status) {
    case OrderStatus.placed:
      return CustomerOrderAction(
        headline:
            'Waiting for ${order.vendorName} to confirm the preparation time',
        subtitle: '',
        primary: CustomerPrimaryAction.none,
        secondary: CustomerSecondaryAction.cancel,
        deadline: OrderTimeouts.deadlineFor(order),
      );

    case OrderStatus.etaProposed:
      final n = order.proposedPrepMinutes ?? 0;
      final deliveryEta = n + AppConfig.deliveryTravelBufferMinutes;
      return CustomerOrderAction(
        headline:
            '${order.vendorName} can have it ready about $n min after you pay',
        subtitle: 'At your room around $deliveryEta min after payment',
        primary: CustomerPrimaryAction.agree,
        secondary: CustomerSecondaryAction.decline,
        deadline: OrderTimeouts.deadlineFor(order),
      );

    case OrderStatus.etaAgreed:
      return CustomerOrderAction(
        headline: 'Waiting for ${order.vendorName} to accept',
        subtitle: '',
        primary: CustomerPrimaryAction.none,
        secondary: CustomerSecondaryAction.cancel,
        deadline: OrderTimeouts.deadlineFor(order),
      );

    case OrderStatus.accepted:
      if (order.paymentStatus == PaymentStatus.unpaid) {
        return CustomerOrderAction(
          headline: 'Accepted! Pay now to start preparing',
          subtitle: '',
          primary: CustomerPrimaryAction.pay,
          secondary: CustomerSecondaryAction.cancel,
          deadline: OrderTimeouts.deadlineFor(order),
        );
      }
      return const CustomerOrderAction(
        headline: 'Order accepted',
        subtitle: '',
        primary: CustomerPrimaryAction.none,
        secondary: CustomerSecondaryAction.none,
        deadline: null,
      );

    case OrderStatus.preparing:
      final readyText = order.estimatedReadyTime != null
          ? 'Being prepared. Ready by ${_formatTime(order.estimatedReadyTime!)}'
          : 'Being prepared';
      return CustomerOrderAction(
        headline: readyText,
        subtitle: '',
        primary: CustomerPrimaryAction.none,
        secondary: CustomerSecondaryAction.none,
        deadline: null,
      );

    case OrderStatus.readyForPickup:
      return const CustomerOrderAction(
        headline: 'Ready for pickup',
        subtitle: 'Your order is packed and ready for pickup',
        primary: CustomerPrimaryAction.none,
        secondary: CustomerSecondaryAction.none,
        deadline: null,
      );

    case OrderStatus.outForDelivery:
      return const CustomerOrderAction(
        headline: 'Out for delivery',
        subtitle: 'Your food is on the way to your room',
        primary: CustomerPrimaryAction.none,
        secondary: CustomerSecondaryAction.none,
        deadline: null,
      );

    case OrderStatus.delivered:
      return const CustomerOrderAction(
        headline: 'Delivered',
        subtitle: 'Enjoy your meal!',
        primary: CustomerPrimaryAction.none,
        secondary: CustomerSecondaryAction.none,
        deadline: null,
      );

    case OrderStatus.cancelled:
      return CustomerOrderAction(
        headline: 'Order cancelled',
        subtitle: order.cancelReason?.label ?? 'Cancelled',
        primary: CustomerPrimaryAction.none,
        secondary: CustomerSecondaryAction.none,
        deadline: null,
      );
  }
}
