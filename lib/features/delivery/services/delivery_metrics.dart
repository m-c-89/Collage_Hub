import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/order.dart';

class DeliveryMetrics {
  final int activeDeliveries;
  final int deliveredToday;

  const DeliveryMetrics({
    required this.activeDeliveries,
    required this.deliveredToday,
  });

  static DeliveryMetrics compute({
    required List<Order> orders,
    required String partnerId,
    required DateTime now,
  }) {
    var activeCount = 0;
    var deliveredTodayCount = 0;

    for (final order in orders) {
      if (order.assignedPartnerId != partnerId) continue;

      if (order.status == OrderStatus.preparing ||
          order.status == OrderStatus.readyForPickup ||
          order.status == OrderStatus.outForDelivery) {
        activeCount++;
      } else if (order.status == OrderStatus.delivered) {
        final deliveredTime = order.timeOf(OrderStatus.delivered);
        if (deliveredTime != null &&
            deliveredTime.year == now.year &&
            deliveredTime.month == now.month &&
            deliveredTime.day == now.day) {
          deliveredTodayCount++;
        }
      }
    }

    return DeliveryMetrics(
      activeDeliveries: activeCount,
      deliveredToday: deliveredTodayCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryMetrics &&
          runtimeType == other.runtimeType &&
          activeDeliveries == other.activeDeliveries &&
          deliveredToday == other.deliveredToday;

  @override
  int get hashCode => Object.hash(activeDeliveries, deliveredToday);

  @override
  String toString() =>
      'DeliveryMetrics(activeDeliveries: $activeDeliveries, deliveredToday: $deliveredToday)';
}
