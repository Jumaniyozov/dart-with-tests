// Study 29 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are the boundary: something arrives as `dynamic` and has to be
// turned into something the rest of the program can trust.

import 'package:ch29_expenses/expenses.dart';

/// 1. A budget, written down and read back.
///
///    [Budget] is a limit for one category. Give it a `toJson` of exactly two
///    keys — `category` (the normalised name) and `pence` — and a
///    [budgetFromJson] that answers `null` for anything that is not one.
///
///    Use a **map pattern**, not `as`. A file somebody edited is the world
///    being awkward; a `TypeError` out of a cast is a bug, and study 26 says
///    those are different things.
///
///    The domain still has opinions JSON does not: a limit of zero or less is
///    not a budget, and a blank category is not a category.
class const Budget(final Category category, final Money limit);

Map<String, Object?> budgetToJson(Budget budget) =>
    throw UnimplementedError('1');

Budget? budgetFromJson(Object? json) => throw UnimplementedError('1');

/// 2. Read a whole file's worth at once, and keep going.
///
///    [expensesFrom] takes the text of a file — one JSON object per line, the
///    format study 29 writes — and answers every expense it could read.
///
///    A line it cannot read is skipped and the rest still arrive. That
///    includes text that is not JSON at all, so this is one of the few places
///    a `catch` belongs; `jsonDecode` throws a [FormatException], which is an
///    `Exception` and not an `Error`.
///
///    An empty text is an empty list, not a list holding one failure.
List<Expense> expensesFrom(String text) => throw UnimplementedError('2');

/// 3. Say what could not be read, rather than dropping it in silence.
///
///    [readReport] answers a record: the expenses that were read, and the
///    **line numbers** of the ones that were not, counting from 1.
///
///    Skipping quietly is what `expensesFrom` does and it is a real choice,
///    not an obviously right one. A program that has just lost three lines of
///    somebody's spending should be able to say so.
typedef ReadReport = ({List<Expense> read, List<int> skipped});

ReadReport readReport(String text) => throw UnimplementedError('3');
