import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/order.dart';

class VendorAnalyticsResult {
  final int todaysOrders;
  final int todaysRevenue;
  final int completedToday;
  final int averageOrderValue;
  final String? topItemName;
  final int topItemQuantity;
  final int completedSinceLastAnalysis;
  final int threshold;
  final double progress;

  const VendorAnalyticsResult({
    required this.todaysOrders,
    required this.todaysRevenue,
    required this.completedToday,
    required this.averageOrderValue,
    this.topItemName,
    required this.topItemQuantity,
    required this.completedSinceLastAnalysis,
    required this.threshold,
    required this.progress,
  });

  @override
  String toString() =>
      'VendorAnalyticsResult(todaysOrders: $todaysOrders, todaysRevenue: $todaysRevenue, averageOrderValue: $averageOrderValue, topItem: $topItemName ($topItemQuantity), progress: $progress)';
}

abstract final class VendorAnalytics {
  static VendorAnalyticsResult compute({
    required List<Order> orders,
    required String vendorId,
    required DateTime now,
    required DateTime lastAnalysisAt,
    required int threshold,
  }) {
    // 1. Only the given vendor's orders
    final vendorOrders = orders.where((o) => o.vendorId == vendorId).toList();

    // Helper: device-local same calendar day
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    // Helper: get delivered timestamp from order
    DateTime? getDeliveredTime(Order o) {
      for (final entry in o.statusHistory) {
        if (entry.$1 == OrderStatus.delivered) {
          return entry.$2;
        }
      }
      return null;
    }

    // "today" = the same device-local calendar day as now, using placedAt
    final todaysPlaced = vendorOrders.where((o) => isSameDay(o.placedAt, now));

    // todaysOrders = status != cancelled
    final todaysNonCancelled =
        todaysPlaced.where((o) => o.status != OrderStatus.cancelled).toList();
    final todaysOrdersCount = todaysNonCancelled.length;

    // todaysRevenue = sum of subtotal of those orders (food revenue only; excludes delivery fee and tax)
    final todaysRevenue =
        todaysNonCancelled.fold<int>(0, (sum, o) => sum + o.subtotal);

    // completedToday = delivered orders whose delivered time (taken from statusHistory) is today
    final completedToday = vendorOrders.where((o) {
      if (o.status != OrderStatus.delivered) return false;
      final delTime = getDeliveredTime(o);
      return delTime != null && isSameDay(delTime, now);
    }).length;

    // averageOrderValue = (todaysRevenue / todaysOrders).round(), 0 if none
    final averageOrderValue = todaysOrdersCount == 0
        ? 0
        : (todaysRevenue / todaysOrdersCount).round();

    // top item = highest total quantity across today's non-cancelled orders
    final itemQuantities = <String, int>{};
    for (final order in todaysNonCancelled) {
      for (final item in order.items) {
        itemQuantities[item.name] =
            (itemQuantities[item.name] ?? 0) + item.quantity;
      }
    }

    String? topItemName;
    int topItemQuantity = 0;
    for (final entry in itemQuantities.entries) {
      if (entry.value > topItemQuantity) {
        topItemQuantity = entry.value;
        topItemName = entry.key;
      }
    }

    // completedSinceLastAnalysis = delivered orders whose delivered time is after lastAnalysisAt
    final completedSinceLastAnalysis = vendorOrders.where((o) {
      if (o.status != OrderStatus.delivered) return false;
      final delTime = getDeliveredTime(o);
      return delTime != null && delTime.isAfter(lastAnalysisAt);
    }).length;

    // progress (0..1 clamped)
    final double rawProgress = threshold > 0
        ? completedSinceLastAnalysis / threshold
        : 1.0;
    final progress = rawProgress.clamp(0.0, 1.0);

    return VendorAnalyticsResult(
      todaysOrders: todaysOrdersCount,
      todaysRevenue: todaysRevenue,
      completedToday: completedToday,
      averageOrderValue: averageOrderValue,
      topItemName: topItemName,
      topItemQuantity: topItemQuantity,
      completedSinceLastAnalysis: completedSinceLastAnalysis,
      threshold: threshold,
      progress: progress,
    );
  }
}

bool shouldRefreshAnalysis(int completedSince, int threshold) =>
    completedSince >= threshold;

int clampThreshold(int v) =>
    v.clamp(AppConfig.minAnalyticsBatchSize, AppConfig.maxAnalyticsBatchSize);
