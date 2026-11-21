String formatRupees(int amount) {
  final isNegative = amount < 0;
  final s = amount.abs().toString();
  if (s.length <= 3) {
    return isNegative ? '-₹$s' : '₹$s';
  }
  final lastThree = s.substring(s.length - 3);
  var remaining = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (remaining.length > 2) {
    parts.add(remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }
  if (remaining.isNotEmpty) {
    parts.add(remaining);
  }
  final grouped = '${parts.reversed.join(',')},$lastThree';
  return isNegative ? '-₹$grouped' : '₹$grouped';
}
