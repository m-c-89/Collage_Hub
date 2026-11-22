import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/order.dart';

class TimelineStep {
  final OrderStatus status;
  final String label;
  final bool reached;
  final bool isCurrent;
  final DateTime? time;

  const TimelineStep({
    required this.status,
    required this.label,
    required this.reached,
    required this.isCurrent,
    this.time,
  });

  String get title => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineStep &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          label == other.label &&
          reached == other.reached &&
          isCurrent == other.isCurrent &&
          time == other.time;

  @override
  int get hashCode => Object.hash(status, label, reached, isCurrent, time);

  @override
  String toString() =>
      'TimelineStep(status: $status, label: $label, reached: $reached, isCurrent: $isCurrent, time: $time)';
}

const List<OrderStatus> _kStepOrder = [
  OrderStatus.placed,
  OrderStatus.etaProposed,
  OrderStatus.etaAgreed,
  OrderStatus.accepted,
  OrderStatus.preparing,
  OrderStatus.readyForPickup,
  OrderStatus.outForDelivery,
  OrderStatus.delivered,
];

List<TimelineStep> buildTimeline(Order order) {
  if (order.status == OrderStatus.cancelled) {
    return const [];
  }

  final currentIndex = _kStepOrder.indexOf(order.status);
  if (currentIndex == -1) {
    return const [];
  }

  final preparingLabel = order.paymentMethod == PaymentMethod.cod
      ? 'Confirmed & preparing'
      : 'Paid & preparing';

  final stepDefinitions = <(OrderStatus status, String label)>[
    (OrderStatus.placed, 'Requested'),
    (OrderStatus.etaProposed, 'Time confirmed'),
    (OrderStatus.etaAgreed, 'You agreed'),
    (OrderStatus.accepted, 'Accepted'),
    (OrderStatus.preparing, preparingLabel),
    (OrderStatus.readyForPickup, 'Ready'),
    (OrderStatus.outForDelivery, 'Out for delivery'),
    (OrderStatus.delivered, 'Delivered'),
  ];

  final historyMap = <OrderStatus, DateTime>{};
  for (final (status, time) in order.statusHistory) {
    historyMap[status] = time;
  }

  return List.generate(stepDefinitions.length, (index) {
    final (status, label) = stepDefinitions[index];
    final reached = index <= currentIndex;
    final isCurrent = index == currentIndex;
    final time = historyMap[status];

    return TimelineStep(
      status: status,
      label: label,
      reached: reached,
      isCurrent: isCurrent,
      time: time,
    );
  });
}
