import 'package:ch24_expenses/expenses.dart';
import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — show', () {
    test('prints the amount, on stdout, and exits zero', () {
      final outcome = runMore(['show', '12.50']);
      expect(outcome.code, okay);
      expect(outcome.out, '£12.50');
      expect(outcome.err, isEmpty);
    });

    test('and refuses what it cannot read, on stderr', () {
      final outcome = runMore(['show', 'abc']);
      expect(outcome.code, misuse);
      expect(outcome.err, "'abc' is not an amount");
      expect(outcome.out, isEmpty);
    });
  });

  group('challenge 2 — total', () {
    test('adds up what it is given', () {
      expect(runMore(['total', '1.00', '2.50']).out, '£3.50');
      expect(runMore(['total', '0.05']).out, '£0.05');
    });

    test('refuses the whole command if any one amount is unreadable', () {
      final outcome = runMore(['total', '1.00', 'abc', '2.50']);
      expect(outcome.code, misuse);
      expect(outcome.out, isEmpty, reason: 'a partial total is a wrong total');
    });

    test('and needs at least one amount', () {
      expect(runMore(['total']).code, misuse);
    });
  });

  group('challenge 3 — flags', () {
    test('the help flags do what help does', () {
      expect(runMore(['--help']).out, usage);
      expect(runMore(['-h']).code, okay);
    });

    test('and an unknown flag is its own kind of mistake', () {
      expect(runMore(['-x']).err, "no flag named '-x'");
      expect(runMore(['-x']).code, misuse);
    });
  });
}
