// Study 24 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three extend the program's front door. You are writing [runMore], which
// answers the commands `run` does not, and the rules are the same ones 24.2
// drew: the answer goes on `out`, the complaint goes on `err`, never both, and
// the code says which happened.

import 'package:ch24_expenses/expenses.dart';

/// 1. `show <amount>` prints the amount and nothing else.
///
///    `runMore(['show', '12.50'])` has `out` of `£12.50` and a code of [okay].
///    An amount that cannot be read is [misuse], with `'abc' is not an amount`
///    on `err` and nothing on `out`.
///
/// 2. `total <amount> <amount> ...` adds them up.
///
///    `runMore(['total', '1.00', '2.50'])` has `out` of `£3.50`. One amount is
///    fine. No amounts at all is [misuse]. If any single amount cannot be read,
///    the whole command is [misuse] and nothing is printed on `out` — a total
///    that quietly skipped one number would be worse than no total.
///
/// 3. The help flags.
///
///    `--help` and `-h` do what `help` does: [usage] on `out`, code [okay].
///    Anything else beginning with `-` is [misuse], and says
///    `no flag named '-x'` — a flag is a different mistake from a misspelled
///    command, and telling them apart is the first thing study 33's
///    `package:args` will do for you.
Outcome runMore(List<String> args) => throw UnimplementedError('challenges');
