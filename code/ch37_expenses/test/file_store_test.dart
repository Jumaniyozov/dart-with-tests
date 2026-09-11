import 'dart:convert';
import 'dart:io';

import 'package:ch37_expenses/expenses.dart';
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
      expect(Report.of(await store.all).lines, [
        CategoryTotal(Category('food'), Money.fromPence(350)),
        CategoryTotal(Category('transport'), Money.fromPence(300)),
      ]);
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

    test('so record appends, and one JSON object lands on each line', () async {
      final store = FileStore(file);
      await store.record(expenseOf(100, 'food', 'apple'));
      await store.record(expenseOf(250, 'food', 'soup'));

      final lines = const LineSplitter().convert(await file.readAsString());
      expect(lines, hasLength(2));
      expect(
        lines.first,
        '{"day":"2026-09-09","pence":100,"category":"food","note":"apple"}',
      );
    });

    test('and LineSplitter has no phantom last line', () async {
      // Study 28 split on '\n' and had to answer null for the empty string a
      // trailing newline leaves behind. This is the tool that does not make one.
      expect(const LineSplitter().convert(''), isEmpty);
      expect(const LineSplitter().convert('a\nb\n'), ['a', 'b']);
      expect(''.split('\n'), [''], reason: 'what study 28 had to work around');
    });
  });
  // #endregion append

  // #region repaired
  group('what study 28 could not carry, and this format can', () {
    test('a note with a comma survives the round trip', () async {
      final store = FileStore(file);
      await store.record(expenseOf(320, 'transport', 'bus, then train'));

      expect((await store.all).single.note, 'bus, then train');
    });

    test('and so does a note with a newline in it', () async {
      final store = FileStore(file);
      await store.record(expenseOf(500, 'food', 'lunch\nwith notes'));

      expect((await store.all).single.note, 'lunch\nwith notes');
      expect(
        const LineSplitter().convert(await file.readAsString()),
        hasLength(1),
        reason:
            'the newline is written as the two characters backslash-n, so '
            'one expense is still one line',
      );
      expect(await file.readAsString(), contains(r'lunch\nwith notes'));
    });

    test('and a quote, and a backslash, which nobody thought about', () async {
      final store = FileStore(file);
      await store.record(expenseOf(99, 'food', r'a "quote" and a \ backslash'));

      expect((await store.all).single.note, r'a "quote" and a \ backslash');
    });
  });
  // #endregion repaired

  // #region limits
  group('a limit lives in the same file', () {
    test('and a second run of the program sees it', () async {
      await FileStore(file)
          .setLimit(Limit(Category('food'), Money.fromPence(20000)));
      expect(await FileStore(file).limits, [
        Limit(Category('food'), Money.fromPence(20000)),
      ]);
    });

    test('set twice, the later line wins', () async {
      final store = FileStore(file);
      await store.setLimit(Limit(Category('food'), Money.fromPence(20000)));
      await store.setLimit(Limit(Category('food'), Money.fromPence(30000)));

      expect(await store.limits, [
        Limit(Category('food'), Money.fromPence(30000)),
      ]);
      expect(
        const LineSplitter().convert(await file.readAsString()),
        hasLength(2),
        reason: 'a log appends; it is the reading that decides which counts',
      );
    });

    test('and limits and expenses share the file without confusion', () async {
      final store = FileStore(file);
      await store.record(expenseOf(1250, 'food', 'coffee'));
      await store.setLimit(Limit(Category('food'), Money.fromPence(20000)));
      await store.record(expenseOf(320, 'transport', 'bus'));

      expect(await store.all, hasLength(2));
      expect(await store.limits, hasLength(1));
    });

    test('an acknowledged overspend survives the file', () async {
      final store = FileStore(file);
      await store.record(
        Expense(
          Money.fromPence(2500),
          Category('food'),
          day,
          'big',
          acknowledged: true,
        ),
      );
      expect((await store.all).single.acknowledged, isTrue);
    });

    test("and a file study 29 wrote reads with nothing acknowledged", () async {
      await file.writeAsString(
        '{"day":"2026-09-09","pence":1250,"category":"food","note":"coffee"}\n',
      );
      expect((await FileStore(file).all).single.acknowledged, isFalse);
      expect(await FileStore(file).limits, isEmpty);
    });
  });
  // #endregion limits

  // #region unreadable
  group('a line this program cannot read is skipped, not fatal', () {
    test('text that is not JSON at all', () async {
      await file.writeAsString('this is not json\n');
      expect(await FileStore(file).all, isEmpty);
    });

    test('JSON that is not an expense', () async {
      await file.writeAsString('[1,2,3]\n{"unrelated":true}\n');
      expect(await FileStore(file).all, isEmpty);
    });

    test('an expense whose pence arrived as a string', () async {
      await file.writeAsString(
        '{"day":"2026-09-09","pence":"1250","category":"food","note":"x"}\n',
      );
      expect(
        await FileStore(file).all,
        isEmpty,
        reason: 'the map pattern checks the type, so no TypeError is thrown',
      );
    });

    test('an expense the domain refuses, which JSON was happy with', () async {
      await file.writeAsString(
        '{"day":"2026-09-09","pence":-500,"category":"food","note":"x"}\n'
        '{"day":"2026-02-31","pence":100,"category":"food","note":"y"}\n',
      );
      expect(
        await FileStore(file).all,
        isEmpty,
        reason:
            'money is never negative and February has no 31st, and neither '
            'of those is something JSON has an opinion about',
      );
    });

    test('and the readable lines around it still arrive', () async {
      final store = FileStore(file);
      await store.record(expenseOf(100, 'food', 'apple'));
      await file.writeAsString('rubbish\n', mode: FileMode.append);
      await store.record(expenseOf(250, 'food', 'soup'));

      expect([for (final e in await store.all) e.note], ['apple', 'soup']);
    });
  });
  // #endregion unreadable
}
