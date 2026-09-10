import 'category.dart';
import 'expense.dart';
import 'money.dart';

// #region line
/// One line of a report: a category, and what went to it.
///
/// A value by study 25's rules — two lines with the same category and the same
/// amount say the same thing — and the first type in this program to be
/// [Comparable], because a report is a thing with an order.
class const CategoryTotal(final Category category, final Money spent)
    implements Comparable<CategoryTotal> {
  /// Dearest first, and ties broken by name.
  ///
  /// The tie-break is not tidiness. `List.sort` is **not a stable sort** —
  /// measured, it keeps the order of equal elements up to 33 of them and stops
  /// at 34 — so two categories on the same amount would hold their order in
  /// every test anyone is likely to write and swap in front of a real user.
  ///
  /// Implementing [Comparable] is a promise of a **total** order: any two
  /// lines compare, and the answer does not depend on what the list happened
  /// to look like beforehand. Returning 0 for two different categories breaks
  /// that promise, so this never does.
  @override
  int compareTo(CategoryTotal other) {
    final byAmount = other.spent.compareTo(spent);
    return byAmount != 0
        ? byAmount
        : category.name.compareTo(other.category.name);
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryTotal &&
      other.category == category &&
      other.spent == spent;

  @override
  int get hashCode => Object.hash(category, spent);

  @override
  String toString() => '$category: ${spent.asText}';
}
// #endregion line

// #region report
/// What was spent, where it went, and how much of it there was.
///
/// This is study 27's promise arriving. `totals` was an extension — first on
/// `Store`, then on the expenses themselves — and it only ever answered half a
/// report: a map, in whatever order the keys were first seen, with no total and
/// no opinion about how to show itself. Ordering and totalling are what a report
/// is for, so they live here rather than being lent out by something else.
class const Report._(
  final List<Expense> expenses,
  final List<CategoryTotal> lines,
  final Money total,
) {
  /// Group, order, add up — all of it here, so that a report walks its
  /// expenses once and then answers three questions from what it found.
  factory Report.of(Iterable<Expense> expenses) {
    // A plain loop, and not `fold`. Grouping needs the running map at every
    // step, so a `fold` here would carry the same map through an accumulator
    // and read as an accumulation of something it is not.
    final sums = <Category, Money>{};
    for (final expense in expenses) {
      sums[expense.category] =
          (sums[expense.category] ?? Money.zero) + expense.amount;
    }

    // `sort()` with no comparator at all: it asks the elements, because
    // `CategoryTotal` is `Comparable`. `..` returns the list rather than the
    // `null` that `sort` returns, which is the whole reason the cascade is
    // there.
    final lines = [
      for (final entry in sums.entries) CategoryTotal(entry.key, entry.value),
    ]..sort();

    // And `sort` *with* a comparator, because `Expense` is not comparable and
    // should not be: two expenses on the same day are two expenses, and a type
    // that is `Comparable` is claiming its order is the order.
    final inDayOrder = [...expenses]..sort((a, b) => a.day.compareTo(b.day));

    // `fold` where `fold` belongs: many values in, one out, starting from the
    // identity. `Money.zero` exists to be this argument.
    final total = lines.fold(Money.zero, (sum, line) => sum + line.spent);

    return Report._(inDayOrder, lines, total);
  }

  /// Whether anything was recorded at all.
  bool get isEmpty => expenses.isEmpty;

  /// The report as a person reads it: what happened, then where it went, then
  /// how much.
  String get asText => [
    for (final expense in expenses) expense.asText,
    '',
    for (final line in lines) '$line',
    '',
    'total: ${total.asText}',
  ].join('\n');
}
// #endregion report
