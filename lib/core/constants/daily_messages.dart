abstract final class DailyMessages {
  static const List<String> welcomeQuotes = [
    'Small steps every day lead to big achievements.',
    'Stay focused, stay curious, have a great day on campus!',
    'Make today count with passion and curiosity.',
    'Every lecture is an opportunity to learn something new.',
    'Believe in your potential and keep striving forward.',
    'Your hard work today shapes your tomorrow.',
    'Embrace the journey, enjoy campus life!',
  ];

  static const List<String> foodHooks = [
    'Are you hungry?',
    'Hot snacks between lectures?',
    'Beat the canteen rush!',
    'Craving something delicious?',
    'Fuel up for your next class!',
    'Fresh bites waiting for you!',
  ];

  static const List<String> busHooks = [
    'Check your bus',
    "Don't miss your ride!",
    'Track your campus bus live',
    'Check route & arrival time',
    'Heading home? Check bus status',
    'Live campus bus updates',
  ];

  static const List<String> stationaryHooks = [
    'Quick printouts',
    'Need urgent lab prints?',
    'Print assignments in seconds',
    'Skip the stationary queue!',
    'Notes, pens & instant prints',
    'Ready for submission? Print now',
  ];

  static String pick(List<String> list, [DateTime? now]) =>
      list[(now ?? DateTime.now()).day % list.length];

  static String get welcome => pick(welcomeQuotes);
  static String get foodHook => pick(foodHooks);
  static String get busHook => pick(busHooks);
  static String get stationaryHook => pick(stationaryHooks);
}
