import 'category.dart';
import 'day.dart';
import 'expense.dart';
import 'money.dart';
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
/// Returning this instead of printing is what makes the program testable. No
/// `dart:io` appears anywhere under `lib/`, so a test can run every command
/// without a terminal to run it in.
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

// #region parse
/// Pence from what a person typed at a terminal. `12.50` is 1250.
///
/// Naive on purpose, and study 26 rewrites it. It answers `null` for anything
/// it cannot read, which is study 9's `tryParse` answer — and study 26 asks
/// whether `null` is really what a caller needs to be told here.
int? penceFrom(String text) {
  switch (text.split('.')) {
    case [final pounds]:
      final whole = int.tryParse(pounds);
      return whole == null ? null : whole * 100;
    case [final pounds, final pence] when pence.length == 2:
      final whole = int.tryParse(pounds);
      final part = int.tryParse(pence);
      return whole == null || part == null ? null : whole * 100 + part;
    default:
      return null;
  }
}
// #endregion parse

// #region run
/// One run of the program, start to finish.
///
/// The [Store] arrives as a parameter rather than being made in here. That is
/// what lets a test hand in a store with expenses already in it, and it is the
/// first shape of an idea study 27 takes much further.
Outcome run(List<String> args, Store store) => switch (args) {
  [] || ['help'] => (code: okay, out: usage, err: ''),
  ['add', final amount, final category, ...final note] when note.isNotEmpty =>
    _add(store, amount, category, note.join(' ')),
  ['add', ...] => (
    code: misuse,
    out: '',
    err: 'usage: expenses add <amount> <category> <note>',
  ),
  ['list'] => _list(store),
  [final unknown, ...] => (
    code: misuse,
    out: '',
    err: "no command named '$unknown'",
  ),
};

Outcome _add(Store store, String amount, String category, String note) {
  final pence = penceFrom(amount);
  if (pence == null) {
    return (code: misuse, out: '', err: "'$amount' is not an amount");
  }
  try {
    final expense = Expense(
      Money.fromPence(pence),
      Category(category),
      // The clock, read in the middle of the work. This one line is why
      // `_add` cannot be tested for the day it records. Study 27 fixes it.
      Day.on(DateTime.now()),
      note,
    );
    store.record(expense);
    return (code: okay, out: expense.asText, err: '');
  } on ArgumentError catch (error) {
    return (code: refused, out: '', err: '${error.message}');
  }
}

Outcome _list(Store store) {
  if (store.all.isEmpty) {
    return (code: okay, out: 'nothing recorded yet', err: '');
  }
  final lines = [
    for (final expense in store.all) expense.asText,
    '',
    for (final entry in store.totals.entries)
      '${entry.key}: ${entry.value.asText}',
  ];
  return (code: okay, out: lines.join('\n'), err: '');
}
// #endregion run
