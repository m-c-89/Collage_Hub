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

    // Sales count only if isConfirmed, not cancelled, and confirmedAt (device-local day) is today
    final todaysSales = vendorOrders.where((o) {
      if (!o.isConfirmed) return false;
      if (o.status == OrderStatus.cancelled) return false;
      final confAt = o.confirmedAt;
      return confAt != null && isSameDay(confAt, now);
    }).toList();

    final todaysOrdersCount = todaysSales.length;
    final todaysRevenue =
        todaysSales.fold<int>(0, (sum, o) => sum + o.subtotal);

    final completedToday = vendorOrders.where((o) {
      if (o.status != OrderStatus.delivered) return false;
      final delTime = getDeliveredTime(o);
      return delTime != null && isSameDay(delTime, now);
    }).length;

    final averageOrderValue = todaysOrdersCount == 0
        ? 0
        : (todaysRevenue / todaysOrdersCount).round();

    final itemQuantities = <String, int>{};
    for (final order in todaysSales) {
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

    final completedSinceLastAnalysis = vendorOrders.where((o) {
      if (o.status != OrderStatus.delivered) return false;
      final delTime = getDeliveredTime(o);
      return delTime != null && delTime.isAfter(lastAnalysisAt);
    }).length;

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
