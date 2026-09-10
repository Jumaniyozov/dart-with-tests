import 'category.dart';
import 'expense.dart';
import 'money.dart';

// #region store
/// What holds expenses.
///
/// Deliberately not a *ledger*: a ledger is double-entry, with every amount
/// appearing twice, and this is not that.
///
/// **Every member returns a `Future` from this study on**, and that is a change
/// to what the interface promises rather than to how it is implemented. A
/// signature is a claim about time: `void record(Expense)` says the expense is
/// kept by the moment the call returns. A file cannot say that without stopping
/// the program to prove it, so the promise had to be the weaker, truer one.
///
/// `InMemoryStore` pays nothing for this — it is done before it returns and
/// says so by returning an already-completed future. It is [FileStore] that
/// needed the room.
abstract interface class Store {
  /// Keep an expense. The future completes when it is kept.
  Future<void> record(Expense expense);

  /// Everything recorded, in the order it arrived.
  Future<List<Expense>> get all;
}
// #endregion store

// #region totals
/// What was spent on each category.
///
/// An extension rather than a member of [Store], because it is **derived**: two
/// stores holding the same expenses must answer this identically, so there is
/// nothing here for an implementation to decide. Put it on the interface and
/// [FileStore] has to write this fold again, which is work with no purpose and
/// a chance to get it wrong.
///
/// It waits for `all` and nothing else, so it costs whatever the store costs
/// and not a penny more.
///
/// This is the map that makes [Category]'s `==` and `hashCode` load-bearing.
/// Get either of them wrong and one category quietly becomes two rows.
extension Totals on Store {
  Future<Map<Category, Money>> get totals async {
    final sums = <Category, int>{};
    for (final expense in await all) {
      sums[expense.category] =
          (sums[expense.category] ?? 0) + expense.amount.pence;
    }
    return {
      for (final entry in sums.entries) entry.key: Money.fromPence(entry.value),
    };
  }
}
// #endregion totals

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
