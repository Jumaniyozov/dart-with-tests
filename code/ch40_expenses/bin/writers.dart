// #region writers
import 'dart:io';

import 'package:ch40_expenses/expenses.dart';
import 'package:ch40_expenses/src/sqlite_store.dart';
import 'package:sqlite3/sqlite3.dart';

/// Two writers against one database file, interleaved on purpose.
///
/// **The interleaving is scripted, and that is the only way this could be a
/// transcript.** Two writers that really do overlap breach *sometimes* — Book
/// III's spike measured 11 times in 40, then 10, then 4, for the same
/// experiment — so a program that raced them would print a different answer on
/// the reader's second run. What is deterministic is the *shape*: both read
/// before either writes. This runs that shape, and what each writer is told is
/// then a fact about SQLite rather than about who won.
///
/// Two connections and not two processes, because two connections is what two
/// processes have. The lock SQLite takes is on the file.
///
/// Nothing here prints a day, a duration or a path. A transcript is only
/// re-runnable if every answer in it is a function of the program rather than
/// of when or where it ran.
/// A day written down rather than read off a clock, so this transcript says
/// the same thing next month.
final september11 = Day(2026, 9, 11);

Future<void> main() async {
  final directory = Directory.systemTemp.createTempSync('writers');
  final path = '${directory.path}/expenses.db';

  stdout.writeln('without a boundary');
  await both(path, guarded: false);

  File(path).deleteSync();

  stdout.writeln('\nwith the boundary bin/serve.dart hands over');
  await both(path, guarded: true);

  directory.deleteSync(recursive: true);
}

/// One £10.00 limit, two £6.00 lunches, and both writers in flight at once.
///
/// `Future.wait` and not a loop: a loop would let the first writer finish
/// before the second one read, which is the arrangement in which there is
/// nothing to go wrong. Both calls are started before either is waited on,
/// which is what "two writers" means.
Future<void> both(String path, {required bool guarded}) async {
  final connections = [sqlite3.open(path), sqlite3.open(path)];
  final stores = [for (final db in connections) SqliteStore(db)];
  await stores.first.setLimit(Limit(Category('food'), Money.fromPence(1000)));

  final said = await Future.wait([
    for (var i = 0; i < 2; i++)
      told(
        Tracker(
          stores[i],
          () => september11,
          guarded ? <T>(body) => aloneIn(connections[i], body) : unguarded,
        ),
      ),
  ]);

  stdout.writeln('  first  ${said.first}');
  stdout.writeln('  second ${said.last}');

  final month = Period.of(september11);
  final kept = (await stores.first.expenses(period: month))
      .fold(Money.zero, (sum, expense) => sum + expense.amount);
  stdout.writeln('  the month holds ${kept.asText} against £10.00');

  for (final db in connections) {
    db.close();
  }
}

/// What one writer was told, in one line, whichever way it came back.
Future<String> told(Tracker tracker) async {
  try {
    final verdict = await tracker.record(
      Expense(Money.fromPence(600), Category('food'), september11, 'lunch'),
    );
    return switch (verdict) {
      Within(:final remaining) => 'recorded, ${remaining.asText} left',
      Breach(:final over) => 'refused, ${over.asText} over',
      null => 'recorded, no limit on food',
    };
  } on SqliteException catch (error) {
    return 'not served: ${error.message}';
  }
}
// #endregion writers
