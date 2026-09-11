import 'budget.dart';
import 'expense.dart';
import 'store.dart';

// #region holding
/// A [Store] that reads what it wraps once and holds on to the answer.
///
/// Study 28 shipped a [Store] that opens the file on every call and said in as
/// many words that this was fine for a command and would not be fine for a
/// server: *"it will read once and hold on, and it will need a reason to
/// believe what it holds is still true."* This is the first half. [version] is
/// the second.
///
/// **It has never heard of a file, and that is deliberate.** What a cache needs
/// is not *the thing it is caching* but a cheap way to ask whether the answer
/// has changed — so that arrives as a function answering a number, and this
/// class holds what it was given until that number is different. Study 27's
/// argument, fourth time of asking: a dependency on the world is a parameter,
/// and the one end that wants an interface is the end with alternatives. There
/// is exactly one of these.
///
/// It also keeps `file_store.dart`'s doc comment true. That file says it is the
/// only type under `lib/` that has heard of `dart:io`, and a class taking a
/// `File` here would have made it a liar — which `test/server_test.dart#borrowed`
/// would not have caught, because it reads imports and `File` would have come in
/// through this one.
///
/// **Writes are not held.** `record` and `setLimit` go straight through, and the
/// next read finds a different [version] and re-reads everything. That is one
/// extra read per write, and it is the trade a cache with a single number for a
/// stamp makes: correct, and not clever.
class HoldingStore(final Store inner, final int Function() version)
    implements Store {
  /// What [version] said when what is held below was read.
  ///
  /// `null` before anything has been asked, which is not the same as `0` — an
  /// empty file is a real answer with a real version.
  int? _read;

  List<Expense>? _expenses;
  List<Limit>? _limits;

  /// Throw away what is held if the answer can have changed.
  ///
  /// **The version is taken before the read, and the order is load-bearing.**
  /// `inner.all` suspends, and a write can land while it is suspended. Stamping
  /// first means that write is recorded as unseen and the next ask goes back
  /// for it — one extra read. Stamping *after* the read would record it as
  /// seen, and the held copy would be wrong until something else moved the
  /// file. Asserted in `test/holding_store_test.dart`, because swapping two
  /// adjacent lines is the easiest edit in this file to make by accident.
  ///
  /// Two concurrent reads can both find nothing held and both go to [inner].
  /// Both get the right answer and one of them writes it down twice, which is
  /// wasteful and not wrong. Study 40 is where a suspension in the middle of a
  /// read is worth talking about properly.
  void _check() {
    final now = version();
    if (now == _read) return;
    _read = now;
    _expenses = null;
    _limits = null;
  }

  @override
  Future<List<Expense>> get all async {
    _check();
    return _expenses ??= await inner.all;
  }

  @override
  Future<List<Limit>> get limits async {
    _check();
    return _limits ??= await inner.limits;
  }

  @override
  Future<void> record(Expense expense) => inner.record(expense);

  @override
  Future<void> setLimit(Limit limit) => inner.setLimit(limit);
}
// #endregion holding
