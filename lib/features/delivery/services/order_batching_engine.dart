import 'dart:convert';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/delivery/models/delivery_order.dart';
import 'package:college_canteen/features/food/models/order.dart';

String computeBatchId(List<String> orderIds) {
  final sortedIds = List<String>.from(orderIds)..sort();
  final input = sortedIds.join('|');
  final bytes = utf8.encode(input);

  var hash = 0x811c9dc5;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }

  return hash.toRadixString(16).padLeft(8, '0');
}

class DeliveryBatch {
  final String id;
  final String building;
  final String block;
  final List<DeliveryOrder> stops;
  final List<String> pickupVendorNames;
  final DateTime windowStart;
  final DateTime windowEnd;
  final int readyCount;
  final bool allReady;

  const DeliveryBatch({
    required this.id,
    required this.building,
    required this.block,
    required this.stops,
    required this.pickupVendorNames,
    required this.windowStart,
    required this.windowEnd,
    required this.readyCount,
    required this.allReady,
  });

  factory DeliveryBatch.fromStops({
    required String building,
    required String block,
    required List<DeliveryOrder> stops,
  }) {
    if (stops.isEmpty) {
      throw ArgumentError('Stops cannot be empty');
    }

    final id = computeBatchId(stops.map((s) => s.orderId).toList());
    final vendorNames =
        stops.map((s) => s.vendorName).toSet().toList()..sort();

    final minStart = stops
        .map((s) => s.windowStart)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final maxEnd = stops
        .map((s) => s.windowEnd)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final readyCount =
        stops.where((s) => s.status == OrderStatus.readyForPickup).length;
    final allReady = readyCount == stops.length;

    return DeliveryBatch(
      id: id,
      building: building,
      block: block,
      stops: List.unmodifiable(stops),
      pickupVendorNames: List.unmodifiable(vendorNames),
      windowStart: minStart,
      windowEnd: maxEnd,
      readyCount: readyCount,
      allReady: allReady,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryBatch &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DeliveryBatch(id: $id, building: $building, block: $block, stops: ${stops.length})';
}

abstract final class OrderBatchingEngine {
  static List<DeliveryBatch> build(
    List<Order> orders, {
    int? toleranceMinutes,
    int? maxBatchSize,
  }) {
    final tolerance = toleranceMinutes ?? AppConfig.batchTimeToleranceMinutes;
    final maxSize = maxBatchSize ?? AppConfig.maxBatchSize;
    final toleranceDuration = Duration(minutes: tolerance);

    final pool = orders.where((o) {
      if (o.assignedPartnerId != null) return false;
      if (o.status != OrderStatus.preparing &&
          o.status != OrderStatus.readyForPickup) {
        return false;
      }
      if (o.estimatedReadyTime == null) return false;
      return true;
    }).toList();

    final groups = <(String building, String block), List<Order>>{};
    for (final order in pool) {
      final key = (order.building, order.block);
      groups.putIfAbsent(key, () => []).add(order);
    }

    final allBatches = <DeliveryBatch>[];

    for (final entry in groups.entries) {
      final building = entry.key.$1;
      final block = entry.key.$2;
      final groupOrders = entry.value;

      groupOrders.sort((a, b) {
        final t = a.estimatedReadyTime!.compareTo(b.estimatedReadyTime!);
        if (t != 0) return t;
        return a.id.compareTo(b.id);
      });

      int i = 0;
      while (i < groupOrders.length) {
        final batchStartOrder = groupOrders[i];
        final batchStartReadyTime = batchStartOrder.estimatedReadyTime!;
        final batchCutoff = batchStartReadyTime.add(toleranceDuration);

        final batchOrders = <Order>[batchStartOrder];
        i++;

        while (i < groupOrders.length &&
            batchOrders.length < maxSize &&
            (groupOrders[i].estimatedReadyTime!.isBefore(batchCutoff) ||
                groupOrders[i]
                    .estimatedReadyTime!
                    .isAtSameMomentAs(batchCutoff))) {
          batchOrders.add(groupOrders[i]);
          i++;
        }

        final stops = batchOrders.map(DeliveryOrder.fromOrder).toList();

        stops.sort((a, b) {
          final f = a.floor.compareTo(b.floor);
          if (f != 0) return f;
          final r = a.room.compareTo(b.room);
          if (r != 0) return r;
          return a.orderId.compareTo(b.orderId);
        });

        allBatches.add(
          DeliveryBatch.fromStops(
            building: building,
            block: block,
            stops: stops,
          ),
        );
      }
    }

    allBatches.sort((a, b) {
      final w = a.windowStart.compareTo(b.windowStart);
      if (w != 0) return w;
      final blk = a.block.compareTo(b.block);
      if (blk != 0) return blk;
      return a.id.compareTo(b.id);
    });

    return allBatches;
  }

  static List<DeliveryOrder> nearbyOrders({
    required List<Order> orders,
    required String building,
    required String block,
    required int floor,
    int limit = 10,
  }) {
    final pool = orders.where((o) {
      if (o.assignedPartnerId != null) return false;
      if (o.status != OrderStatus.preparing &&
          o.status != OrderStatus.readyForPickup) {
        return false;
      }
      if (o.estimatedReadyTime == null) return false;
      if (o.building != building) return false;
      return true;
    }).toList();

    pool.sort((a, b) {
      final aSameBlock = a.block == block;
      final bSameBlock = b.block == block;
      if (aSameBlock != bSameBlock) {
        return aSameBlock ? -1 : 1;
      }

      final aDist = (a.floor - floor).abs();
      final bDist = (b.floor - floor).abs();
      final distDiff = aDist.compareTo(bDist);
      if (distDiff != 0) return distDiff;

      final timeDiff = a.estimatedReadyTime!.compareTo(b.estimatedReadyTime!);
      if (timeDiff != 0) return timeDiff;

      return a.id.compareTo(b.id);
    });

    return pool.take(limit).map(DeliveryOrder.fromOrder).toList();
  }
}
