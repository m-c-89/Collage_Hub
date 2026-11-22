import 'package:college_canteen/core/config/app_config.dart';

/// Pure calculation of default proposed prep minutes for an order.
///
/// Returns the largest value rounded UP to a multiple of 5, clamped to
/// [AppConfig.minProposedPrepMinutes]..[AppConfig.maxProposedPrepMinutes];
/// defaults to 5 when empty.
int defaultProposedPrepMinutes(Iterable<int> itemPrepMaxMinutes) {
  if (itemPrepMaxMinutes.isEmpty) {
    return AppConfig.minProposedPrepMinutes;
  }
  var maxMinutes = 0;
  for (final m in itemPrepMaxMinutes) {
    if (m > maxMinutes) {
      maxMinutes = m;
    }
  }
  final roundedUp = (maxMinutes <= 0) ? 0 : ((maxMinutes + 4) ~/ 5) * 5;
  return roundedUp.clamp(
    AppConfig.minProposedPrepMinutes,
    AppConfig.maxProposedPrepMinutes,
  );
}
