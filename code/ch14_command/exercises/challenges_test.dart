import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — reading a range', () {
    test('reads two numbers with a dash between them', () {
      expect(asRange('3-7'), (3, 7));
      expect(asRange('0-100'), (0, 100));
    });

    test('anything else is nothing', () {
      expect(asRange('3'), isNull);
      expect(asRange('3-7-9'), isNull);
      expect(asRange('a-b'), isNull);
      expect(asRange(''), isNull);
    });
  });

  group('challenge 2 — a verdict from a result', () {
    test('a failure is a failure whatever the score', () {
      expect(verdict((95, false)), 'failed');
      expect(verdict((0, false)), 'failed');
    });

    test('ninety or more, and passed, is a distinction', () {
      expect(verdict((90, true)), 'distinction');
      expect(verdict((100, true)), 'distinction');
    });

    test('passed but under ninety is a pass', () {
      expect(verdict((89, true)), 'passed');
      expect(verdict((50, true)), 'passed');
    });
  });

  group('challenge 3 — labelling a nested amount', () {
    test('writes the name and the money', () {
      expect(label(('rent', (12, 34))), r'rent £12.34');
    });

    test('pads the pence to two digits', () {
      expect(label(('bus', (0, 5))), r'bus £0.05');
      expect(label(('fee', (3, 0))), r'fee £3.00');
    });
  });
}
