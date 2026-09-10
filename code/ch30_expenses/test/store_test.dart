import 'package:ch30_expenses/expenses.dart';
import 'package:test/test.dart';

// #region spy
/// The one day everything in this file happens on. It is a value, so a test can
/// write it down; that is 27.5's half of the study, used here by the other.
final day = Day(2026, 9, 9);

/// A store that remembers how it was called and nothing else.
///
/// This is a **mock**, hand-written. `package:mockito` generates classes like
/// it, and writing one by hand is enough to show both what a mock buys and
/// what it costs.
class SpyStore implements Store {
  final List<String> calls = [];

  @override
  Future<void> record(Expense expense) async => calls.add('record');

  @override
  Future<List<Expense>> get all async {
    calls.add('all');
    return const [];
  }
}
// #endregion spy

void main() {
  // #region blind
  group('a mock knows how it was called', () {
    test('and can say record happened exactly once', () async {
      final spy = SpyStore();
      await run(['add', '12.50', 'food', 'coffee'], spy, day);
      expect(spy.calls, ['record']);
    });

    test('and cannot say what was recorded', () async {
      final spy = SpyStore();
      await run(['add', '12.50', 'food', 'coffee'], spy, day);
      expect(
        (await run(['list'], spy, day)).out,
        'nothing recorded yet',
        reason: 'it counted the call and kept nothing, so list has nothing',
      );
    });

    test('because its ledger is a record of the implementation', () async {
      final spy = SpyStore();
      await run(['add', '12.50', 'food', 'coffee'], spy, day);
      await run(['list'], spy, day);
      expect(
        spy.calls,
        ['record', 'all'],
        reason:
            'list read the store once and stopped, because it found it '
            'empty. That is a fact about how run is written, not about what '
            'the program does.',
      );
    });
  });
  // #endregion blind

  // #region fake
  group('a fake knows what happened', () {
    late Store store;
    setUp(() => store = InMemoryStore());

    test('so a test can ask what the program did, not how it did it', () async {
      await run(['add', '12.50', 'food', 'coffee'], store, day);
      final listed = (await run(['list'], store, day)).out;
      expect(listed, contains('£12.50'));
      expect(listed, contains('coffee'));
      expect(listed, contains('food: £12.50'));
    });
  });
  // #endregion fake

  group('the interface is the only thing run knows about', () {
    test('a store that keeps only the last expense works unchanged', () async {
      final store = LastOnlyStore();
      await run(['add', '1.00', 'food', 'apple'], store, day);
      await run(['add', '2.00', 'food', 'soup'], store, day);
      expect((await store.all).single.note, 'soup');
      expect((await run(['list'], store, day)).out, contains('food: £2.00'));
    });
  });

  // #region derived
  group('totals is derived, and no longer asks the store for it', () {
    test('any expenses at all will do, including none', () {
      expect(<Expense>[].totals, isEmpty);
    });

    test('and a store hands its own over like any other list', () async {
      final store = InMemoryStore();
      await store.record(
        Expense(Money.fromPence(250), Category('food'), day, 'soup'),
      );
      expect((await store.all).totals, {
        Category('food'): Money.fromPence(250),
      });
    });

    test('so half a store totals too, which is what study 30 needed', () async {
      final store = InMemoryStore();
      final august = Expense(
        Money.fromPence(100),
        Category('food'),
        Day(2026, 8, 31),
        'apple',
      );
      final september = Expense(
        Money.fromPence(250),
        Category('food'),
        day,
        'soup',
      );
      await store.record(august);
      await store.record(september);

      final month = Period(2026, 9);
      final some = [
        for (final e in await store.all)
          if (month.contains(e.day)) e,
      ];
      expect(some.totals, {Category('food'): Money.fromPence(250)});
      expect((await store.all).totals, {
        Category('food'): Money.fromPence(350),
      });
    });

    test('and asking costs no future, because adding up never waited', () {
      // `totals` was a `Future<Map<...>>` while it hung off `Store`. It is a
      // plain `Map` now, and this test needs no `async` to say so. Nothing
      // about the work changed; it stopped being reached through something
      // that waits.
      final expenses = [
        Expense(Money.fromPence(250), Category('food'), day, 'soup'),
      ];
      expect(expenses.totals, isA<Map<Category, Money>>());
      expect(expenses.totals, isNot(isA<Future<Object?>>()));
    });
  });
  // #endregion derived
}

/// A second real implementation, written only to show that [run] never learns
/// of it. It keeps the most recent expense and forgets the rest.
class LastOnlyStore implements Store {
  Expense? _last;

  @override
  Future<void> record(Expense expense) async => _last = expense;

  @override
  Future<List<Expense>> get all async => [?_last];
}
