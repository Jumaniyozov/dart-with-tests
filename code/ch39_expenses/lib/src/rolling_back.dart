/// Two answers to a statement that failed inside a transaction, side by side.
///
/// **A demonstration, and deliberately not part of this package.** It sits
/// under `lib/src/` and out of the barrel, the way study 26's `asserting.dart`
/// does: reaching it means naming the file. `migration.dart` is the shipped
/// code and it looks like neither of these.
///
/// The rows these are handed come from a test, because this program cannot
/// build one the schema refuses — every amount it writes came through `Money`,
/// which has no negative value to hand over. The `CHECK` is there for whatever
/// else opens the file, and this is where you can watch it fire.
library;

import 'package:sqlite3/sqlite3.dart';

// #region caught
/// The one statement both of these run, so that the only thing that differs
/// between them is what they do when it fails.
const _insert =
    'INSERT INTO expenses (day, pence, category, note, acknowledged) '
    'VALUES (?, ?, ?, ?, 0)';

/// Insert every row in one transaction, and **catch** what SQLite throws.
///
/// This is the shape everybody writes first, and every word of it looks right.
/// The rows go in a transaction so that a failure cannot leave half of them
/// behind. The exception is caught rather than allowed to take the program
/// down. The transaction is committed at the end, on the way out.
///
/// What it does is commit the half. A failing statement is rolled back by
/// SQLite on its own; the **transaction around it is not**, and
/// [Database.autocommit] is `false` from the moment of the throw. So `COMMIT`
/// here commits every row that went in before the bad one — and the caller is
/// told nothing at all, because the exception was handled.
void caughtAndCommitted(Database db, List<List<Object?>> rows) {
  db.execute('BEGIN');
  try {
    for (final row in rows) {
      db.execute(_insert, row);
    }
  } on SqliteException {
    // Handled. Look at what that word is doing in this comment.
  }
  db.execute('COMMIT');
}
// #endregion caught

// #region rolled
/// The same function, with the two lines that make it true.
///
/// `ROLLBACK` is a statement like any other — there is no transaction object to
/// call a method on, and nothing anywhere in `package:sqlite3` will do this for
/// you. The `return` is what stops the `COMMIT` below from running on the way
/// out of a failure, which is the other half of what the version above got
/// wrong.
void caughtAndRolledBack(Database db, List<List<Object?>> rows) {
  db.execute('BEGIN');
  try {
    for (final row in rows) {
      db.execute(_insert, row);
    }
  } on SqliteException {
    db.execute('ROLLBACK');
    return;
  }
  db.execute('COMMIT');
}
// #endregion rolled
