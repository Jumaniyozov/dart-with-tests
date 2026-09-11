// #region serve
import 'dart:io';

import 'package:ch36_expenses/expenses.dart';
import 'package:ch36_expenses/src/server.dart';
import 'package:shelf/shelf_io.dart' as io;

/// The server's edge, and everything an edge is allowed to know.
///
/// Which file, which day it is, and which port — three facts about the world,
/// read once, here. `bin/expenses.dart` reads exactly the same three and is
/// four lines long for the same reason.
///
/// **`Day.on(DateTime.now())` is read once, and this program does not exit.**
/// That is correct for a command that lives for milliseconds and wrong for a
/// server that runs for days: started on Tuesday, it will still think it is
/// Tuesday on Friday. Study 38 is where that gets broken on purpose and fixed.
Future<void> main(List<String> args) async {
  final tracker = Tracker(
    FileStore(File(fileFrom(args))),
    Day.on(DateTime.now()),
  );
  final server = await io.serve(expensesHandler(tracker), 'localhost', 8080);
  stdout.writeln('listening on http://localhost:${server.port}');
}
// #endregion serve
