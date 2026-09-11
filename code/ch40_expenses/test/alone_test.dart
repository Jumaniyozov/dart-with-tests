import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ch40_expenses/expenses.dart';
import 'package:ch40_expenses/src/server.dart';
import 'package:ch40_expenses/src/sqlite_store.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

// #region harness
/// One month, one category, and a limit two expenses cannot both fit under.
///
/// £6.00 twice against £10.00: either is fine on its own and the pair is not,
/// which is the smallest arrangement in which *both callers were told yes* is
/// a sentence with a victim.
final food = Category('food');
final day = Day(2026, 9, 11);
final limit = Limit(food, Money.fromPence(1000));

Expense lunch() => Expense(Money.fromPence(600), food, day, 'lunch');

/// One expense, spelled as SQL, for the tests that are about two connections
/// rather than about this program.
const insert =
    "INSERT INTO expenses (day, pence, category, note, acknowledged) "
    "VALUES ('2026-09-11', 600, 'food', 'lunch', 0)";

/// What a budget check reads, straight off a connection.
int spent(Database db) =>
    db
            .select('SELECT COALESCE(SUM(pence), 0) AS spent FROM expenses')
            .first['spent']!
        as int;

/// The boundary `bin/serve.dart` hands over, over one connection.
Alone lockedBy(Database db) =>
    <T>(body) => aloneIn(db, body);

/// One `POST /expenses`, built rather than sent.
Request _post() => Request(
  'POST',
  Uri.parse('http://localhost/expenses'),
  headers: {'authorization': 'Bearer k'},
  body: jsonEncode({'pence': 600, 'category': 'food', 'note': 'lunch'}),
);

/// A store already holding [limit], over a database with no file.
Future<SqliteStore> fresh(Database db) async {
  final store = SqliteStore(db);
  await store.setLimit(limit);
  return store;
}
// #endregion harness

