import 'dart:math';

String generatePartnerId(
  bool Function(String id) exists, [
  Random? rng,
]) {
  final random = rng ?? Random();
  while (true) {
    final digits = random.nextInt(1000000).toString().padLeft(6, '0');
    final candidate = 'partner-$digits';
    if (!exists(candidate)) {
      return candidate;
    }
  }
}
