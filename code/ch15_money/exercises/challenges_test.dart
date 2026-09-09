import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — a weight that reads itself out', () {
    test('counts whole kilograms', () {
      expect(Grams(1500).kilos, 1);
      expect(Grams(900).kilos, 0);
      expect(Grams(2000).kilos, 2);
    });

    test('writes grams below a kilogram and kilograms above', () {
      expect(Grams(1500).format(), '1.5kg');
      expect(Grams(1050).format(), '1.05kg');
      expect(Grams(900).format(), '900g');
      expect(Grams(2000).format(), '2.0kg');
    });
  });

  group('challenge 2 — two names for one slot', () {
    test('two slots with the same day and hour are equal', () {
      expect(Slot('tuesday', 9) == Slot('tuesday', 9), isTrue);
      expect(Slot('tuesday', 9) == Slot('tuesday', 10), isFalse);
      expect(Slot('monday', 9) == Slot('tuesday', 9), isFalse);
    });

    test('and a map agrees with them', () {
      final booked = {Slot('tuesday', 9): 'dentist'};
      expect(booked[Slot('tuesday', 9)], 'dentist');
    });
  });

  group('challenge 3 — a number that cannot be wrong', () {
    test('refuses to exist outside its range', () {
      expect(() => Percent(101), throwsA(isA<AssertionError>()));
      expect(() => Percent(-1), throwsA(isA<AssertionError>()));
    });

    test('allows the ends of the range', () {
      expect(Percent(0).value, 0);
      expect(Percent(100).value, 100);
    });

    test('and clamps anything handed to it that way instead', () {
      expect(Percent.clamped(140).value, 100);
      expect(Percent.clamped(-3).value, 0);
      expect(Percent.clamped(42).value, 42);
    });
  });
}
