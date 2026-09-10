import 'package:ch31_expenses/expenses.dart';
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

  // #region reported
  group('list prints a report now', () {
    test('dearest category first, and a total under it', () async {
      await run(['add', '1.00', 'food', 'apple'], store, Day(2026, 9, 1));
      await run(['add', '9.00', 'rent', 'room'], store, Day(2026, 9, 2));
      await run(['add', '3.00', 'transport', 'bus'], store, Day(2026, 9, 3));

      // The report is three blocks separated by blank lines: what happened,
      // where it went, then how much. The last block is the total.
      final blocks = (await run(['list'], store, today)).out.split('\n\n');
      expect(blocks, hasLength(3));
      expect(blocks[1].split('\n'), [
        'rent: £9.00',
        'transport: £3.00',
        'food: £1.00',
      ]);
      expect(blocks[2], 'total: £13.00');
    });

    test('and the expenses above it in day order, not file order', () async {
      await run(['add', '1.00', 'food', 'third'], store, Day(2026, 9, 30));
      await run(['add', '1.00', 'food', 'first'], store, Day(2026, 9, 1));
      await run(['add', '1.00', 'food', 'second'], store, Day(2026, 9, 9));

      final out = (await run(['list'], store, today)).out;
      expect(
        out.indexOf('first') < out.indexOf('second'),
        isTrue,
        reason: 'the store handed them over in the order they were recorded',
      );
      expect(out.indexOf('second') < out.indexOf('third'), isTrue);
    });
  });
  // #endregion reported

  // #region month
  group('list, given a month', () {
    /// Three expenses either side of a boundary, so that a filter which is off
    /// by one day shows up as a wrong total rather than as nothing at all.
    Future<void> spread() async {
      await run(['add', '1.00', 'food', 'august'], store, Day(2026, 8, 31));
      await run(['add', '2.50', 'food', 'first'], store, Day(2026, 9, 1));
      await run(['add', '3.00', 'transport', 'last'], store, Day(2026, 9, 30));
      await run(['add', '4.00', 'food', 'october'], store, Day(2026, 10, 1));
    }

    test('shows only that month, and totals only that month', () async {
      await spread();
      final out = (await run(['list', '2026-09'], store, today)).out;
      expect(out, contains('first'));
      expect(out, contains('last'));
      expect(out, isNot(contains('august')));
      expect(out, isNot(contains('october')));
      expect(out, contains('food: £2.50'));
      expect(out, contains('transport: £3.00'));
    });

    test('and says which days it covered', () async {
      await spread();
      final out = (await run(['list', '2026-09'], store, today)).out;
      expect(out, startsWith('2026-09-01 to 2026-09-30'));
    });

    test('which is the interesting line in February', () async {
      await run(['add', '1.00', 'food', 'february'], store, Day(2026, 2, 14));
      final out = (await run(['list', '2026-02'], store, today)).out;
      expect(out, startsWith('2026-02-01 to 2026-02-28'));
    });

    test('and in the February that has a 29th', () async {
      await run(['add', '1.00', 'food', 'leap'], store, Day(2024, 2, 29));
      final out = (await run(['list', '2024-02'], store, today)).out;
      expect(out, startsWith('2024-02-01 to 2024-02-29'));
      expect(out, contains('leap'));
    });

    test('a month with nothing in it is an answer, not a failure', () async {
      await spread();
      final outcome = await run(['list', '2026-11'], store, today);
      expect(outcome.code, okay);
      expect(outcome.out, 'nothing recorded in 2026-11');
      expect(outcome.err, isEmpty);
    });

    test('and a month nobody can read is misuse', () async {
      final outcome = await run(['list', 'September'], store, today);
      expect(outcome.code, misuse);
      expect(outcome.err, contains('is not a month'));
      expect(outcome.out, isEmpty);
    });

    test('while list on its own still shows everything', () async {
      await spread();
      final out = (await run(['list'], store, today)).out;
      expect(out, contains('august'));
      expect(out, contains('october'));
      expect(out, contains('food: £7.50'));
      expect(out, isNot(contains(' to ')), reason: 'no period, no range line');
    });

    test('and too many arguments is misuse, not an unknown command', () async {
      final outcome = await run(['list', '2026-09', 'please'], store, today);
      expect(outcome.code, misuse);
      expect(outcome.err, 'usage: expenses list [YYYY-MM]');
    });
  });
  // #endregion month

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
