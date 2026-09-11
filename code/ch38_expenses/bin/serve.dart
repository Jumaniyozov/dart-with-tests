// #region serve
import 'dart:io';

import 'package:ch38_expenses/expenses.dart';
import 'package:ch38_expenses/src/server.dart';
import 'package:shelf/shelf_io.dart' as io;

/// The server's edge, and everything an edge is allowed to know.
///
/// **Two things that were read once are now asked for.** Study 37's version
/// opened the file on every request and captured the day at startup; this one
/// holds the file's contents and asks the clock. Both changes are the same
/// sentence read in opposite directions — *a value read once is a bet that
/// nothing else can change it* — and `bin/holding.dart` is the program that
/// makes the bet and loses it.
///
/// `file.lengthSync()` is the reason to believe. It is a `stat` rather than a
/// read: the file is only opened when the number it answers has moved. What
/// that catches and what it does not is 38.4, and it is not a guarantee.
Future<void> main(List<String> args) async {
  final key = Platform.environment['EXPENSES_KEY'];
  if (key == null || key.isEmpty) {
    stderr.writeln('set EXPENSES_KEY to the key callers must send');
    exitCode = misuse;
    return;
  }

  final file = File(fileFrom(args));
  final tracker = Tracker(
    HoldingStore(FileStore(file), () => _lengthOf(file)),
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

/// How many bytes are in the file, or `0` when there is not one yet.
///
/// A file that does not exist is not an error here: `FileStore` answers an
/// empty list for one, so `0` is the true version of that answer and the first
/// `record` moves it.
int _lengthOf(File file) => file.existsSync() ? file.lengthSync() : 0;
// #endregion serve
