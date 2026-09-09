import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — a method on a type you do not own', () {
    test('adds up the squares', () {
      expect([1, 2, 3].sumOfSquares, 14);
      expect([5].sumOfSquares, 25);
    });

    test('and answers zero for nothing at all', () {
      expect(<int>[].sumOfSquares, 0);
      expect([0, 0].sumOfSquares, 0);
    });
  });

  group('challenge 2 — a percentage that checks itself', () {
    test('refuses a number that is not a percentage', () {
      expect(() => Percent.of(101), throwsA(isA<AssertionError>()));
      expect(() => Percent.of(-1), throwsA(isA<AssertionError>()));
    });

    test('and accepts both ends of the range', () {
      expect(Percent.of(0).value, 0);
      expect(Percent.of(100).value, 100);
    });

    test('and takes its share of an amount', () {
      expect(Percent(25).applied(400), 100);
      expect(Percent(33).applied(100), 33);
      expect(Percent(0).applied(999), 0);
    });
  });

  group('challenge 3 — two units that cannot be swapped', () {
    test('converts one into the other', () {
      expect(Metres(2).asCentimetres.value, 200);
      expect(Metres(0).asCentimetres.value, 0);
    });

    test('and says a length the way a person would', () {
      expect(describe(Centimetres(250)), '2m 50cm');
      expect(describe(Centimetres(0)), '0m 0cm');
      expect(describe(Centimetres(7)), '0m 7cm');
    });
  });
}
