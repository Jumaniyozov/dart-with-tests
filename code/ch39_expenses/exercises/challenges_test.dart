import 'package:ch39_expenses/expenses.dart';
import 'package:ch39_expenses/src/sqlite_store.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'challenges.dart';

late Database db;

void record(
  int pence, {
  String category = 'food',
  int month = 9,
  int day = 11,
}) => db.execute(
  'INSERT INTO expenses (day, pence, category, note, acknowledged) '
  'VALUES (?, ?, ?, ?, 0)',
  [
    '2026-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    pence,
    category,
    'note',
  ],
);

int get rows =>
    db.select('SELECT COUNT(*) AS n FROM expenses').single['n']! as int;

void main() {
  setUp(() {
    db = sqlite3.openInMemory();
    db.execute(schema);
  });
  tearDown(() => db.close());

  group('challenge 1 — all of it or none of it', () {
    test('it answers what the body answered', () {
      expect(atomically(db, () => 42), 42);
    });

    test('and what the body wrote is committed', () {
      atomically(db, () {
        record(100);
        record(200);
      });

      expect(rows, 2);
      expect(db.autocommit, isTrue);
    });

    test('a throw takes everything the body wrote back out', () {
      expect(
        () => atomically(db, () {
          record(100);
          db.execute(
            'INSERT INTO expenses (day, pence, category, note, acknowledged) '
            "VALUES ('2026-09-12', -1, 'food', 'x', 0)",
          );
        }),
        throwsA(isA<SqliteException>()),
      );

      expect(rows, 0, reason: 'the first one went in and came back out');
      expect(db.autocommit, isTrue, reason: 'and the transaction is closed');
    });

    test('and it does not have to be SQLite that threw', () {
      expect(
        () => atomically(db, () {
          record(100);
          throw StateError('the caller changed its mind');
        }),
        throwsStateError,
      );

      expect(rows, 0);
      expect(db.autocommit, isTrue);
    });

    test('a successful run does not then try to roll back', () {
      expect(
        () => atomically(db, () => record(100)),
        returnsNormally,
        reason:
            'a bare ROLLBACK after the COMMIT throws cannot rollback - no '
            'transaction is active, which is the whole reason for the check',
      );
    });
  });

  group('challenge 2 — a total nothing crossed the boundary for', () {
    test('nothing spent is nothing, not null', () {
      expect(spentIn(db, Category('food'), Period(2026, 9)), Money.zero);
    });

    test('it adds up one category in one month', () {
      record(450);
      record(1200);
      record(999, category: 'travel');
      record(500, month: 10);

      expect(
        spentIn(db, Category('food'), Period(2026, 9)),
        Money.fromPence(1650),
      );
    });

    test('and February stops where February stops', () {
      record(100, month: 2, day: 28);
      record(200, month: 3, day: 1);

      expect(
        spentIn(db, Category('food'), Period(2026, 2)),
        Money.fromPence(100),
      );
    });

    test(
      "a category is text somebody typed, and it is not part of the SQL",
      () {
        record(450, category: 'food');

        expect(
          spentIn(db, Category("food' OR '1'='1"), Period(2026, 9)),
          Money.zero,
          reason: 'a bound parameter is a value, whatever characters are in it',
        );
      },
    );
  });

  group('challenge 3 — the other end of the list', () {
    test('nothing recorded is nothing to answer', () {
      expect(latest(db, 3), isEmpty);
    });

    test('it answers the last few', () {
      for (final pence in [100, 200, 300, 400]) {
        record(pence);
      }

      expect(latest(db, 2), [300, 400]);
    });

    test('oldest first, which is the trap', () {
      for (final pence in [100, 200, 300, 400]) {
        record(pence);
      }

      expect(
        latest(db, 3),
        [200, 300, 400],
        reason:
            'ORDER BY id DESC LIMIT 3 is the right rows in the wrong order, '
            'and nothing about the answer says so until you read it',
      );
    });

    test('and asking for more than there are is not an error', () {
      record(100);

      expect(latest(db, 10), [100]);
    });
  });
}
