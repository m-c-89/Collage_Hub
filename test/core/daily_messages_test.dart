import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/constants/daily_messages.dart';

void main() {
  group('DailyMessages Tests', () {
    test('list lengths match specifications', () {
      expect(DailyMessages.welcomeQuotes.length, 7);
      expect(DailyMessages.foodHooks.length, 6);
      expect(DailyMessages.busHooks.length, 6);
      expect(DailyMessages.stationaryHooks.length, 6);
    });

    test('pick helper is deterministic with explicit DateTime', () {
      // Day 14 % 7 = 0
      final dateDay14 = DateTime(2026, 11, 14);
      expect(
        DailyMessages.pick(DailyMessages.welcomeQuotes, dateDay14),
        DailyMessages.welcomeQuotes[0],
      );

      // Day 15 % 7 = 1
      final dateDay15 = DateTime(2026, 11, 15);
      expect(
        DailyMessages.pick(DailyMessages.welcomeQuotes, dateDay15),
        DailyMessages.welcomeQuotes[1],
      );

      // Day 14 % 6 = 2
      expect(
        DailyMessages.pick(DailyMessages.foodHooks, dateDay14),
        DailyMessages.foodHooks[2],
      );

      // Day 17 % 6 = 5
      final dateDay17 = DateTime(2026, 11, 17);
      expect(
        DailyMessages.pick(DailyMessages.foodHooks, dateDay17),
        DailyMessages.foodHooks[5],
      );
    });

    test('getters return valid non-empty messages from respective lists', () {
      expect(DailyMessages.welcome, isNotEmpty);
      expect(DailyMessages.welcomeQuotes.contains(DailyMessages.welcome), isTrue);

      expect(DailyMessages.foodHook, isNotEmpty);
      expect(DailyMessages.foodHooks.contains(DailyMessages.foodHook), isTrue);

      expect(DailyMessages.busHook, isNotEmpty);
      expect(DailyMessages.busHooks.contains(DailyMessages.busHook), isTrue);

      expect(DailyMessages.stationaryHook, isNotEmpty);
      expect(
        DailyMessages.stationaryHooks.contains(DailyMessages.stationaryHook),
        isTrue,
      );
    });
  });
}
