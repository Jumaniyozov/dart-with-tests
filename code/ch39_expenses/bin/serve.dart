// #region serve
import 'dart:io';

import 'package:ch39_expenses/expenses.dart';
import 'package:ch39_expenses/src/server.dart';
import 'package:ch39_expenses/src/sqlite_store.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:sqlite3/sqlite3.dart';

/// The server's edge, and everything an edge is allowed to know.
///
/// **The cache is gone and nothing replaced it.** Study 38 wrapped the store in
/// a `HoldingStore` and gave it a byte count to ask whether the file had moved,
/// because `FileStore.all` read the whole file on every single request. A
/// database answers the question it was asked, so there is nothing left worth
/// holding — and the reason a cache can be deleted is a better ending than any
/// improvement to it would have been.
///
/// The other half of study 38 stays exactly as it was: `() => Day.on(...)` is
/// still a function, because a server that runs for days still has to be asked
/// what day it is. One of the two bets was a bet about a file and one was a bet
/// about a clock, and only the first of them had a better store underneath it.
///
/// One [Database], opened once and never closed, because this program does not
/// stop. Every request reads through it, and `sqlite3` is a C library over
/// `dart:ffi` rather than an event loop, so a read does not suspend and two
/// requests cannot be inside one halfway through.
Future<void> main(List<String> args) async {
  final key = Platform.environment['EXPENSES_KEY'];
  if (key == null || key.isEmpty) {
    stderr.writeln('set EXPENSES_KEY to the key callers must send');
    exitCode = misuse;
    return;
  }

  final tracker = Tracker(
    SqliteStore(sqlite3.open(fileFrom(args))),
    () => Day.on(DateTime.now()),
  );
  final api = expensesApi(
    tracker,
    key: key,
    report: (error, stack) => stderr.writeln('$error\n$stack'),
  );

  final server = await io.serve(api, 'localhost', 8080);
  stdout.writeln('listening on http://localhost:${server.port}');
}
// #endregion serve
