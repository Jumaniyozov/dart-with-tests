import 'package:ch25_expenses/expenses.dart';
import 'package:test/test.dart';

void main() {
  late Store store;
  setUp(() => store = Store());

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
      expect(penceFrom('1.2.3'), isNull);
    });
  });

  group('a run that worked', () {
    test('records what it was given and says so', () {
      final outcome = run(['add', '12.50', 'Food', 'coffee'], store);
      expect(outcome.code, okay);
      expect(outcome.err, isEmpty);
      expect(outcome.out, contains('£12.50'));
      expect(outcome.out, contains('coffee'));
      expect(store.all.single.category, Category('food'));
    });

    test('keeps a note of several words whole', () {
      run(['add', '3.20', 'transport', 'bus', 'fare'], store);
      expect(store.all.single.note, 'bus fare');
    });

    test('with nothing recorded, list says so', () {
      expect(run(['list'], store).out, 'nothing recorded yet');
    });

    test('and otherwise lists what is there, with totals', () {
      run(['add', '1.00', 'food', 'apple'], store);
      run(['add', '2.50', 'food', 'soup'], store);
      run(['add', '3.00', 'transport', 'bus'], store);
      final out = run(['list'], store).out;
      expect(out, contains('food: £3.50'));
      expect(out, contains('transport: £3.00'));
    });

    test('with no arguments at all, prints how to use it', () {
      expect(run([], store).out, startsWith('usage: expenses'));
    });
  });

  group('a run that did not', () {
    test('an amount nobody can read is misuse, and records nothing', () {
      final outcome = run(['add', 'abc', 'food', 'coffee'], store);
      expect(outcome.code, misuse);
      expect(outcome.err, "'abc' is not an amount");
      expect(store.all, isEmpty);
    });

    test('a missing note is misuse', () {
      expect(run(['add', '12.50', 'food'], store).code, misuse);
    });

    test('a command nobody has heard of is misuse', () {
      expect(run(['fly'], store).err, "no command named 'fly'");
    });

    test('an amount the domain refuses is refused, not misuse', () {
      final outcome = run(['add', '-5', 'food', 'coffee'], store);
      expect(outcome.code, refused);
      expect(store.all, isEmpty, reason: 'a refused expense is not recorded');
    });
  });
}
