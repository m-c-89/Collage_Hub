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
          label == label &&
          reached == other.reached &&
          isCurrent == other.isCurrent &&
          time == other.time;

  @override
  int get hashCode => Object.hash(status, label, reached, isCurrent, time);

  @override
  String toString() =>
      'TimelineStep(status: $status, label: $label, reached: $reached, isCurrent: $isCurrent, time: $time)';
}

const List<(OrderStatus status, String label)> _kTimelineStepDefinitions = [
  (OrderStatus.placed, 'Placed'),
  (OrderStatus.accepted, 'Accepted'),
  (OrderStatus.preparing, 'Preparing'),
  (OrderStatus.readyForPickup, 'Ready'),
  (OrderStatus.outForDelivery, 'Out for delivery'),
  (OrderStatus.delivered, 'Delivered'),
];

List<TimelineStep> buildTimeline(Order order) {
  if (order.status == OrderStatus.cancelled) {
    return const [];
  }

  int currentIndex = _kTimelineStepDefinitions
      .indexWhere((step) => step.$1 == order.status);
  if (currentIndex == -1) {
    if (order.status == OrderStatus.etaProposed ||
        order.status == OrderStatus.etaAgreed) {
      currentIndex = 0;
    } else {
      return const [];
    }
  }

  final historyMap = <OrderStatus, DateTime>{};
  for (final (status, time) in order.statusHistory) {
    historyMap[status] = time;
  }

  return List.generate(_kTimelineStepDefinitions.length, (index) {
    final (status, label) = _kTimelineStepDefinitions[index];
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
