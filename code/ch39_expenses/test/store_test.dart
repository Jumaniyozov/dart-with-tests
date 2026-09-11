import 'dart:io';

import 'package:ch39_expenses/expenses.dart';
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
  Future<List<Expense>> expenses({Period? period, int? count}) async {
    calls.add('expenses');
    return const [];
  }

  /// Two members this double has no opinion about, written out anyway.
  ///
  /// That is the cost study 27 named and study 32 collected: `implements`
  /// takes the whole interface, so growing `Store` by two lines grew every
  /// double in the book by two members, whether or not the test cares.
  ///
  /// Study 39 sent the bill again and in a different currency. It added no
  /// member — it **renamed** one and gave it two parameters — and the analyzer
  /// reported it at every implementation of [Store] in this package at once,
  /// and the group below names them. A double that ignores both parameters, as
  /// this one does, still has to write them down.
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
        ['limits', 'record', 'expenses'],
        reason:
            'add asks for the limits before recording, and list read the '
            'store once and stopped because it found it empty. Every one of '
            'those is a fact about how run is written, not about what the '
            'program does — which is why this assertion has now been edited '
            'three times for changes that broke nothing. Study 39 only '
            'renamed the member.',
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

  // #region bill
  group('what renaming one member of an interface costs', () {
    test('it is paid at every implementation in the package, by name', () {
      final implementing = [
        for (final directory in ['lib/src', 'test', 'exercises'])
          for (final file in Directory(directory).listSync().whereType<File>())
            for (final match in RegExp(
              r'^class (\w+).*implements Store',
              multiLine: true,
            ).allMatches(file.readAsStringSync()))
              match.group(1)!,
      ]..sort();

      expect(
        implementing,
        [
          'CountingStore',
          'FileStore',
          'InMemoryStore',
          'LastOnlyStore',
          'SpyStore',
          'SqliteStore',
        ],
        reason:
            'study 32 itemised this bill for two added members; study 39 '
            'sent it again for one renamed one, and the analyzer named every '
            'one of these at once. A list rather than a count, because a '
            'count is the half of this that rots',
      );
    });
  });
  // #endregion bill

  group('the interface is the only thing run knows about', () {
    test('a store that keeps only the last expense works unchanged', () async {
      final store = LastOnlyStore();
      await run(['add', '1.00', 'food', 'apple'], store, day);
      await run(['add', '2.00', 'food', 'soup'], store, day);
      expect((await store.expenses()).single.note, 'soup');
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
  Future<List<Expense>> expenses({Period? period, int? count}) async => [
    ?_last,
  ];

  @override
  Future<void> setLimit(Limit limit) async {}

  @override
  Future<List<Limit>> get limits async => const [];
}
