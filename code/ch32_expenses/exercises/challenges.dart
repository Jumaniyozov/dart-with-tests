// Study 32 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are about where a rule lives. The first two need facts that no
// single object holds, and the third is a rule that genuinely does fit inside
// one — which is the comparison the study is built on.

import 'package:ch32_expenses/expenses.dart';

/// 1. Every budget that is broken, worst first.
///
///    [broken] answers only the budgets that have been passed, ordered by how
///    far over they are, the furthest over first. Ties go to the category name,
///    for study 31's reason: `List.sort` is not stable, and a tie that keeps
///    its order in a test will not keep it for a user.
///
///    A budget spent exactly to its limit is not broken. A budget with nothing
///    spent against it is not broken. Compare in pence — [Money] is
///    [Comparable], and `Money - Money` is the subtraction that answers `null`
///    when there is nothing to take.
List<Budget> broken(Iterable<Budget> budgets) => throw UnimplementedError('1');

/// 2. What the month would look like if one more thing were bought.
///
///    [afterAll] takes a budget and several expenses and answers the verdict
///    on adding *all* of them, not each one separately. Three £8 lunches
///    against £20 left is one [Breach] of £4, not three separate answers.
///
///    An empty list of expenses is the verdict on the budget as it already
///    stands. Build the answer from [Budget], rather than reaching for the
///    arithmetic yourself; the point of the type is that the rule is inside it.
Verdict afterAll(Budget budget, Iterable<Expense> expenses) =>
    throw UnimplementedError('2');

/// 3. A rule that fits inside one object.
///
///    [isSuspicious] says whether a single expense looks like a typo: an
///    amount of £1000 or more, or a note that is empty once trimmed.
///
///    Nothing else in the store matters and nothing else is consulted, which
///    is exactly why this is *not* an aggregate and needs no [Budget], no
///    [Period] and no [Store]. Most rules are this one. The study is about the
///    ones that are not.
bool isSuspicious(Expense expense) => throw UnimplementedError('3');
