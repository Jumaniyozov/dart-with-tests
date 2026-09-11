// #region serve
import 'dart:io';

import 'package:ch37_expenses/expenses.dart';
import 'package:ch37_expenses/src/server.dart';
import 'package:shelf/shelf_io.dart' as io;

/// The server's edge, and everything an edge is allowed to know.
///
/// Which file, which day it is, which port, **and now the key** — four facts
/// about the world, read once, here.
///
/// The key comes from the environment rather than from `--key`, because an
/// argument is in the shell history of whoever started it and in the output of
/// `ps` for everybody else on the machine. Missing, the server does not start:
/// a program that silently answers strangers because a variable was misspelt
/// is worse than one that refuses to run, and `misuse` is study 24's own word
/// for being asked something the program cannot make sense of.
///
/// **`Day.on(DateTime.now())` is still read once, and this program still does
/// not exit.** Study 38 is where that gets broken on purpose and fixed.
Future<void> main(List<String> args) async {
  final key = Platform.environment['EXPENSES_KEY'];
  if (key == null || key.isEmpty) {
    stderr.writeln('set EXPENSES_KEY to the key callers must send');
    exitCode = misuse;
    return;
  }

  final tracker = Tracker(
    FileStore(File(fileFrom(args))),
    Day.on(DateTime.now()),
  );
  final api = expensesApi(
    tracker,
    key: key,
    // The one place in this program that decides where a fault is written
    // down, and it is the file that already owns the terminal.
    report: (error, stack) => stderr.writeln('$error\n$stack'),
  );

  final server = await io.serve(api, 'localhost', 8080);
  stdout.writeln('listening on http://localhost:${server.port}');
}
// #endregion serve
