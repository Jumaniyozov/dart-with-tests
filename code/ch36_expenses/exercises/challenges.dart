// Study 36 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are about the line this study drew. Two of them live on the domain
// side of it and are written in the tracker's own words; one lives on the edge
// side and turns a domain answer into something one particular caller needs.
// Notice which is which without being told, because that is the skill.

import 'package:ch36_expenses/expenses.dart';

/// 1. What was spent over a period.
///
///    Use [Tracker.expenses], which already narrows to a period, and add the
///    amounts up. `Money.zero` is the empty total and `+` is what you need;
///    `fold` is study 12's.
///
///    Nothing here reaches for a `Store`. The point of a layer is that the
///    thing above it stops knowing there is one.
///
///    One wrinkle worth meeting on purpose: in an `async` function the return
///    context is a `FutureOr<Money>`, and `fold` will infer *that* as its
///    accumulator type and then refuse `+`. Give it the type argument —
///    `fold<Money>(…)` — which is study 18's lesson about inference taking
///    whatever the context offers and being right about nothing else.
Future<Money> spentIn(Tracker tracker, Period period) =>
    throw UnimplementedError('1');

/// 2. The same verdict, as one caller's exit code.
///
///    [okay] when nothing stood in the way — a `null` verdict, a [Within], or a
///    [Breach] the person acknowledged. [refused] for a [Breach] they did not.
///
///    This is the whole of what the edge adds, written out as a pure function:
///    a number the shell reads, decided from a value the domain handed over.
///    Study 37 writes this function again and answers an HTTP status instead,
///    from the same [Verdict] — which is the argument for the verdict being a
///    value rather than a message.
int codeFor(Verdict? verdict, {required bool acknowledged}) =>
    throw UnimplementedError('2');

/// 3. Which categories have already gone past their limit.
///
///    Ask [Tracker.budgets] and keep the ones a [Budget] says are broken. In
///    the order the budgets came back, and without a duplicate — one limit per
///    category is [Store]'s rule, so there cannot be one.
///
///    `Budget` already knows the answer about itself. If you find yourself
///    comparing two amounts here, look at `Budget` again.
Future<List<Category>> overspent(Tracker tracker) =>
    throw UnimplementedError('3');
