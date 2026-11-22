import 'package:college_canteen/core/config/app_config.dart';

abstract final class TripRules {
  static bool canTakeOrders({
    required int activeCount,
    required int adding,
  }) {
    return activeCount + adding <= AppConfig.maxActiveTripOrders;
  }
}

bool canTakeOrders({
  required int activeCount,
  required int adding,
}) =>
    TripRules.canTakeOrders(
      activeCount: activeCount,
      adding: adding,
    );
