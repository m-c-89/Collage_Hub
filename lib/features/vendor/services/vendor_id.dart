import 'dart:math';

String slugifyVendorName(String name) {
  final buffer = StringBuffer();
  var prevIsHyphen = false;
  for (final rune in name.toLowerCase().runes) {
    final isAlphaNum =
        (rune >= 97 && rune <= 122) || (rune >= 48 && rune <= 57);
    if (isAlphaNum) {
      buffer.writeCharCode(rune);
      prevIsHyphen = false;
    } else if (!prevIsHyphen && buffer.isNotEmpty) {
      buffer.write('-');
      prevIsHyphen = true;
    }
  }
  var result = buffer.toString();
  while (result.endsWith('-')) {
    result = result.substring(0, result.length - 1);
  }
  return result.isEmpty ? 'vendor' : result;
}

String generateVendorId(
  String name,
  bool Function(String id) exists,
  Random rng,
) {
  final slug = slugifyVendorName(name);
  while (true) {
    final digits = rng.nextInt(10000).toString().padLeft(4, '0');
    final candidate = '$slug-$digits';
    if (!exists(candidate)) {
      return candidate;
    }
  }
}
