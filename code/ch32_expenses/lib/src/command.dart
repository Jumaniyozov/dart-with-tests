import 'budget.dart';
import 'category.dart';
import 'day.dart';
import 'expense.dart';
import 'money.dart';
import 'period.dart';
import 'reading.dart';
import 'report.dart';
import 'store.dart';

// #region codes
/// What the program tells the shell when it stops.
///
/// The shell cannot read English. It reads this number, and every script that
/// ever calls this program branches on it.
const okay = 0; // it worked
const refused = 1; // you asked for something the program will not do
const misuse = 2; // the program could not tell what you asked for
// #endregion codes

// #region outcome
/// Everything one run of the program came to.
///
/// A record and not a class, by study 13's rule: three values travelling
/// together, with no invariant to keep and no identity of their own.
///
/// Returning this instead of printing is what makes the program testable. This
/// file has never imported `dart:io` and still has not — study 28 gave the
/// package one file that does, and it is behind [Store] where a fake replaces
/// it. A test can still run every command without a terminal to run it in.
typedef Outcome = ({int code, String out, String err});
// #endregion outcome

// #region usage
/// What to print when nobody said anything useful.
const usage = '''
usage: expenses <command>

  add <amount> <category> <note>   record what you spent
     [--anyway]                    record it even if it breaks a budget
  list [YYYY-MM]                   show what has been recorded, all of it
                                   or one calendar month of it
  budget                           show this month against its limits
  budget <category> <amount>       set the limit on a category
  help                             print this''';
// #endregion usage

// #region run
/// One run of the program, start to finish.
///
/// A `Future<Outcome>` now, because [Store] is one. Nothing in here decided to
/// be asynchronous — the interface it was already written against changed what
/// it promises, and `run` had no choice but to say so too.
///
/// That is worth naming rather than resenting. `async` travels up the call
/// stack and cannot be hidden: a function that awaits is a function whose
/// callers await. Study 28 is where this program first paid that; study 21
/// taught the keyword and made no claim about how far it spreads.
Future<Outcome> run(List<String> args, Store store, Day today) async {
  final (:acknowledged, :rest) = _flagged(args);

  return switch (rest) {
    [] || ['help'] => (code: okay, out: usage, err: ''),
    ['add', final amount, final category, ...final note] when note.isNotEmpty =>
      await _add(
        store,
        today,
        amount,
        category,
        note.join(' '),
        acknowledged: acknowledged,
      ),
    ['add', ...] => (
      code: misuse,
      out: '',
      err: 'usage: expenses add <amount> <category> <note>',
    ),
    ['list'] => await _list(store, null),
    ['list', final month] => await _listMonth(store, month),
    ['list', ...] => (
      code: misuse,
      out: '',
      err: 'usage: expenses list [YYYY-MM]',
    ),
    ['budget'] => await _showBudgets(store, today),
    ['budget', final category, final amount] => await _setLimit(
      store,
      category,
      amount,
    ),
    ['budget', ...] => (
      code: misuse,
      out: '',
      err: 'usage: expenses budget [<category> <amount>]',
    ),
    [final unknown, ...] => (
      code: misuse,
      out: '',
      err: "no command named '$unknown'",
    ),
  };
}

// #endregion run

// #region flag
/// The one flag this program has.
const _anyway = '--anyway';

/// The arguments with the flag taken out, and whether it was in there.
///
/// This has to happen *before* the patterns in [run] see the arguments,
/// because `['add', …, ...final note]` would otherwise swallow `--anyway` and
/// put it in somebody's note. A real argument parser knows the difference
/// between a flag and a word. This is what not having one costs, and it is the
/// last of the three debts ADR 0003 took on: study 33 deletes it.
({bool acknowledged, List<String> rest}) _flagged(List<String> args) => (
  acknowledged: args.contains(_anyway),
  rest: [
    for (final argument in args)
      if (argument != _anyway) argument,
  ],
);
// #endregion flag

Future<Outcome> _add(
  Store store,
  Day today,
  String amount,
  String category,
  String note, {
  required bool acknowledged,
}) async => switch (readMoney(amount)) {
  Unreadable(:final reason) => (code: misuse, out: '', err: reason),
  Refused(:final reason) => (code: refused, out: '', err: reason),
  Understood(:final money) => await _record(
    store,
    today,
    money,
    category,
    note,
    acknowledged: acknowledged,
  ),
};

