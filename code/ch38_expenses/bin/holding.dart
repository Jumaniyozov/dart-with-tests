// #region holding
import 'dart:io';

import 'package:ch38_expenses/expenses.dart';
import 'package:ch38_expenses/src/server.dart';
import 'package:shelf/shelf_io.dart' as io;

/// `bin/serve.dart` with one value read once instead of asked for, so that one
/// page can show what that costs.
///
/// It exists for study 35's reason and will end study 35's way: a comparison
/// artifact belongs to the study that compares something with it, and study 39
/// deletes both this and the cache it is here to break.
///
/// **The bet is on line one of `main`.** `length` is read at startup and never
/// again, so [HoldingStore] is told the answer has not changed, for ever. Every
/// other line in this file is `bin/serve.dart`'s.
///
/// Nothing here is wrong in a way an analyzer or a test of this program can
/// see. It is wrong because something outside the process — the command line,
/// in another terminal, writing the same file — is a thing this program decided
/// could not happen.
Future<void> main(List<String> args) async {
  final key = Platform.environment['EXPENSES_KEY'];
  if (key == null || key.isEmpty) {
    stderr.writeln('set EXPENSES_KEY to the key callers must send');
    exitCode = misuse;
    return;
  }

  final file = File(fileFrom(args));
  final length = _lengthOf(file);
  final tracker = Tracker(
    HoldingStore(FileStore(file), () => length),
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
int _lengthOf(File file) => file.existsSync() ? file.lengthSync() : 0;
// #endregion holding
