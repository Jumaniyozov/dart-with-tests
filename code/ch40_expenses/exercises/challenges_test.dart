import 'package:ch40_expenses/expenses.dart';
import 'package:ch40_expenses/src/sqlite_store.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'challenges.dart';

final food = Category('food');
final day = Day(2026, 9, 11);

Expense lunch() => Expense(Money.fromPence(600), food, day, 'lunch');

/// A store over a database with no file, already holding a £10.00 limit.
Future<SqliteStore> fresh(Database db) async {
  final store = SqliteStore(db);
  await store.setLimit(Limit(food, Money.fromPence(1000)));
  return store;
}

/// An `Alone` that fails [times] times with SQLITE_BUSY and then works.
Alone busyFor(int times, {required List<int> attempts}) {
  var left = times;
  return <T>(body) {
    attempts.add(attempts.length + 1);
    if (left-- > 0) {
      throw SqliteException(
        extendedResultCode: 5,
        message: 'database is locked',
      );
    }
    return body();
  };
}

void main() {
  late Database db;

  setUp(() => db = sqlite3.openInMemory());
  tearDown(() => db.close());

  group('challenge 1 — wait your turn', () {
    test('it answers what the body answered', () async {
      expect(await serialised()(() async => 42), 42);
    });

    test(
      'and the second of two calls in flight sees the first one finished',
      () async {
        final order = <String>[];
        final alone = serialised();

        await Future.wait([
          alone(() async {
            order.add('first in');
            await Future<void>.delayed(Duration.zero);
            order.add('first out');
          }),
          alone(() async => order.add('second in')),
        ]);

        expect(order, ['first in', 'first out', 'second in']);
      },
    );

    test(
      'so the budget refuses the second expense instead of SQLite',
      () async {
        final store = await fresh(db);
        final tracker = Tracker(store, () => day, serialised());

        final verdicts = await Future.wait([
          tracker.record(lunch()),
          tracker.record(lunch()),
        ]);

        expect(verdicts.first, isA<Within>());
        expect(
          verdicts.last,
          isA<Breach>(),
          reason:
              'the second caller ran after the first one, read £6.00 spent, '
              'and was told by the budget rather than by the database',
        );
        expect(await store.expenses(), hasLength(1));
      },
    );

    test('and a body that throws does not wedge the ones behind it', () async {
      final alone = serialised();

      final failed = alone(() async => throw StateError('mine'));
      final after = alone(() async => 'served');

      await expectLater(failed, throwsStateError);
      expect(await after, 'served');
    });
  });

  group('challenge 2 — a pragma for the length of one body', () {
    int timeout() =>
        db.select('PRAGMA busy_timeout').single.values.single! as int;

    test('it answers what the body answered', () async {
      expect(await withBusyTimeout(db, 50, () async => 'done'), 'done');
    });

    test('and the body runs with it set', () async {
      expect(await withBusyTimeout(db, 250, () async => timeout()), 250);
    });

    test('and it is back to what it was afterwards', () async {
      db.execute('PRAGMA busy_timeout = 17');
      await withBusyTimeout(db, 250, () async => null);
      expect(timeout(), 17);
    });

    test('and back even when the body throws', () async {
      db.execute('PRAGMA busy_timeout = 17');
      await expectLater(
        withBusyTimeout(db, 250, () async => throw StateError('mine')),
        throwsStateError,
      );
      expect(timeout(), 17);
    });
  });

  group('challenge 3 — once more, for the one failure worth it', () {
    test('it does not try again when nothing went wrong', () async {
      final attempts = <int>[];
      expect(
        await retryingOnce(busyFor(0, attempts: attempts))(() async => 'once'),
        'once',
      );
      expect(attempts, hasLength(1));
    });

    test('and tries again when the database was locked', () async {
      final attempts = <int>[];
      expect(
        await retryingOnce(busyFor(1, attempts: attempts))(() async => 'twice'),
        'twice',
      );
      expect(attempts, hasLength(2));
    });

    test('and gives up after the second, rather than looping', () async {
      final attempts = <int>[];
      await expectLater(
        retryingOnce(busyFor(2, attempts: attempts))(() async => 'never'),
        throwsA(isA<SqliteException>()),
      );
      expect(attempts, hasLength(2));
    });

    test(
      'and never tries again for a failure trying again cannot fix',
      () async {
        var attempts = 0;
        await expectLater(
          retryingOnce(<T>(body) {
            attempts++;
            throw SqliteException(
              extendedResultCode: 275,
              message: 'CHECK constraint failed',
            );
          })(() async => 'never'),
          throwsA(isA<SqliteException>()),
        );
        expect(attempts, 1);
      },
    );
  });
}
