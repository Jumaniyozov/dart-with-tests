// #region alone
/// Something that runs a body with nothing else writing underneath it.
///
/// **A generic function type, because the body is not [Tracker.record]'s to
/// keep.** `Future<Verdict?> Function(...)` would have been enough for the one
/// caller there is, and would have been a guess about the next one — the same
/// mistake as an optional parameter nobody passes, spelled in a return type.
/// Study 39's first challenge asked the reader to write `atomically<T>` over a
/// `Database`; this is that shape with the database taken out of it.
///
/// And taking it out is the whole reason this is a function rather than a
/// member on [Store]. Study 28 settled what an interface may promise: the
/// weakest implementation's promise is the interface's promise, which is why
/// every member of `Store` answers a `Future` for `FileStore`'s sake. A
/// `Store.alone` would have had to promise the opposite direction — more than
/// `FileStore` can keep — and the two implementations that could keep it would
/// have been carrying a member the one that could not was lying about.
///
/// So it is handed in, exactly the way study 38 handed in the clock. The thing
/// that can really make a unit of work is the database, `bin/` is where this
/// program decides which database it has, and `bin/` is therefore where it is
/// decided whether anything is guaranteed at all.
typedef Alone = Future<T> Function<T>(Future<T> Function() body);

/// Run [body], and promise nothing about what else runs while it does.
///
/// **The honest default, and the name is the documentation.** A [Tracker] built
/// with this one is a tracker whose read-decide-write can be interleaved by
/// anything that gets a turn in the middle of it — and whether anything does is
/// a property of the store rather than of this program, which is the reason a
/// program should not rely on it.
///
/// Book III's spike measured exactly where the turn has to fall. A store that
/// suspends in the **read** is harmless: every caller resumes with the same
/// answer and the first to resume runs decision-and-write to completion,
/// because nothing after the read yields — one expense recorded, 30 trials out
/// of 30. A store that suspends in the **write** breaches every time, over the
/// same 30. So *it suspends* is not the condition; *it suspends between the
/// decision and the write* is.
///
/// It is what the tests use, because a test with one store and one caller has
/// no second writer to exclude, and it is half of what `bin/writers.dart`
/// shows. Nothing that serves a reader is built with it.
Future<T> unguarded<T>(Future<T> Function() body) => body();

/// Another writer has the database, and this one did not wait for it.
///
/// **A name, and that is the whole of what it adds.** SQLite answers
/// `SqliteException(5): database is locked`, which is a perfectly good
/// description and a type two edges of this program are not allowed to see:
/// `server.dart` must not import `package:sqlite3` and neither must
/// `command.dart`, for the reason study 34 gave and `test/surface_test.dart`
/// keeps. So the one file that does translates it, and this is what comes out.
///
/// **It is thrown rather than returned, which is study 26's rule bending as
/// far as it bends.** That study says an expected outcome comes back as a
/// value, and a caller being told *not now* is expected. But [Alone] answers
/// whatever the body answers — there is no room in `Future<T>` for a second
/// kind of answer without giving every caller of [Tracker.record] a sum type to
/// unwrap for a case they will meet once. So it is thrown, and it is caught at
/// both edges rather than left to reach a reader: `503` over HTTP, and
/// `refused` at the terminal.
///
/// Nothing retries it. Study 40's third challenge is what retrying would look
/// like, and why once is the only number that is not a loop.
class const Busy() implements Exception {
  @override
  String toString() => 'another writer has the database';
}
// #endregion alone
