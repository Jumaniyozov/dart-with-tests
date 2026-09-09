// #region main
import 'dart:io';

import 'package:ch25_expenses/expenses.dart';

/// The only file in this package that knows a terminal exists.
///
/// It does three things and no thinking: run the arguments, put each kind of
/// text on the stream it belongs on, and hand the shell the number.
void main(List<String> args) {
  final outcome = run(args, Store());
  if (outcome.out.isNotEmpty) stdout.writeln(outcome.out);
  if (outcome.err.isNotEmpty) stderr.writeln(outcome.err);
  exit(outcome.code);
}
// #endregion main
