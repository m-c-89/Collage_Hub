import 'package:flutter_test/flutter_test.dart';

import 'package:college_canteen/features/vendor/services/proposal_defaults.dart';

void main() {
  group('proposal_defaults', () {
    test('18 -> 20', () {
      expect(defaultProposedPrepMinutes([18]), 20);
    });

    test('20 -> 20', () {
      expect(defaultProposedPrepMinutes([20]), 20);
    });

    test('21 -> 25', () {
      expect(defaultProposedPrepMinutes([21]), 25);
    });

    test('empty -> 5', () {
      expect(defaultProposedPrepMinutes([]), 5);
    });

    test('0 -> 5', () {
      expect(defaultProposedPrepMinutes([0]), 5);
    });

    test('130 -> 120', () {
      expect(defaultProposedPrepMinutes([130]), 120);
    });

    test('mixed [10, 35, 20] -> 35', () {
      expect(defaultProposedPrepMinutes([10, 35, 20]), 35);
    });
  });
}