// #region record
Future<Outcome> _record(
  Store store,
  Day today,
  Money money,
  String category,
  String note, {
  required bool acknowledged,
}) async {
  // Asked before building, not caught afterwards. `Category` throws an
  // `ArgumentError` for a blank name, and 26.5 says why catching one would be
  // the wrong shape even though it would work.
  if (category.trim().isEmpty) {
    return (code: misuse, out: '', err: 'a category needs a name');
  }
  final expense = Expense(
    money,
    Category(category),
    today,
    note,
    acknowledged: acknowledged,
  );

  // The rule is asked *before* the expense is kept, and the thing asked is the
  // budget rather than the store. `Store.record` is still what it was in study
  // 25: it writes down what it is given and has no opinion. Putting the check
  // behind it would hide a domain rule inside the one interface study 27 built
  // to be swappable, and every fake would have to grow the rule or lie about
  // it.
  final limit = limitOn(expense.category, await store.limits);
  if (limit != null) {
    final budget = Budget.of(limit, Period.of(today), await store.all);
    switch (budget.on(expense)) {
      // A breach nobody has acknowledged is refused. This is study 26's rule
      // spent on a *business* failure rather than a typing one: it is an
      // expected outcome of using the program correctly, so it comes back as a
      // value with an exit code and not as an exception.
      case Breach(:final over) when !acknowledged:
        return (
          code: refused,
          out: '',
          err:
              '${expense.category} is budgeted at ${limit.amount.asText} and '
              'this would put it ${over.asText} over. '
              'Record it anyway with --anyway.',
        );
      case Breach() || Within():
        break;
    }
  }

  await store.record(expense);
  return (code: okay, out: expense.asText, err: '');
}
// #endregion record

// #region budgeting
Future<Outcome> _setLimit(Store store, String category, String amount) async {
  if (category.trim().isEmpty) {
    return (code: misuse, out: '', err: 'a category needs a name');
  }
  return switch (readMoney(amount)) {
    Unreadable(:final reason) => (code: misuse, out: '', err: reason),
    Refused(:final reason) => (code: refused, out: '', err: reason),
    Understood(:final money) when money == Money.zero => (
      code: refused,
      out: '',
      err: 'a budget of nothing is not a budget',
    ),
    Understood(:final money) => await _kept(store, category, money),
  };
}

Future<Outcome> _kept(Store store, String category, Money money) async {
  final limit = Limit(Category(category), money);
  await store.setLimit(limit);
  return (code: okay, out: '$limit', err: '');
}

Future<Outcome> _showBudgets(Store store, Day today) async {
  final limits = await store.limits;
  if (limits.isEmpty) {
    return (code: okay, out: 'no budgets set', err: '');
  }
  final period = Period.of(today);
  final budgets = budgetsFor(limits, period, await store.all);
  final lines = [
    '${period.first} to ${period.last}',
    '',
    for (final budget in budgets) budget.asText,
  ];
  return (code: okay, out: lines.join('\n'), err: '');
}
// #endregion budgeting

/// `list` with a month after it.
///
/// The parse is separated from the listing because the two failures are
/// different: a month nobody can read is misuse, and a month with nothing in it
/// is a perfectly good answer.
Future<Outcome> _listMonth(Store store, String month) async {
  final period = Period.parse(month);
  if (period == null) {
    return (
      code: misuse,
      out: '',
      err: '"$month" is not a month; write it as 2026-09',
    );
  }
  return _list(store, period);
}

Future<Outcome> _list(Store store, Period? period) async {
  final recorded = [
    for (final expense in await store.all)
      if (period == null || period.contains(expense.day)) expense,
  ];
  if (recorded.isEmpty) {
    return (
      code: okay,
      out: period == null
          ? 'nothing recorded yet'
          : 'nothing recorded in ${period.asText}',
      err: '',
    );
  }
  final lines = [
    // What the program actually covered, rather than what was asked for. They
    // are the same here, and saying so is how a reader finds out that February
    // stops on the 28th without having to trust that it does.
    if (period != null) ...['${period.first} to ${period.last}', ''],
    // Everything below this line used to be written out here. A report knows
    // how to group itself, order itself and add itself up, and `run` is not a
    // better place to keep any of that.
    Report.of(recorded).asText,
  ];
  return (code: okay, out: lines.join('\n'), err: '');
}
