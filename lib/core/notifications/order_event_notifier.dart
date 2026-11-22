import 'dart:async';

import 'package:college_canteen/core/notifications/app_notification.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/services/order_notifications.dart';

class OrderEventNotifier {
  final OrderRepository _orderRepository;
  final AppNotificationService _notificationService;
  final DateTime Function() _clock;
  StreamSubscription<List<Order>>? _subscription;
  List<Order>? _previousOrders;

  OrderEventNotifier({
    required OrderRepository orderRepository,
    required AppNotificationService notificationService,
    DateTime Function()? clock,
  })  : _orderRepository = orderRepository,
        _notificationService = notificationService,
        _clock = clock ?? DateTime.now {
    _start();
  }

  void _start() {
    _subscription = _orderRepository.watchOrders().listen((orders) {
      if (_previousOrders == null) {
        // IGNORES the first emission
        _previousOrders = List<Order>.from(orders);
        return;
      }
      final diff = diffOrderNotifications(_previousOrders!, orders, _clock());
      _previousOrders = List<Order>.from(orders);
      for (final n in diff) {
        _notificationService.notify(n);
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
