// #region main
import 'dart:io';

import 'package:ch33_expenses/expenses.dart';

/// The only file in this package that knows a terminal exists, and the only one
/// that knows what day it is.
///
/// It no longer knows which file to use either. `--file` says, and [fileFrom]
/// reads it — study 28 left that `const` here and named this study.
///
/// `main` may be `async`, and returning a `Future<void>` is how you tell the
/// runtime to wait for it. Without that the program would reach the end of
/// `main` with the write still outstanding, and `exit` would take the process
/// down mid-sentence.
Future<void> main(List<String> args) async {
  final outcome = await run(
    args,
    FileStore(File(fileFrom(args))),
    Day.on(DateTime.now()),
  );
  if (outcome.out.isNotEmpty) stdout.writeln(outcome.out);
  if (outcome.err.isNotEmpty) stderr.writeln(outcome.err);
  exit(outcome.code);
}
// #endregion main
