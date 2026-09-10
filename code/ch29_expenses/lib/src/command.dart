import 'category.dart';
import 'day.dart';
import 'expense.dart';
import 'money.dart';
import 'reading.dart';
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
  list                             show what has been recorded
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
/// callers await. Study 21 said it; this is the first time this program has
/// paid it.
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
      ['list'] => await _list(store),
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

Future<Outcome> _list(Store store) async {
  final recorded = await store.all;
  if (recorded.isEmpty) {
    return (code: okay, out: 'nothing recorded yet', err: '');
  }
  final lines = [
    for (final expense in recorded) expense.asText,
    '',
    for (final entry in (await store.totals).entries)
      '${entry.key}: ${entry.value.asText}',
  ];
  return (code: okay, out: lines.join('\n'), err: '');
}
// #endregion run
