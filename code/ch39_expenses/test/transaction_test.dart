import 'dart:io';

import 'package:ch39_expenses/expenses.dart';
import 'package:ch39_expenses/src/migration.dart';
import 'package:ch39_expenses/src/rolling_back.dart';
import 'package:ch39_expenses/src/sqlite_store.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

// #region harness
/// A database that was never a file, with a schema made by [SqliteStore].
late Database db;

/// Two rows for [caughtAndCommitted] and [caughtAndRolledBack], the second of
/// which the schema will not take.
///
/// This program cannot build the second one: `Money` has no negative value to
/// hand over, so the only way to put a `-1` in that column is to write the SQL
/// by hand, which is what whatever else opens this file will be doing.
const good = ['2026-09-11', 100, 'food', 'coffee'];
const bad = ['2026-09-12', -1, 'food', 'impossible'];

int get rows =>
    db.select('SELECT COUNT(*) AS n FROM expenses').single['n']! as int;
// #endregion harness

void main() {
  setUp(() {
    db = sqlite3.openInMemory();
    SqliteStore(db);
  });
  tearDown(() => db.close());

  // #region open
  group('a failing statement leaves the transaction open', () {
    test('autocommit is true until BEGIN and false after it', () {
      expect(db.autocommit, isTrue);
      db.execute('BEGIN');
      expect(db.autocommit, isFalse);
      db.execute('ROLLBACK');
      expect(db.autocommit, isTrue);
    });

    test('and it is still false after the statement has thrown', () {
      db.execute('BEGIN');
      db.execute(
        'INSERT INTO expenses (day, pence, category, note, acknowledged) '
        "VALUES ('2026-09-11', 100, 'food', 'x', 0)",
      );

      expect(
        () => db.execute(
          'INSERT INTO expenses (day, pence, category, note, acknowledged) '
          "VALUES ('2026-09-12', -1, 'food', 'y', 0)",
        ),
        throwsA(isA<SqliteException>()),
      );

      expect(
        db.autocommit,
        isFalse,
        reason:
            'SQLite undid the statement and did not undo the transaction '
            'around it, which is the whole of this study',
      );
      db.execute('ROLLBACK');
    });

    test(
      'and that is true of every kind of failure, not only a constraint',
      () {
        for (final broken in [
          "INSERT INTO expenses (day, pence, category, note, acknowledged) VALUES ('2026-09-11', -1, 'food', 'x', 0)",
          "INSERT INTO expenses (day, pence, category, note, acknowledged) VALUES ('2026-09-11', 'lots', 'food', 'x', 0)",
          'INSERT INTO nowhere (a) VALUES (1)',
          'INSERT INTO',
        ]) {
          db.execute('BEGIN');
          expect(() => db.execute(broken), throwsA(isA<SqliteException>()));
          expect(
            db.autocommit,
            isFalse,
            reason: 'a constraint, a type, a missing table and a typo: $broken',
          );
          db.execute('ROLLBACK');
        }
      },
    );

    test('what the exception carries, which is more than a message', () {
      try {
        db.execute(
          'INSERT INTO expenses (day, pence, category, note, acknowledged) '
          'VALUES (?, ?, ?, ?, 0)',
          bad,
        );
        fail('the CHECK should have refused that');
      } on SqliteException catch (error) {
        expect(error.message, 'CHECK constraint failed: pence >= 0');
        expect(error.extendedResultCode, 275);
        expect(error.resultCode, 19, reason: 'SQLITE_CONSTRAINT, the family');
        expect(error.causingStatement, contains('INSERT INTO expenses'));
        expect(error.parametersToStatement, bad);
      }
    });

    test('and a ROLLBACK with nothing open throws in its turn', () {
      expect(
        () => db.execute('ROLLBACK'),
        throwsA(
          isA<SqliteException>().having(
            (e) => e.message,
            'message',
            'cannot rollback - no transaction is active',
          ),
        ),
        reason:
            'which is why moveInto asks db.autocommit first rather than '
            'rolling back unconditionally in its finally',
      );
    });
  });
  // #endregion open

  // #region caught
  group('the two answers, side by side', () {
    test('catching it and committing anyway commits the half', () {
      caughtAndCommitted(db, [good, bad]);

      expect(
        rows,
        1,
        reason:
            'the exception was handled, nothing was reported, and one of the '
            'two rows is now in the table for ever',
      );
      expect(db.autocommit, isTrue, reason: 'the COMMIT did work');
    });

    test('and rolling back leaves the table as it was', () {
      caughtAndRolledBack(db, [good, bad]);

      expect(rows, 0);
      expect(db.autocommit, isTrue);
    });

    test('both are the same function when nothing fails', () {
      caughtAndCommitted(db, [good]);
      expect(rows, 1);

      caughtAndRolledBack(db, [good]);
      expect(rows, 2);
    });
  });
  // #endregion caught

  // #region move
  group('moving the reader file in, once', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('migrate39');
      file = File('${directory.path}/expenses.txt');
    });
    tearDown(() => directory.deleteSync(recursive: true));

    Expense spent(int pence, {String category = 'food', int day = 11}) =>
        Expense(
          Money.fromPence(pence),
          Category(category),
          Day(2026, 9, day),
          'note $pence',
        );

    test(
      'everything a FileStore holds arrives, and it says how much',
      () async {
        final from = FileStore(file);
        await from.record(spent(450));
        await from.record(spent(1200, category: 'travel'));
        await from.setLimit(Limit(Category('food'), Money.fromPence(2000)));

        final moved = await moveInto(from, db);

        expect(moved, (expenses: 2, limits: 1));
        expect(await SqliteStore(db).expenses(), hasLength(2));
        expect(await SqliteStore(db).limits, hasLength(1));
      },
    );

    test(
      'a limit set twice arrives once, because FileStore already knew that',
      () async {
        final from = FileStore(file);
        await from.setLimit(Limit(Category('food'), Money.fromPence(2000)));
        await from.setLimit(Limit(Category('food'), Money.fromPence(3000)));

        final moved = await moveInto(from, db);

        expect(
          moved.limits,
          1,
          reason:
              'the log holds two lines and FileStore.limits answers one, so '
              'going through Store is what keeps this from meeting the primary '
              'key',
        );
        expect(
          (await SqliteStore(db).limits).single.amount,
          Money.fromPence(3000),
        );
      },
    );

    test(
      'and nothing arrives at all when something in the middle fails',
      () async {
        // A table this program did not create, which is the one thing
        // `CREATE TABLE IF NOT EXISTS` leaves alone.
        final other = sqlite3.openInMemory();
        other.execute(
          'CREATE TABLE expenses (id INTEGER NOT NULL PRIMARY KEY, day TEXT '
          'NOT NULL, pence INTEGER NOT NULL CHECK (pence >= 100000), category '
          'TEXT NOT NULL, note TEXT NOT NULL, acknowledged INTEGER NOT NULL) '
          'STRICT',
        );
        addTearDown(other.close);

        final from = InMemoryStore();
        await from.record(spent(200000));
        await from.record(spent(450));
        await from.record(spent(300000));

        await expectLater(
          moveInto(from, other),
          throwsA(isA<SqliteException>()),
          reason: 'there is nothing this program could do about that',
        );
        expect(
          other.select('SELECT COUNT(*) AS n FROM expenses').single['n'],
          0,
          reason: 'the first expense went in and the finally took it back out',
        );
        expect(other.autocommit, isTrue);
        expect(
          await from.expenses(),
          hasLength(3),
          reason: 'and the source is untouched, so it can be run again',
        );
      },
    );
  });
  // #endregion move
}
