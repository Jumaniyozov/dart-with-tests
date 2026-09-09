import 'category.dart';
import 'expense.dart';
import 'money.dart';

// #region store
/// What holds expenses.
///
/// Deliberately not a *ledger*: a ledger is double-entry, with every amount
/// appearing twice, and this is not that.
///
/// It forgets everything when the program stops. Study 28 gives it a file.
class Store {
  final List<Expense> _recorded = [];

  void record(Expense expense) => _recorded.add(expense);

  /// Everything recorded, in the order it arrived.
  ///
  /// `List.unmodifiable` copies once and hands back a list that throws if
  /// anyone calls `add` on it. Returning `_recorded` itself would hand callers
  /// the store's own list and let them change it behind its back.
  List<Expense> get all => List.unmodifiable(_recorded);

  /// What was spent on each category.
  ///
  /// This is the map that makes [Category]'s `==` and `hashCode` load-bearing.
  /// Get either of them wrong and one category quietly becomes two rows.
  Map<Category, Money> get totals {
    final sums = <Category, int>{};
    for (final expense in _recorded) {
      sums[expense.category] =
          (sums[expense.category] ?? 0) + expense.amount.pence;
    }
    return {
      for (final entry in sums.entries) entry.key: Money.fromPence(entry.value),
    };
  }
}
// #endregion store
