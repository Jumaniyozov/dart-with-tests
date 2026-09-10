import 'dart:io';

import 'package:ch28_expenses/expenses.dart';
import 'package:test/test.dart';

void main() {
  // #region temp
  /// A real directory, made fresh for every test and deleted after it.
  ///
  /// `FileStore` is the one class in this package that a fake cannot stand in
  /// for, because the thing being tested *is* the file. So this is the one test
  /// file that touches a disk, and `tearDown` is what keeps it from leaving
  /// anything behind.
  final day = Day(2026, 9, 9);
  late Directory directory;
  late File file;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('expenses_test');
    file = File('${directory.path}/expenses.txt');
  });
  tearDown(() => directory.delete(recursive: true));

  Expense expenseOf(int pence, String category, String note) =>
      Expense(Money.fromPence(pence), Category(category), day, note);
  // #endregion temp

  // #region roundtrip
  group('a file store keeps what it is told', () {
    test('and a file that was never written is simply empty', () async {
      expect(await file.exists(), isFalse);
      expect(await FileStore(file).all, isEmpty);
    });

    test('one expense survives being written and read back', () async {
      await FileStore(file).record(expenseOf(1250, 'Food', 'coffee'));

      final read = (await FileStore(file).all).single;
      expect(read.amount, Money.fromPence(1250));
      expect(read.category, Category('food'));
      expect(read.day, day);
      expect(read.note, 'coffee');
    });

    test('and so do several, in the order they arrived', () async {
      final store = FileStore(file);
      await store.record(expenseOf(100, 'food', 'apple'));
      await store.record(expenseOf(250, 'food', 'soup'));
      await store.record(expenseOf(300, 'transport', 'bus'));

      expect(
        [for (final e in await store.all) e.note],
        ['apple', 'soup', 'bus'],
      );
      expect(await store.totals, {
        Category('food'): Money.fromPence(350),
        Category('transport'): Money.fromPence(300),
      });
    });

    test("a second run of the program sees the first run's work", () async {
      await FileStore(file).record(expenseOf(100, 'food', 'apple'));
      // A different object, the same file. This is the whole point of the
      // study: study 27's InMemoryStore would answer empty here.
      expect(await FileStore(file).all, hasLength(1));
    });
  });
  // #endregion roundtrip

  // #region append
  group('appending is not a detail', () {
    test(
      'writeAsString truncates, which would keep only the last expense',
      () async {
        await file.writeAsString('one\n');
        await file.writeAsString('two\n');
        expect(
          await file.readAsString(),
          'two\n',
          reason: 'the default mode replaces the file, it does not add to it',
        );
      },
    );

    test('so record uses FileMode.append and the file grows', () async {
      final store = FileStore(file);
      await store.record(expenseOf(100, 'food', 'apple'));
      await store.record(expenseOf(250, 'food', 'soup'));

      expect(
        (await file.readAsString()).split('\n'),
        hasLength(3),
        reason:
            'two expenses, each ending in a newline, so the split leaves a '
            'trailing empty string. That is the line _expenseFrom answers null '
            'for, and why it has to.',
      );
    });
  });
  // #endregion append

  // #region debt
  group('what this format cannot carry — study 29 is the repair', () {
    test('a note with a comma loses the whole expense', () async {
      final store = FileStore(file);
      await store.record(expenseOf(320, 'transport', 'bus, then train'));

      expect(await file.readAsString(), contains('bus, then train'));
      expect(
        await store.all,
        isEmpty,
        reason: 'five fields, and the four-field pattern does not match',
      );
    });

    test('and a note with a newline is worse: it comes back wrong', () async {
      final store = FileStore(file);
      await store.record(expenseOf(500, 'food', 'lunch\nwith notes'));

      // Measured, and not what this study first assumed. One expense became
      // two lines. The first four fields still line up, so it reads back as a
      // perfectly ordinary expense — with half its note missing and nothing
      // anywhere saying so.
      final read = (await store.all).single;
      expect(read.amount, Money.fromPence(500));
      expect(
        read.note,
        'lunch',
        reason: 'the rest of the note is gone and the record looks fine',
      );
    });
  });
  // #endregion debt
}
