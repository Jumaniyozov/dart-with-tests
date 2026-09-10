import 'expense.dart';

// #region store
/// What holds expenses.
///
/// Deliberately not a *ledger*: a ledger is double-entry, with every amount
/// appearing twice, and this is not that.
///
/// **Every member returns a `Future` since study 28**, and that is a change
/// to what the interface promises rather than to how it is implemented. A
/// signature is a claim about time: `void record(Expense)` says the expense is
/// kept by the moment the call returns. A file cannot say that without stopping
/// the program to prove it, so the promise had to be the weaker, truer one.
///
/// `InMemoryStore` pays nothing for this — it is done before it returns and
/// says so by returning an already-completed future. It is [FileStore] that
/// needed the room.
///
/// Two members and no third. `totals` used to hang off this type and no longer
/// does: it is derived from the expenses and not from the store, so study 30
/// moved it onto the expenses, where a caller holding a filtered list can ask
/// it too.
abstract interface class Store {
  /// Keep an expense. The future completes when it is kept.
  Future<void> record(Expense expense);

  /// Everything recorded, in the order it arrived.
  Future<List<Expense>> get all;
}
// #endregion store

// #region memory
/// A [Store] that keeps everything in a list and forgets it when the program
/// stops. [FileStore] is the one that does not.
///
/// This is the **fake** the tests use. A fake implements the behaviour, so a
/// test that uses it asks what the program did rather than which methods it
/// happened to call.
///
/// `async` on a method that never waits for anything is not a lie and not a
/// cost. It wraps the answer in a future that is already complete, which is
/// what the interface asks for and all it asks for.
class InMemoryStore implements Store {
  final List<Expense> _recorded = [];

  @override
  Future<void> record(Expense expense) async => _recorded.add(expense);

  /// `List.unmodifiable` copies once and hands back a list that throws if
  /// anyone calls `add` on it. Returning `_recorded` itself would hand callers
  /// the store's own list and let them change it behind its back.
  @override
  Future<List<Expense>> get all async => List.unmodifiable(_recorded);
}
// #endregion memory
