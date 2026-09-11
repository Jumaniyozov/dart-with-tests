// #region migrate
import 'dart:io';

import 'package:args/args.dart';
import 'package:ch39_expenses/expenses.dart';
import 'package:ch39_expenses/src/migration.dart';
import 'package:ch39_expenses/src/sqlite_store.dart';
import 'package:sqlite3/sqlite3.dart';

/// Move what study 28 put in a file into the database study 39 reads.
///
/// The one program in this book that a reader runs **once** and then never
/// again. That is the whole of its design: it refuses a database that already
/// holds expenses, because nothing in an expense identifies it and a second run
/// would file every one of them a second time.
///
/// **The refusal is `expenses(count: 1)`, and it is only cheap because of
/// 39.5.** *Is there anything in here?* used to mean reading everything in here
/// and looking at the length. It is now a `LIMIT 1`.
Future<void> main(List<String> args) async {
  final ArgResults parsed;
  try {
    parsed = _parser.parse(args);
  } on ArgParserException catch (error) {
    stderr.writeln('${error.message}\n\n${_parser.usage}');
    exitCode = misuse;
    return;
  }
  final from = File(parsed.option('from')!);
  final to = parsed.option('to')!;

  if (!from.existsSync()) {
    stderr.writeln('there is no ${from.path} to move');
    exitCode = misuse;
    return;
  }

  final db = sqlite3.open(to);
  try {
    if ((await SqliteStore(db).expenses(count: 1)).isNotEmpty) {
      stderr.writeln(
        '$to already holds expenses, and this move only happens once',
      );
      exitCode = refused;
      return;
    }
    final moved = await moveInto(FileStore(from), db);
    stdout.writeln(
      'moved ${_plural(moved.expenses, 'expense')} and '
      '${_plural(moved.limits, 'budget')} into $to',
    );
  } finally {
    db.close();
  }
}

final _parser = ArgParser()
  ..addOption('from', defaultsTo: 'expenses.txt', help: 'the file to read')
  ..addOption('to', defaultsTo: 'expenses.db', help: 'the database to write');

/// A count and its noun, agreeing.
String _plural(int count, String noun) =>
    '$count $noun${count == 1 ? '' : 's'}';
// #endregion migrate