void main() {
  // #region machinery
  group('what resumes when', () {
    test(
      'an await on a finished future beats a timer that is already due',
      () async {
        final order = <String>[];

        // Both are queued before anything yields. The timer's delay is zero, so
        // nothing about *time* separates them: what separates them is which
        // queue they are on.
        Future<void>.delayed(Duration.zero).then((_) => order.add('timer'));
        Future<void>.value().then((_) => order.add('await'));

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(
          order,
          ['await', 'timer'],
          reason:
              'an await on a completed future resumes on the microtask '
              'queue, and that queue is drained to empty before the event loop '
              'is allowed to deliver the next event — which is what a socket '
              'carrying the next request arrives as',
        );
      },
    );
  });
  // #endregion machinery

  // #region arrival
  group('the same two expenses, arriving two ways', () {
    test('through two sockets, one is recorded', () async {
      final store = await fresh(sqlite3.openInMemory());
      final api = expensesApi(
        Tracker(store, () => day, unguarded),
        key: 'k',
        report: (error, stack) {},
      );
      final server = await io.serve(api, 'localhost', 0);
      addTearDown(() => server.close(force: true));

      await twoAtOnce(server.port);

      expect(
        await store.expenses(),
        hasLength(1),
        reason:
            'shelf_io hands this isolate one socket event at a time, and '
            'the first request runs decision-and-write to completion before '
            'the second one exists — with no transaction anywhere',
      );
    });

    test('through two calls already in flight, both are', () async {
      final store = await fresh(sqlite3.openInMemory());
      final tracker = Tracker(store, () => day, unguarded);

      await Future.wait([tracker.record(lunch()), tracker.record(lunch())]);

      expect(
        await store.expenses(),
        hasLength(2),
        reason:
            'the same store and the same tracker: both read an empty '
            'month, both were told there was room, and £12.00 is recorded '
            'against a £10.00 limit that refused nobody. The safety in the '
            'test above was never this program, it was how the requests came',
      );
    });
  });
  // #endregion arrival

  // #region loud
  group('and with the boundary the edge hands over', () {
    test('the second caller is refused rather than served wrongly', () async {
      final db = sqlite3.openInMemory();
      final store = await fresh(db);
      final tracker = Tracker(store, () => day, lockedBy(db));

      await expectLater(
        Future.wait([tracker.record(lunch()), tracker.record(lunch())]),
        throwsA(
          isA<SqliteException>().having(
            (e) => e.message,
            'message',
            'cannot start a transaction within a transaction',
          ),
        ),
      );

      expect(
        await store.expenses(),
        hasLength(1),
        reason:
            'one connection holds one transaction, so the second BEGIN '
            'IMMEDIATE fails instead of reading a number the first one is '
            'about to invalidate. A budget nothing refused is impossible here; '
            'a caller being told this program could not serve them is not',
      );
    });

    test('and a write that throws inside it leaves nothing behind', () async {
      final db = sqlite3.openInMemory();
      final store = await fresh(db);

      await expectLater(
        aloneIn(db, () async {
          await store.record(lunch());
          throw StateError('after the write, before the commit');
        }),
        throwsStateError,
      );

      expect(
        await store.expenses(),
        isEmpty,
        reason:
            'the finally rolls back and the StateError is what arrives, '
            'which is moveInto shape: a catch here would replace the failure '
            'with whatever the rollback had to say about it',
      );
    });
  });
  // #endregion loud

  // #region lock
  group('a second writer in another connection', () {
    late Directory directory;
    late Database first;
    late Database second;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('alone');
      final path = '${directory.path}/expenses.db';
      first = sqlite3.open(path);
      second = sqlite3.open(path);
      // One of them creates the tables. Both then hold the same file open,
      // which is what the command line and the server do to each other.
      SqliteStore(first);
    });

    tearDown(() {
      first.close();
      second.close();
      directory.deleteSync(recursive: true);
    });

    test('is refused by BEGIN IMMEDIATE before it can read anything', () {
      first.execute('BEGIN IMMEDIATE');

      expect(
        () => second.execute('BEGIN IMMEDIATE'),
        throwsA(
          isA<SqliteException>()
              .having((e) => e.resultCode, 'resultCode', 5)
              .having((e) => e.message, 'message', 'database is locked'),
        ),
        reason:
            'the write lock is taken by the verb, so the second writer is '
            'stopped at the top — before it can read a total it would then be '
            'allowed to make a decision on',
      );

      first.execute('COMMIT');

      expect(() => second.execute('BEGIN IMMEDIATE'), returnsNormally);
    });

    test('makes aloneIn fail at COMMIT, and the finally is what undoes it', () async {
      // Seeded first: a writer cannot even set a limit while a reader is
      // sitting in an open transaction, which is the same lock arriving one
      // statement earlier.
      final store = await fresh(first);

      // A reader that stays. `BEGIN IMMEDIATE` still lets the writer in — a
      // reserved lock and a shared one coexist — and the exclusive lock
      // `COMMIT` needs does not.
      second.execute('BEGIN');
      expect(spent(second), 0);
      await expectLater(
        aloneIn(first, () => store.record(lunch())),
        throwsA(isA<Busy>()),
        reason:
            'the write was accepted and the commit was not, which is the '
            'one failure path a transaction wrapper is written for and the '
            'only one that reaches the finally with the transaction still open',
      );

      second.execute('COMMIT');
      expect(
        await store.expenses(),
        isEmpty,
        reason:
            'autocommit was still false, so the finally rolled it back — a '
            'wrapper that only rolled back when the body threw would have left '
            'this row half-written and said nothing',
      );
    });

    test(
      'is let all the way in by BEGIN, which moves the failure to COMMIT',
      () {
        first.execute('BEGIN');
        second.execute('BEGIN');

        // Two readers, one number, and no lock between them: this is the
        // deferred transaction's version of both callers being told yes.
        expect(spent(first), 0);
        expect(spent(second), 0);

        expect(() => first.execute(insert), returnsNormally);
        expect(
          () => second.execute(insert),
          throwsA(
            isA<SqliteException>().having((e) => e.resultCode, 'code', 5),
          ),
          reason:
              'BEGIN takes a shared lock at the first read and has to '
              'upgrade it to write, and the upgrade is what fails',
        );

        expect(
          () => first.execute('COMMIT'),
          throwsA(
            isA<SqliteException>().having((e) => e.resultCode, 'code', 5),
          ),
          reason:
              'and the writer that did get in cannot finish either, because '
              'the other one is still reading. COMMIT is the statement nobody '
              'writes a catch around, which is why the finally in alone is not '
              'optional — nothing is recorded and both callers are told so',
        );
      },
    );
  });
  // #endregion lock

  // #region named
  group('and a locked database, at the two edges that have to answer for it', () {
    late Directory directory;
    late Database held;
    late Database mine;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('named');
      final path = '${directory.path}/expenses.db';
      held = sqlite3.open(path);
      mine = sqlite3.open(path);
      SqliteStore(held);
    });

    tearDown(() {
      held.close();
      mine.close();
      directory.deleteSync(recursive: true);
    });

    test('is Busy rather than a type two edges are not allowed to see', () {
      held.execute('BEGIN IMMEDIATE');

      expect(
        () => SqliteStore(mine).record(lunch()),
        throwsA(isA<Busy>()),
        reason:
            'server.dart and command.dart may not import package:sqlite3 — '
            'test/surface_test.dart is there to stop it — so the one file that '
            'may is the file that gives the failure a name',
      );
    });

    test('and every statement is translated, not only the transaction', () {
      held.execute('BEGIN IMMEDIATE');
      final store = SqliteStore(mine);

      expect(() => store.setLimit(limit), throwsA(isA<Busy>()));
      expect(
        () => aloneIn(mine, () => store.record(lunch())),
        throwsA(isA<Busy>()),
      );
    });

    test('but a CHECK violation is still this program being wrong', () {
      expect(
        () => mine.execute(
          "INSERT INTO expenses (day, pence, category, note, acknowledged) "
          "VALUES ('2026-09-11', -1, 'food', 'lunch', 0)",
        ),
        throwsA(isA<SqliteException>()),
        reason:
            'only result code 5 is renamed; anything else arrives looking '
            'like what it is',
      );
    });

    test('the server answers 503 and says the request is worth repeating', () async {
      final api = expensesApi(
        Tracker(SqliteStore(mine), () => day, lockedBy(mine)),
        key: 'k',
        report: (error, stack) => fail('a conflict is not a fault: $error'),
      );
      held.execute('BEGIN IMMEDIATE');

      final answer = await api(_post());

      expect(answer.statusCode, 503);
      expect(
        jsonDecode(await answer.readAsString()),
        {'problem': 'another writer has the database; try again'},
        reason:
            '500 would have said this program is wrong, which is false, '
            'and 409 would have said send something else, which is also false',
      );
    });

    test(
      'and the command line answers refused rather than a stack trace',
      () async {
        final store = SqliteStore(mine);
        held.execute('BEGIN IMMEDIATE');

        final outcome = await run(
          ['add', '6.00', 'food', 'lunch'],
          store,
          day,
          alone: lockedBy(mine),
        );

        expect(outcome.code, refused);
        expect(outcome.err, 'another writer has the database; try again');
        expect(
          outcome.out,
          isEmpty,
          reason:
              "run's contract since study 24 is an Outcome and never a "
              'print, and an uncaught SqliteException breaks both halves',
        );
      },
    );
  });
  // #endregion named

  // #region blocking
  group('and waiting for that lock', () {
    test('stops this isolate, which is why there is no busy timeout', () async {
      final directory = Directory.systemTemp.createTempSync('busy');
      addTearDown(() => directory.deleteSync(recursive: true));
      final path = '${directory.path}/expenses.db';

      final holder = sqlite3.open(path);
      final waiter = sqlite3.open(path);
      addTearDown(() {
        holder.close();
        waiter.close();
      });
      SqliteStore(holder);
      holder.execute('BEGIN IMMEDIATE');

      // Long enough that a timer due immediately would certainly have run, and
      // short enough to be a test. The assertion is not about the number.
      waiter.execute('PRAGMA busy_timeout = 200');

      var ticked = false;
      Timer.run(() => ticked = true);

      expect(() => waiter.execute(insert), throwsA(isA<SqliteException>()));

      expect(
        ticked,
        isFalse,
        reason:
            'SQLite waits inside the C call and dart:ffi runs it on this '
            "isolate's only thread, so a server that waits for a lock is a "
            'server answering nobody. The same synchrony that made two '
            'requests unable to interleave is what makes this unaffordable',
      );
    });
  });
  // #endregion blocking
}

// #region sockets
/// Two `POST /expenses` written to two open sockets before either is read.
///
/// **Every socket is connected before a single byte is written**, and that is
/// the harness rather than a detail. Awaiting `Socket.connect` for the second
/// request lets the server finish the first one before the second exists, so a
/// version that does it in one loop measures the client's pacing and reports
/// that nothing ever interleaves.
///
/// `connection: close` because HTTP/1.1 keeps a socket open otherwise, and a
/// test that waits for a socket nobody is going to close is a test that waits.
Future<void> twoAtOnce(int port) async {
  const body = '{"pence":600,"category":"food","note":"lunch"}';
  final sockets = [
    for (var i = 0; i < 2; i++) await Socket.connect('localhost', port),
  ];
  for (final socket in sockets) {
    socket.write(
      'POST /expenses HTTP/1.1\r\n'
      'host: localhost\r\n'
      'connection: close\r\n'
      'authorization: Bearer k\r\n'
      'content-type: application/json\r\n'
      'content-length: ${body.length}\r\n\r\n$body',
    );
  }
  await Future.wait([for (final socket in sockets) socket.flush()]);
  await Future.wait([
    for (final socket in sockets) socket.map((_) => 0).drain<void>(),
  ]);
}
// #endregion sockets
