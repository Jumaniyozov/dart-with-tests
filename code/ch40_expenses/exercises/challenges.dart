// Study 40 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are the answers this study weighed and did not ship. `alone` is a
// boundary and nothing else: the second caller is refused, loudly, and that is
// the whole of its policy. A bigger program wants a policy — wait your turn,
// wait a while, or try again — and each of these is one of them, written as an
// `Alone` you could hand to a `Tracker` instead.

import 'package:ch40_expenses/expenses.dart';
import 'package:sqlite3/sqlite3.dart';

/// 1. Make the second caller wait instead of refusing it.
///
///    Answer an [Alone] that runs bodies **one at a time, in the order it was
///    asked**, so two calls already in flight both get served: the first
///    records, the second reads a month the first one has already changed, and
///    the budget refuses it as a `Breach` rather than SQLite refusing it as an
///    exception.
///
///    A queue in Dart is a future you keep. Hold the last one you handed out,
///    chain the next body onto it, and store the result as the new last —
///    which is three lines and no lock, because an isolate has one thread and
///    the only thing you are serialising against is itself.
///
///    **A body that throws must not wedge the queue.** The caller gets the
///    error; the callers behind it get their turn.
Alone serialised() => throw UnimplementedError('1');

/// 2. Set a pragma for the length of one body and put it back.
///
///    Answer whatever [body] answers, having run it with `busy_timeout` set to
///    [milliseconds] — and with the value that was there before restored on
///    the way out, whichever way out it takes.
///
///    `PRAGMA busy_timeout = N` sets it and `PRAGMA busy_timeout` reads it
///    back, as a one-row, one-column `select`. There is no catch in the
///    answer: study 20's `finally` is the clause for this and the only one.
Future<T> withBusyTimeout<T>(
  Database db,
  int milliseconds,
  Future<T> Function() body,
) => throw UnimplementedError('2');

/// 3. Try again, once, and only for the failure that is worth trying again.
///
///    Answer an [Alone] that runs the body through [inner], and — if that
///    throws a [SqliteException] whose `resultCode` is 5, which is
///    `SQLITE_BUSY` — runs it through [inner] one more time.
///
///    A second failure is the caller's, and so is anything that is not a 5: a
///    `CHECK` violation retried is a `CHECK` violation twice. That is the
///    difference between a retry and a loop.
Alone retryingOnce(Alone inner) => throw UnimplementedError('3');
