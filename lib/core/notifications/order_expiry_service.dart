import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/services/app_logger.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';

class OrderExpiryService with WidgetsBindingObserver {
  final OrderRepository _orderRepository;
  Timer? _timer;
  bool _disposed = false;

  OrderExpiryService({
    required OrderRepository orderRepository,
    bool autoStart = true,
  }) : _orderRepository = orderRepository {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    if (autoStart) {
      start();
    }
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: AppConfig.orderExpirySweepSeconds),
      (_) => sweep(),
    );
  }

  Future<void> sweep() async {
    if (_disposed) return;
    try {
      await _orderRepository.expireStaleOrders();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to expire stale orders',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sweep();
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
  }
}
