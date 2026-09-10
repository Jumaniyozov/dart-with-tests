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
  list [YYYY-MM]                   show what has been recorded, all of it
                                   or one calendar month of it
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
Future<Outcome> run(List<String> args, Store store, Day today) async =>
    switch (args) {
      [] || ['help'] => (code: okay, out: usage, err: ''),
      ['add', final amount, final category, ...final note]
          when note.isNotEmpty =>
        await _add(store, today, amount, category, note.join(' ')),
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
      [final unknown, ...] => (
        code: misuse,
        out: '',
        err: "no command named '$unknown'",
      ),
    };

Future<Outcome> _add(
  Store store,
  Day today,
  String amount,
  String category,
  String note,
) async => switch (readMoney(amount)) {
  Unreadable(:final reason) => (code: misuse, out: '', err: reason),
  Refused(:final reason) => (code: refused, out: '', err: reason),
  Understood(:final money) => await _record(
    store,
    today,
    money,
    category,
    note,
  ),
};

Future<Outcome> _record(
  Store store,
  Day today,
  Money money,
  String category,
  String note,
) async {
  // Asked before building, not caught afterwards. `Category` throws an
  // `ArgumentError` for a blank name, and 26.5 says why catching one would be
  // the wrong shape even though it would work.
  if (category.trim().isEmpty) {
    return (code: misuse, out: '', err: 'a category needs a name');
  }
  final expense = Expense(money, Category(category), today, note);
  await store.record(expense);
  return (code: okay, out: expense.asText, err: '');
}

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
// #endregion run
