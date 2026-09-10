// #region main
import 'dart:io';

import 'package:ch27_expenses/expenses.dart';

/// The only file in this package that knows a terminal exists — and, from this
/// study, the only one that knows what day it is.
///
/// Both of the program's seams are tied off here, in the file no test ever
/// runs: the store it will use, and the instant that becomes today.
void main(List<String> args) {
  final outcome = run(args, InMemoryStore(), Day.on(DateTime.now()));
  if (outcome.out.isNotEmpty) stdout.writeln(outcome.out);
  if (outcome.err.isNotEmpty) stderr.writeln(outcome.err);
  exit(outcome.code);
}
// #endregion main
