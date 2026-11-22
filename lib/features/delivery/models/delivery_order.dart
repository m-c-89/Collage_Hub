import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/delivery/services/delivery_formatters.dart';
import 'package:college_canteen/features/food/models/order.dart';

class DeliveryOrder {
  final String orderId;
  final OrderModule module;
  final String vendorName;
  final String locationId;
  final String building;
  final String block;
  final int floor;
  final String room;
  final String address;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String itemsSummary;
  final DateTime estimatedReadyTime;
  final OrderStatus status;

  const DeliveryOrder({
    required this.orderId,
    required this.module,
    required this.vendorName,
    required this.locationId,
    required this.building,
    required this.block,
    required this.floor,
    required this.room,
    required this.address,
    required this.windowStart,
    required this.windowEnd,
    required this.itemsSummary,
    required this.estimatedReadyTime,
    required this.status,
  });

  factory DeliveryOrder.fromOrder(Order order) {
    final readyTime = order.estimatedReadyTime;
    if (readyTime == null) {
      throw StateError('Order ${order.id} has no estimatedReadyTime');
    }
    final windowStart = readyTime;
    final windowEnd = windowStart.add(
      const Duration(minutes: AppConfig.deliveryWindowMinutes),
    );
    final summary = DeliveryFormatters.formatItemsSummary(order.items);

    return DeliveryOrder(
      orderId: order.id,
      module: order.module,
      vendorName: order.vendorName,
      locationId: order.locationId,
      building: order.building,
      block: order.block,
      floor: order.floor,
      room: order.room,
      address: order.address,
      windowStart: windowStart,
      windowEnd: windowEnd,
      itemsSummary: summary,
      estimatedReadyTime: readyTime,
      status: order.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryOrder &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId;

  @override
  int get hashCode => orderId.hashCode;

  @override
  String toString() =>
      'DeliveryOrder(orderId: $orderId, module: ${module.name}, vendor: $vendorName, building: $building, block: $block, floor: $floor, room: $room)';
}
