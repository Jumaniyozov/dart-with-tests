// #region main
import 'dart:io';

import 'package:ch30_expenses/expenses.dart';

/// Where the tracker keeps what it is told, until study 33 lets you say.
const _path = 'expenses.txt';

/// The only file in this package that knows a terminal exists, and the only one
/// that knows what day it is or which file to use.
///
/// `main` may be `async`, and returning a `Future<void>` is how you tell the
/// runtime to wait for it. Without that the program would reach the end of
/// `main` with the write still outstanding, and `exit` would take the process
/// down mid-sentence.
Future<void> main(List<String> args) async {
  final outcome = await run(
    args,
    FileStore(File(_path)),
    Day.on(DateTime.now()),
  );
  if (outcome.out.isNotEmpty) stdout.writeln(outcome.out);
  if (outcome.err.isNotEmpty) stderr.writeln(outcome.err);
  exit(outcome.code);
}
// #endregion main
