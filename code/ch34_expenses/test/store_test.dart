import 'package:ch34_expenses/expenses.dart';
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

  /// Two members this double has no opinion about, written out anyway.
  ///
  /// That is the cost study 27 named and study 32 collected: `implements`
  /// takes the whole interface, so growing `Store` by two lines grew every
  /// double in the book by two members, whether or not the test cares.
  @override
  Future<void> setLimit(Limit limit) async => calls.add('setLimit');

  @override
  Future<List<Limit>> get limits async {
    calls.add('limits');
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
      expect(
        spy.calls,
        ['limits', 'record'],
        reason:
            'this said [record] until study 32, and the change that broke it '
            'did not change what the program does. See 32.4.',
      );
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
        ['limits', 'record', 'all'],
        reason:
            'add asks for the limits before recording, and list read the '
            'store once and stopped because it found it empty. Every one of '
            'those is a fact about how run is written, not about what the '
            'program does — which is why this assertion has now been edited '
            'twice for changes that broke nothing.',
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
}

/// A second real implementation, written only to show that [run] never learns
/// of it. It keeps the most recent expense and forgets the rest.
class LastOnlyStore implements Store {
  Expense? _last;

  @override
  Future<void> record(Expense expense) async => _last = expense;

  @override
  Future<List<Expense>> get all async => [?_last];

  @override
  Future<void> setLimit(Limit limit) async {}

  @override
  Future<List<Limit>> get limits async => const [];
}
