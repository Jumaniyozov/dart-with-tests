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
/// **Everything is read before the transaction opens.** The reads are real disk
/// I/O and the transaction is the one thing here that must not be held open
/// longer than it has to be. What is left inside it is [SqliteStore]'s writes,
/// which reach a C library over `dart:ffi` and are finished before they return
/// — so each `await` resumes on the microtask queue with nothing else able to
/// run. Study 40 is where that sentence is measured rather than asserted.
///
/// **Study 40 also took the transaction out of this function.** It was written
/// here by hand at study 39 — `BEGIN`, a `try`, a `COMMIT`, and a `finally`
/// that rolls back if `autocommit` says the transaction is still open — and
/// then study 40 wrote the identical shape a second time, as [aloneIn], for
/// `Tracker.record`. Two copies of one rule is the shape this book keeps
/// finding, and the moment to look for it is the moment the second caller
/// arrives rather than the third. The second copy is the one that stayed.
///
/// It changed the verb, which is the part that matters: [aloneIn] is `BEGIN
/// IMMEDIATE`, so a move that is going to write takes the write lock before it
/// starts instead of failing to upgrade one halfway through.
///
/// **It does not catch anything, and the `finally` inside [aloneIn] is why it
/// does not have to.** Nothing this program can cause fails here: every value
/// came through [Money], [Category] and [Day], and the schema's `CHECK`s are
/// the rules those types already keep. What is left is a disk that is full or a
/// database somebody else has locked, and there is nothing to do about either
/// but put it back the way it was and let the caller see what happened.
/// Catching it to say *handled* is 39.4.
Future<Moved> moveInto(Store from, Database db) async {
  final to = SqliteStore(db);
  final expenses = await from.expenses();
  final limits = await from.limits;

  await aloneIn(db, () async {
    for (final expense in expenses) {
      await to.record(expense);
    }
    for (final limit in limits) {
      await to.setLimit(limit);
    }
  });
  return (expenses: expenses.length, limits: limits.length);
}
// #endregion move
