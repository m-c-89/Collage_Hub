import 'package:college_canteen/features/food/models/order.dart';

abstract final class DeliveryFormatters {
  static String formatTimeWindow(DateTime start, DateTime end) {
    int hour12(int h) {
      final val = h % 12;
      return val == 0 ? 12 : val;
    }

    String amPm(int h) => h < 12 ? 'AM' : 'PM';
    String pad2(int n) => n.toString().padLeft(2, '0');

    final startPeriod = amPm(start.hour);
    final endPeriod = amPm(end.hour);
    final startMin = pad2(start.minute);
    final endMin = pad2(end.minute);

    if (startPeriod == endPeriod) {
      return '${hour12(start.hour)}:$startMin \u2013 ${hour12(end.hour)}:$endMin $endPeriod';
    } else {
      return '${hour12(start.hour)}:$startMin $startPeriod \u2013 ${hour12(end.hour)}:$endMin $endPeriod';
    }
  }

  static String formatItemsSummary(List<OrderItem> items) {
    return items.map((i) => '${i.quantity}\u00D7 ${i.name}').join(', ');
  }
}

String formatTimeWindow(DateTime start, DateTime end) =>
    DeliveryFormatters.formatTimeWindow(start, end);

String formatItemsSummary(List<OrderItem> items) =>
    DeliveryFormatters.formatItemsSummary(items);
