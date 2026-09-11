import 'package:sqlite3/sqlite3.dart';

import 'sqlite_store.dart';
import 'store.dart';

// #region move
/// What one move took across.
///
/// A record and not a class, by study 13's rule: two numbers travelling
/// together, with no invariant to keep and no identity of their own.
typedef Moved = ({int expenses, int limits});

/// Move everything [from] holds into [db] — all of it, or none of it.
///
/// Study 28 put the reader's expenses in a file, one JSON object to a line.
/// This is the one time they move, and it goes through [Store] rather than
/// through the file: [FileStore] already knows that a log holds two shapes on
/// the same lines and that a category's latest limit is the one that counts,
/// and none of that is worth writing a second time against a different
/// destination. Study 27's interface, five studies later, doing the thing an
/// interface is for.
///
/// **Everything is read before `BEGIN`.** The reads are real disk I/O and the
/// transaction is the one thing here that must not be held open longer than it
/// has to be. What is left inside it is [SqliteStore]'s writes, which reach a C
/// library over `dart:ffi` and are finished before they return — so each
/// `await` resumes on the microtask queue with nothing else able to run.
/// Study 40 is where that sentence is measured rather than asserted.
///
/// **It does not catch anything, and the `finally` is why it does not have to.**
/// Nothing this program can cause fails here: every value came through [Money],
/// [Category] and [Day], and the schema's `CHECK`s are the rules those types
/// already keep. What is left is a disk that is full or a database somebody
/// else has locked, and there is nothing to do about either but put it back the
/// way it was and let the caller see what happened. Catching it to say *handled*
/// is 39.4.
Future<Moved> moveInto(Store from, Database db) async {
  final to = SqliteStore(db);
  final expenses = await from.expenses();
  final limits = await from.limits;

  db.execute('BEGIN');
  try {
    for (final expense in expenses) {
      await to.record(expense);
    }
    for (final limit in limits) {
      await to.setLimit(limit);
    }
    db.execute('COMMIT');
  } finally {
    // `COMMIT` closed the transaction and put [Database.autocommit] back to
    // `true`. If anything above threw, it did not — SQLite leaves a failed
    // transaction open — so this line is the whole difference between *none of
    // it* and *some of it*.
    //
    // The `if` is not defensive. A bare `ROLLBACK` here would throw its own
    // exception on the way out of a move that worked: `cannot rollback - no
    // transaction is active`, measured, and it would arrive in place of
    // whatever the real failure was on the way out of one that did not.
    if (!db.autocommit) db.execute('ROLLBACK');
  }
  return (expenses: expenses.length, limits: limits.length);
}
// #endregion move
