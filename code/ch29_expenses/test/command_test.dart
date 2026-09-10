import 'package:ch29_expenses/expenses.dart';
import 'package:test/test.dart';

void main() {
  // #region setup
  /// The two things the program used to reach out for, made into two values a
  /// test controls. `setUp` runs before every `test`, so no test can be handed
  /// a store another test has already written to.
  ///
  /// Every test in this file is `async` now, and not one of them tests anything
  /// about time. That is the price of study 28's interface change, paid once
  /// per test and visible here rather than argued about.
  final today = Day(2026, 9, 9);
  late Store store;
  setUp(() => store = InMemoryStore());
  // #endregion setup

  group('a run that worked', () {
    test('records what it was given and says so', () async {
      final outcome = await run(
        ['add', '12.50', 'Food', 'coffee'],
        store,
        today,
      );
      expect(outcome.code, okay);
      expect(outcome.err, isEmpty);
      expect(outcome.out, contains('£12.50'));
      expect(outcome.out, contains('coffee'));
      expect((await store.all).single.category, Category('food'));
    });

    // #region day
    test('and dates it the day it was handed, not the day it ran', () async {
      final outcome = await run(
        ['add', '12.50', 'food', 'coffee'],
        store,
        today,
      );
      expect((await store.all).single.day, today);
      expect(outcome.out, startsWith('2026-09-09'));
    });
    // #endregion day

    test('keeps a note of several words whole', () async {
      await run(['add', '3.20', 'transport', 'bus', 'fare'], store, today);
      expect((await store.all).single.note, 'bus fare');
    });

    test('with nothing recorded, list says so', () async {
      expect((await run(['list'], store, today)).out, 'nothing recorded yet');
    });

    test('and otherwise lists what is there, with totals', () async {
      await run(['add', '1.00', 'food', 'apple'], store, today);
      await run(['add', '2.50', 'food', 'soup'], store, today);
      await run(['add', '3.00', 'transport', 'bus'], store, today);
      final out = (await run(['list'], store, today)).out;
      expect(out, contains('food: £3.50'));
      expect(out, contains('transport: £3.00'));
    });

    test('with no arguments at all, prints how to use it', () async {
      expect((await run([], store, today)).out, startsWith('usage: expenses'));
    });
  });

  group('a run that did not', () {
    test('an amount nobody can read is misuse, and records nothing', () async {
      final outcome = await run(['add', 'abc', 'food', 'coffee'], store, today);
      expect(outcome.code, misuse);
      expect(outcome.err, '"abc" is not digits');
      expect(await store.all, isEmpty);
    });

    test('a missing note is misuse', () async {
      expect((await run(['add', '12.50', 'food'], store, today)).code, misuse);
    });

    test('a command nobody has heard of is misuse', () async {
      expect((await run(['fly'], store, today)).err, "no command named 'fly'");
    });

    test('an amount the domain refuses is refused, not misuse', () async {
      final outcome = await run(['add', '-5', 'food', 'coffee'], store, today);
      expect(outcome.code, refused);
      expect(
        await store.all,
        isEmpty,
        reason: 'a refused expense is not recorded',
      );
    });
  });
}
