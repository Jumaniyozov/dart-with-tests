import 'dart:async';

import 'package:ch39_expenses/expenses.dart';
import 'package:ch39_expenses/src/sqlite_store.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

// #region harness
/// Every test in this file runs against a database that was never a file.
///
/// `sqlite3.openInMemory()` is the whole reason [SqliteStore] takes a
/// [Database] instead of a path. The SQL is real — the real `CHECK`s, the real
/// `LIMIT`, the real primary key — and there is nothing to create, nothing to
/// delete and nothing to leave behind for the next run to find.
late Database db;
late SqliteStore store;

Expense spent(
  int pence, {
  String category = 'food',
  int day = 11,
  bool acknowledged = false,
}) => Expense(
  Money.fromPence(pence),
  Category(category),
  Day(2026, 9, day),
  'note $pence',
  acknowledged: acknowledged,
);
// #endregion harness

void main() {
  setUp(() {
    db = sqlite3.openInMemory();
    store = SqliteStore(db);
  });
  tearDown(() => db.close());

  // #region roundtrip
  group('an expense goes into a table and comes back out', () {
    test('with every field it went in with', () async {
      await store.record(spent(450, acknowledged: true));

      final back = (await store.expenses()).single;

      expect(back.amount, Money.fromPence(450));
      expect(back.category, Category('food'));
      expect(back.day, Day(2026, 9, 11));
      expect(back.note, 'note 450');
      expect(back.acknowledged, isTrue);
    });

    test('and in the order it arrived', () async {
      await store.record(spent(100));
      await store.record(spent(200));
      await store.record(spent(300));

      expect(
        [for (final e in await store.expenses()) e.amount.pence],
        [100, 200, 300],
        reason: 'ORDER BY id, and id is the order the rows were inserted in',
      );
    });

    test('and the future it answers was finished before it was made', () {
      unawaited(store.record(spent(450)));

      expect(
        db.select('SELECT COUNT(*) AS n FROM expenses').first['n'],
        1,
        reason:
            'an async body runs to its first await, and there is not one — '
            'so package:sqlite3 over dart:ffi is a function call and Store '
            "asks for a Future that this implementation pays nothing for",
      );
    });
  });
  // #endregion roundtrip

  // #region json
  group('what stops a row being read as JSON', () {
    test('a Row is a Map, so expenseFromJson type-checks and matches', () {
      db.execute(
        'INSERT INTO expenses (day, pence, category, note, acknowledged) '
        "VALUES ('2026-09-11', 450, 'food', 'coffee', 1)",
      );
      final row = db.select('SELECT * FROM expenses').single;

      expect(row, isA<Map<String, Object?>>());

      final read = expenseFromJson(row);

      expect(read, isNotNull, reason: 'it really does answer an Expense');
      expect(read!.amount, Money.fromPence(450));
      expect(read.note, 'coffee');
    });

    test(
      'and the one field it silently drops is the one that is not a number',
      () {
        db.execute(
          'INSERT INTO expenses (day, pence, category, note, acknowledged) '
          "VALUES ('2026-09-11', 450, 'food', 'coffee', 1)",
        );
        final row = db.select('SELECT * FROM expenses').single;

        expect(row['acknowledged'], 1);

        // The expression [expenseFromJson] really evaluates, written out.
        //
        // `unrelated_type_equality_checks` is on in this book and it catches
        // `1 == true` when both sides are literals — try it, it is an `info`
        // on that line. It cannot catch this one and it cannot catch the real
        // one, because the left side came out of a `Map<String, Object?>` and
        // `Object?` is a supertype of `bool`. The lint that exists for this is
        // blind in exactly the place the bug lives.
        final Object? flag = row['acknowledged'];
        expect(
          flag == true,
          isFalse,
          reason: 'SQLite has no boolean, and this is the whole mechanism',
        );
        expect(
          expenseFromJson(row)!.acknowledged,
          isFalse,
          reason:
              'the money is right, the category is right, and an overspend '
              'somebody was warned about has quietly become one nobody was',
        );
      },
    );

    test(
      'so SqliteStore reads columns, and toJson survives by not being used',
      () async {
        await store.record(spent(450, acknowledged: true));

        expect((await store.expenses()).single.acknowledged, isTrue);
        expect(
          spent(450, acknowledged: true).toJson(),
          containsPair('acknowledged', true),
          reason:
              'study 36 said toJson is an extension because a database store '
              'would want none of it, and it is untouched here',
        );
      },
    );
  });
  // #endregion json

  // #region strict
  group('what the schema keeps that no Dart type is standing there to keep', () {
    test('an ordinary INTEGER column takes a string and hands it back', () {
      db.execute('CREATE TABLE loose (pence INTEGER NOT NULL)');
      db.execute("INSERT INTO loose (pence) VALUES ('lots')");

      expect(
        db.select('SELECT pence FROM loose').single['pence'],
        isA<String>(),
        reason:
            'without STRICT a column type is a suggestion, and a read that '
            'can hand back the wrong type is study 19 undone at the last '
            'possible moment',
      );
    });

    test('and a STRICT one refuses it', () {
      expect(
        () => db.execute(
          'INSERT INTO expenses (day, pence, category, note, acknowledged) '
          "VALUES ('2026-09-11', 'lots', 'food', 'x', 0)",
        ),
        throwsA(
          isA<SqliteException>().having(
            (e) => e.message,
            'message',
            'cannot store TEXT value in INTEGER column expenses.pence',
          ),
        ),
      );
    });

    test('the CHECK refuses an amount Money would have refused first', () {
      expect(
        () => db.execute(
          'INSERT INTO expenses (day, pence, category, note, acknowledged) '
          "VALUES ('2026-09-11', -1, 'food', 'x', 0)",
        ),
        throwsA(
          isA<SqliteException>()
              .having((e) => e.message, 'message', contains('CHECK constraint'))
              .having((e) => e.extendedResultCode, 'extendedResultCode', 275),
        ),
      );
    });

    test('and a row this program cannot read is skipped, not thrown', () async {
      db.execute(
        'INSERT INTO expenses (day, pence, category, note, acknowledged) '
        "VALUES ('the ninth', 450, 'food', 'x', 0)",
      );
      await store.record(spent(100));

      expect(
        [for (final e in await store.expenses()) e.amount.pence],
        [100],
        reason:
            'TEXT is TEXT, so no CHECK could have caught that day — and '
            'Day.parse is why it comes out as nothing rather than as a throw',
      );
    });
  });
  // #endregion strict

  // #region bound
  group('a bound the store keeps, and a month it keeps too', () {
    setUp(() async {
      for (var day = 1; day <= 5; day++) {
        await store.record(spent(day * 100, day: day));
      }
      await store.record(
        Expense(
          Money.fromPence(999),
          Category('food'),
          Day(2026, 10, 1),
          'oct',
        ),
      );
    });

    test(
      'no arguments is everything, which is what all used to mean',
      () async {
        expect(await store.expenses(), hasLength(6));
      },
    );

    test('a count is a LIMIT', () async {
      expect(
        [for (final e in await store.expenses(count: 2)) e.amount.pence],
        [100, 200],
      );
    });

    test('a period is a WHERE', () async {
      expect(await store.expenses(period: Period(2026, 10)), hasLength(1));
      expect(await store.expenses(period: Period(2026, 9)), hasLength(5));
    });

    test('and both are one statement', () async {
      expect(
        [
          for (final e in await store.expenses(
            period: Period(2026, 9),
            count: 2,
          ))
            e.amount.pence,
        ],
        [100, 200],
      );
    });

    test('LIMIT -1 is how SQLite says no bound, and LIMIT NULL is an error', () {
      expect(
        db.select('SELECT pence FROM expenses ORDER BY id LIMIT ?', [-1]),
        hasLength(6),
      );
      expect(
        () =>
            db.select('SELECT pence FROM expenses ORDER BY id LIMIT ?', [null]),
        throwsA(
          isA<SqliteException>().having(
            (e) => e.message,
            'message',
            'datatype mismatch',
          ),
        ),
        reason:
            'null means no bound in Dart and means nothing at all here, which '
            'is why _unbounded is written down as a number',
      );
    });
  });
  // #endregion bound

  // #region upsert
  group('one limit per category, which is a primary key', () {
    test('setting it twice sets it, rather than setting two of them', () async {
      await store.setLimit(Limit(Category('food'), Money.fromPence(2000)));
      await store.setLimit(Limit(Category('food'), Money.fromPence(3000)));

      expect(await store.limits, [
        Limit(Category('food'), Money.fromPence(3000)),
      ]);
    });

    test('and a plain INSERT is what that upsert is instead of', () async {
      await store.setLimit(Limit(Category('food'), Money.fromPence(2000)));

      expect(
        () => db.execute(
          "INSERT INTO limits (category, pence) VALUES ('food', 3000)",
        ),
        throwsA(
          isA<SqliteException>()
              .having(
                (e) => e.message,
                'message',
                'UNIQUE constraint failed: limits.category',
              )
              .having((e) => e.extendedResultCode, 'extendedResultCode', 1555),
        ),
        reason:
            'the thing InMemoryStore gets from a Map and FileStore earns by '
            'reading its log forwards',
      );
    });

    test('and they answer in the order they were first set', () async {
      await store.setLimit(Limit(Category('food'), Money.fromPence(2000)));
      await store.setLimit(Limit(Category('travel'), Money.fromPence(500)));
      await store.setLimit(Limit(Category('food'), Money.fromPence(3000)));

      expect(
        [for (final limit in await store.limits) limit.category.name],
        ['food', 'travel'],
      );
    });
  });
  // #endregion upsert
}
