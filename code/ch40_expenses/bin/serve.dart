// #region serve
import 'dart:io';

import 'package:ch40_expenses/expenses.dart';
import 'package:ch40_expenses/src/server.dart';
import 'package:ch40_expenses/src/sqlite_store.dart';
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
///
/// **Study 40 measured that and then stopped relying on it.** Forty trials at
/// two, three and four concurrent callers recorded one expense every time, so
/// the lost update Book III declared at study 37 was already gone — closed by
/// a store that happens not to suspend rather than by anything this program
/// says. The second writer that is still real is the command line, in another
/// terminal, against this same file; no fact about this isolate's event loop
/// reaches it, and `store.alone` is what does.
Future<void> main(List<String> args) async {
  final key = Platform.environment['EXPENSES_KEY'];
  if (key == null || key.isEmpty) {
    stderr.writeln('set EXPENSES_KEY to the key callers must send');
    exitCode = misuse;
    return;
  }

  final db = sqlite3.open(fileFrom(args));
  final tracker = Tracker(
    SqliteStore(db),
    () => Day.on(DateTime.now()),
    // The third argument is study 40. Everything about whether this program
    // can be interleaved is decided here, by the edge that chose the database
    // — and it is the database rather than the store that can promise it.
    <T>(body) => aloneIn(db, body),
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
