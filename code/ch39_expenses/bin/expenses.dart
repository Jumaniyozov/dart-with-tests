// #region main
import 'dart:io';

import 'package:ch39_expenses/expenses.dart';
import 'package:ch39_expenses/src/sqlite_store.dart';
import 'package:sqlite3/sqlite3.dart';

/// The only file in this package that knows a terminal exists, and the only one
/// that knows what day it is.
///
/// **`--file` names a database from this study on**, and the default moved from
/// `expenses.txt` to `expenses.db`. `dart run ch39_expenses:migrate` is the one
/// program that reads both, and it is the only time the old file is opened
/// again.
///
/// `sqlite3.open` creates the file if it is not there, and [SqliteStore]'s
/// constructor creates the tables if they are not there, so a first run on a
/// machine with neither works and says nothing about it.
///
/// [Database.close] closes the handle. Nothing here depends on it — every
/// statement this program runs is its own transaction and is on the disk before
/// the call returns — but a program that opens something and does not say where
/// it closes it is a program you have to read all of to be sure. (`dispose` is
/// the deprecated spelling, and the analyzer says so.)
Future<void> main(List<String> args) async {
  final db = sqlite3.open(fileFrom(args));
  final outcome = await run(args, SqliteStore(db), Day.on(DateTime.now()));
  db.close();

  if (outcome.out.isNotEmpty) stdout.writeln(outcome.out);
  if (outcome.err.isNotEmpty) stderr.writeln(outcome.err);
  exit(outcome.code);
}
// #endregion main
