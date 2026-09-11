// Study 39 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are SQL doing work the program was doing in Dart. One is the
// transaction shape `moveInto` writes out by hand, one is a total the database
// can add up for you, and one is the other end of the list.

import 'package:ch39_expenses/expenses.dart';
import 'package:sqlite3/sqlite3.dart';

/// 1. The `finally` in `moveInto`, written once for every caller.
///
///    Answer whatever [body] answers, having run it inside a transaction: the
///    transaction is committed if [body] returns, and rolled back if anything
///    at all comes out of it — which then carries on out of here too, because
///    there is nothing this function could do about it.
///
///    Three things decide the shape. **A `finally` runs on both ways out**,
///    which is study 20's clause doing the one job it is uniquely for; the
///    check on [Database.autocommit] is not defensive, because a `ROLLBACK`
///    after a `COMMIT` throws `cannot rollback - no transaction is active` and
///    would arrive in place of the real failure; and there is no `catch`
///    anywhere in the answer, because catching something you cannot handle is
///    39.3.
T atomically<T>(Database db, T Function() body) =>
    throw UnimplementedError('1');

/// 2. A total the database adds up.
///
///    Answer what was spent on [category] in [period], as a single `SELECT`.
///    `Budget.spent` folds a list of expenses in Dart, which means every one of
///    them crossed the boundary first; this is the same number with nothing
///    crossing but the number.
///
///    `SUM` over no rows answers `NULL`, not `0` — which arrives in Dart as a
///    `null` and is the one thing about this that is not obvious. `COALESCE`
///    is SQL's `??`.
///
///    Bind the three values rather than writing them into the string. A
///    category is text somebody typed.
Money spentIn(Database db, Category category, Period period) =>
    throw UnimplementedError('2');

/// 3. The other end of the list.
///
///    Answer the pence of the last [count] expenses recorded, **oldest first**
///    — so `latest(db, 2)` over four expenses of 100, 200, 300 and 400 answers
///    `[300, 400]`.
///
///    `Store.expenses` takes the *first* `count`, and 39.4 says why: bounding
///    an answer and choosing which end of it are different jobs. This is the
///    other one, and the trap is that the obvious statement gives them to you
///    backwards.
List<int> latest(Database db, int count) => throw UnimplementedError('3');
