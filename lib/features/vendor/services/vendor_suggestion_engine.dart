import 'package:college_canteen/features/food/models/feedback.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';

enum SuggestionType {
  bestsellers,
  lowRated,
  praised,
  slowMover,
  peakHour,
}

class Suggestion {
  final SuggestionType type;
  final String title;
  final String detail;
  final String? itemId;
  final int severity;

  const Suggestion({
    required this.type,
    required this.title,
    required this.detail,
    this.itemId,
    required this.severity,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestion &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          title == other.title &&
          detail == other.detail &&
          itemId == other.itemId &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(type, title, detail, itemId, severity);

  @override
  String toString() =>
      'Suggestion(type: $type, title: $title, severity: $severity, itemId: $itemId)';
}

abstract final class VendorSuggestionEngine {
  static List<Suggestion> generate({
    required List<Order> deliveredOrdersInWindow,
    required List<OrderFeedback> feedback,
    required List<MenuItem> menu,
  }) {
    final suggestions = <Suggestion>[];

    // 1. Count quantities of each item ordered in window
    final itemQuantities = <String, int>{};
    final itemIdQuantities = <String, int>{};
    for (final order in deliveredOrdersInWindow) {
      for (final item in order.items) {
        itemQuantities[item.name] =
            (itemQuantities[item.name] ?? 0) + item.quantity;
        itemIdQuantities[item.itemId] =
            (itemIdQuantities[item.itemId] ?? 0) + item.quantity;
      }
    }

    // Rule: bestsellers = top 3 items by quantity ("Your bestsellers"), severity 20
    final sortedItemQuantities = itemQuantities.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sortedItemQuantities.take(3).toList();
    if (top3.isNotEmpty) {
      final details = top3.map((e) => '${e.key} (${e.value})').join(', ');
      suggestions.add(
        Suggestion(
          type: SuggestionType.bestsellers,
          title: 'Your bestsellers',
          detail: details,
          severity: 20,
        ),
      );
    }

    // Rule: feedback ratings
    // (a feedback entry counts toward every item in its order)
    final itemRatings = <String, List<int>>{};
    for (final fb in feedback) {
      for (final itemId in fb.itemIds) {
        itemRatings.putIfAbsent(itemId, () => []).add(fb.rating);
      }
    }

    for (final item in menu) {
      final ratings = itemRatings[item.id];
      if (ratings != null && ratings.length >= 3) {
        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        // lowRated = an item whose average rating is < 3.0 with >= 3 ratings, severity 90
        if (avg < 3.0) {
          suggestions.add(
            Suggestion(
              type: SuggestionType.lowRated,
              title: 'Low rating: ${item.name}',
              detail:
                  'Average rating is ${avg.toStringAsFixed(1)} based on ${ratings.length} reviews',
              itemId: item.id,
              severity: 90,
            ),
          );
        }
        // praised = average >= 4.5 with >= 3 ratings, severity 30
        else if (avg >= 4.5) {
          suggestions.add(
            Suggestion(
              type: SuggestionType.praised,
              title: 'Praised: ${item.name}',
              detail:
                  'Average rating is ${avg.toStringAsFixed(1)} based on ${ratings.length} reviews',
              itemId: item.id,
              severity: 30,
            ),
          );
        }
      }
    }

    // Rule: slowMover = an available menu item with 0 orders in the window,
    // ONLY when the window has >= 20 orders ("Consider a discount or removing it"), severity 60
    if (deliveredOrdersInWindow.length >= 20) {
      for (final item in menu) {
        final qty = itemIdQuantities[item.id] ?? 0;
        if (item.isAvailable && qty == 0) {
          suggestions.add(
            Suggestion(
              type: SuggestionType.slowMover,
              title: 'Slow mover: ${item.name}',
              detail: 'Consider a discount or removing it',
              itemId: item.id,
              severity: 60,
            ),
          );
        }
      }
    }

    // Rule: peakHour = the hour of day (from placedAt) with the most orders
    // ("Prepare ahead before {hour}"), only when the window has >= 10 orders, severity 40
    if (deliveredOrdersInWindow.length >= 10) {
      final hourCounts = <int, int>{};
      for (final order in deliveredOrdersInWindow) {
        final h = order.placedAt.hour;
        hourCounts[h] = (hourCounts[h] ?? 0) + 1;
      }

      int? peakHour;
      int maxHourOrders = 0;
      for (var h = 0; h < 24; h++) {
        final count = hourCounts[h] ?? 0;
        if (count > maxHourOrders) {
          maxHourOrders = count;
          peakHour = h;
        }
      }

      if (peakHour != null) {
        final hourStr = '${peakHour.toString().padLeft(2, '0')}:00';
        suggestions.add(
          Suggestion(
            type: SuggestionType.peakHour,
            title: 'Peak ordering hour ($hourStr)',
            detail: 'Prepare ahead before $hourStr',
            severity: 40,
          ),
        );
      }
    }

    // Sorted by severity descending, then title ascending
    suggestions.sort((a, b) {
      final s = b.severity.compareTo(a.severity);
      if (s != 0) return s;
      return a.title.compareTo(b.title);
    });

    return suggestions;
  }
}
