import 'package:ch27_expenses/expenses.dart';
import 'package:test/test.dart';

void main() {
  late Store store;
  // #region setup
  /// The two things the program used to reach out for, made into two values a
  /// test controls. `setUp` runs before every `test`, so no test can be handed
  /// a store another test has already written to.
  final today = Day(2026, 9, 9);
  setUp(() => store = InMemoryStore());
  // #endregion setup

  group('a run that worked', () {
    test('records what it was given and says so', () {
      final outcome = run(['add', '12.50', 'Food', 'coffee'], store, today);
      expect(outcome.code, okay);
      expect(outcome.err, isEmpty);
      expect(outcome.out, contains('£12.50'));
      expect(outcome.out, contains('coffee'));
      expect(store.all.single.category, Category('food'));
    });

    // #region day
    test('and dates it the day it was handed, not the day it ran', () {
      final outcome = run(['add', '12.50', 'food', 'coffee'], store, today);
      expect(store.all.single.day, today);
      expect(outcome.out, startsWith('2026-09-09'));
    });
    // #endregion day

    test('keeps a note of several words whole', () {
      run(['add', '3.20', 'transport', 'bus', 'fare'], store, today);
      expect(store.all.single.note, 'bus fare');
    });

    test('with nothing recorded, list says so', () {
      expect(run(['list'], store, today).out, 'nothing recorded yet');
    });

    test('and otherwise lists what is there, with totals', () {
      run(['add', '1.00', 'food', 'apple'], store, today);
      run(['add', '2.50', 'food', 'soup'], store, today);
      run(['add', '3.00', 'transport', 'bus'], store, today);
      final out = run(['list'], store, today).out;
      expect(out, contains('food: £3.50'));
      expect(out, contains('transport: £3.00'));
    });

    test('with no arguments at all, prints how to use it', () {
      expect(run([], store, today).out, startsWith('usage: expenses'));
    });
  });

  group('a run that did not', () {
    test('an amount nobody can read is misuse, and records nothing', () {
      final outcome = run(['add', 'abc', 'food', 'coffee'], store, today);
      expect(outcome.code, misuse);
      expect(outcome.err, '"abc" is not digits');
      expect(store.all, isEmpty);
    });

    test('a missing note is misuse', () {
      expect(run(['add', '12.50', 'food'], store, today).code, misuse);
    });

    test('a command nobody has heard of is misuse', () {
      expect(run(['fly'], store, today).err, "no command named 'fly'");
    });

    test('an amount the domain refuses is refused, not misuse', () {
      final outcome = run(['add', '-5', 'food', 'coffee'], store, today);
      expect(outcome.code, refused);
      expect(store.all, isEmpty, reason: 'a refused expense is not recorded');
    });
  });
}
