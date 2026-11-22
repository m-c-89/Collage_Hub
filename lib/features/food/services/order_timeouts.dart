import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/features/food/models/order.dart';

abstract final class OrderTimeouts {
  static Duration? limitFor(Order order) {
    return switch (order.status) {
      OrderStatus.placed =>
        const Duration(minutes: AppConfig.vendorResponseTimeoutMinutes),
      OrderStatus.etaProposed =>
        const Duration(minutes: AppConfig.etaResponseTimeoutMinutes),
      OrderStatus.etaAgreed =>
        const Duration(minutes: AppConfig.vendorAcceptTimeoutMinutes),
      OrderStatus.accepted when order.paymentStatus == PaymentStatus.unpaid =>
        const Duration(minutes: AppConfig.paymentWindowMinutes),
      _ => null,
    };
  }

  static DateTime? deadlineFor(Order order) {
    final limit = limitFor(order);
    if (limit == null) return null;
    return order.stageEnteredAt.add(limit);
  }

  static bool isExpired(Order order, DateTime now) {
    final deadline = deadlineFor(order);
    if (deadline == null) return false;
    return !now.isBefore(deadline);
  }

  static CancelReason? reasonFor(Order order) {
    return switch (order.status) {
      OrderStatus.placed || OrderStatus.etaAgreed =>
        CancelReason.vendorNoResponse,
      OrderStatus.etaProposed =>
        CancelReason.customerNoResponse,
      OrderStatus.accepted when order.paymentStatus == PaymentStatus.unpaid =>
        CancelReason.paymentTimeout,
      _ => null,
    };
  }

  static int secondsRemaining(Order order, DateTime now) {
    final deadline = deadlineFor(order);
    if (deadline == null) return 0;
    final diff = deadline.difference(now).inSeconds;
    return diff < 0 ? 0 : diff;
  }
}
