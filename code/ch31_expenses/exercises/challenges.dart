// Study 31 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are about order: what one is, when a type is allowed to claim one,
// and what happens to the elements a comparison calls equal.

import 'package:ch31_expenses/expenses.dart';

/// 1. The biggest single expense in a report.
///
///    [dearest] answers the one expense that cost the most, or `null` when
///    there were none at all. Ties go to the earlier day, and if two expenses
///    on the same day cost the same, either will do — say so by picking one
///    rather than by leaving it to `sort`.
///
///    `Money` is [Comparable] now and so is [Day]. You should not need to
///    mention `pence` anywhere.
Expense? dearest(Iterable<Expense> expenses) => throw UnimplementedError('1');

/// 2. An order somebody else chose.
///
///    [byNameThenAmount] is a comparator — the function `sort` takes when the
///    elements' own order is not the one you want. Categories alphabetically,
///    and where two lines share a category, the cheaper first.
///
///    It must be a **total** order: it returns 0 only for lines that are
///    genuinely the same line, because `List.sort` is not stable and will move
///    ties around once there are enough of them.
int Function(CategoryTotal, CategoryTotal) get byNameThenAmount =>
    throw UnimplementedError('2');

/// 3. Where the money went, as whole percents.
///
///    [shareOfSpending] answers a map from category to its share of the
///    report's total, rounded down to a whole number — `food` at £3.50 of
///    £10.00 is 35.
///
///    An empty report is an empty map and not a division by zero. The shares
///    do not have to add up to 100, and pretending otherwise is how rounding
///    bugs get written; the test does not ask them to.
Map<Category, int> shareOfSpending(Report report) =>
    throw UnimplementedError('3');
