import 'package:ch24_expenses/expenses.dart';
import 'package:test/test.dart';

void main() {
  group('reading an amount a person typed', () {
    test('takes pounds and pence, and pounds alone', () {
      expect(penceFrom('12.50'), 1250);
      expect(penceFrom('0.05'), 5);
      expect(penceFrom('12'), 1200);
    });

    test('and answers null for anything it cannot read', () {
      expect(penceFrom('abc'), isNull);
      expect(penceFrom(''), isNull);
      expect(penceFrom('12.5'), isNull, reason: 'pence are two digits');
      expect(penceFrom('12.505'), isNull);
      expect(penceFrom('1.2.3'), isNull);
    });
  });

  group('a run that worked', () {
    test('says what it recorded, on stdout, and exits zero', () {
      final outcome = run(['add', '12.50', 'coffee']);
      expect(outcome.code, okay);
      expect(outcome.out, '£12.50  coffee');
      expect(outcome.err, isEmpty);
    });

    test('keeps a note of several words whole', () {
      expect(run(['add', '3.20', 'bus', 'fare']).out, '£3.20  bus fare');
    });

    test('with no arguments at all, prints how to use it', () {
      final outcome = run([]);
      expect(outcome.code, okay);
      expect(outcome.out, startsWith('usage: expenses'));
    });
  });

  group('a run that did not', () {
    test('an amount nobody can read is misuse, and says so on stderr', () {
      final outcome = run(['add', 'abc', 'coffee']);
      expect(outcome.code, misuse);
      expect(outcome.err, "'abc' is not an amount");
      expect(outcome.out, isEmpty, reason: 'nothing worked, so nothing to say');
    });

    test('a missing note is misuse', () {
      expect(run(['add', '12.50']).code, misuse);
    });

    test('a command nobody has heard of is misuse', () {
      expect(run(['fly']).err, "no command named 'fly'");
    });

    test('an amount the domain refuses is refused, not misuse', () {
      // The reader typed something readable. Money is what said no.
      final outcome = run(['add', '-5', 'coffee']);
      expect(outcome.code, refused);
      expect(outcome.err, 'money is never negative');
    });
  });
}
