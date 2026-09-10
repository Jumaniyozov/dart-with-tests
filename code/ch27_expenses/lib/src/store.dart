import 'category.dart';
import 'expense.dart';
import 'money.dart';

// #region store
/// What holds expenses.
///
/// Deliberately not a *ledger*: a ledger is double-entry, with every amount
/// appearing twice, and this is not that.
///
/// An **interface** from this study on. Study 25 shipped it as a concrete class
/// on purpose — an interface with one implementation is machinery a reader
/// cannot judge. It has two now: [InMemoryStore], which every test runs
/// against, and study 28's file.
///
/// `abstract interface class` says *implement me, do not extend me*. There is
/// no behaviour in here to inherit, and saying so is the difference between a
/// contract and a class other people happen to be implementing.
abstract interface class Store {
  /// Keep an expense.
  void record(Expense expense);

  /// Everything recorded, in the order it arrived.
  List<Expense> get all;
}
// #endregion store

// #region totals
/// What was spent on each category.
///
/// An extension rather than a member of [Store], because it is **derived**: two
/// stores holding the same expenses must answer this identically, so there is
/// nothing here for an implementation to decide. Put it on the interface and
/// study 28's file has to write this fold again, which is work with no purpose
/// and a chance to get it wrong.
///
/// This is the map that makes [Category]'s `==` and `hashCode` load-bearing.
/// Get either of them wrong and one category quietly becomes two rows.
extension Totals on Store {
  Map<Category, Money> get totals {
    final sums = <Category, int>{};
    for (final expense in all) {
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
/// stops. Study 28 adds one that does not forget.
///
/// This is the **fake** the tests use, and it is not a test-only class — it is
/// the store the program itself runs on until study 28. A fake implements the
/// behaviour, so a test that uses it asks what the program did rather than
/// which methods it happened to call.
class InMemoryStore implements Store {
  final List<Expense> _recorded = [];

  @override
  void record(Expense expense) => _recorded.add(expense);

  /// `List.unmodifiable` copies once and hands back a list that throws if
  /// anyone calls `add` on it. Returning `_recorded` itself would hand callers
  /// the store's own list and let them change it behind its back.
  @override
  List<Expense> get all => List.unmodifiable(_recorded);
}
// #endregion memory
