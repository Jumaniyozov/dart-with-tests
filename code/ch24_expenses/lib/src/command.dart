import 'money.dart';

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

  add <amount> <note>   record what you spent
  help                  print this''';
// #endregion usage

// #region parse
/// Pence from what a person typed at a terminal. `12.50` is 1250.
///
/// Every character is checked before anything is parsed, because
/// `int.tryParse` is more generous than a person expects: it reads `0x10` as
/// 16 and accepts a leading sign anywhere it is handed one. A parser that
/// takes `5.-1` and answers 499 is worse than one that refuses, because
/// nothing downstream can tell that it guessed.
///
/// A leading `-` is read, because `-5.00` is a perfectly readable amount. It
/// is [Money] that refuses it, and 24.2 depends on those being two different
/// failures.
///
/// Still naive in one way, and study 26 rewrites it for that: `null` says no
/// and cannot say which part was wrong.
int? penceFrom(String text) {
  final negative = text.startsWith('-');
  final sign = negative ? -1 : 1;
  switch ((negative ? text.substring(1) : text).split('.')) {
    case [final pounds] when _isDigits(pounds):
      return sign * int.parse(pounds) * 100;
    case [final pounds, final pence]
        when _isDigits(pounds) && _isDigits(pence) && pence.length == 2:
      return sign * (int.parse(pounds) * 100 + int.parse(pence));
    default:
      return null;
  }
}

/// Digits and nothing else — not a sign, not a space, not `0x`.
bool _isDigits(String text) =>
    text.isNotEmpty &&
    text.codeUnits.every((unit) => unit >= 0x30 && unit <= 0x39);
// #endregion parse

// #region run
/// One run of the program, start to finish.
///
/// Study 14's switch over a list pattern, reading the arguments the shell
/// handed us. The guard on the first `add` case is what separates "you meant
/// add and got it right" from "you meant add and left something out".
Outcome run(List<String> args) => switch (args) {
  [] || ['help'] => (code: okay, out: usage, err: ''),
  ['add', final amount, ...final note] when note.isNotEmpty => _add(
    amount,
    note.join(' '),
  ),
  ['add', ...] => (
    code: misuse,
    out: '',
    err: 'usage: expenses add <amount> <note>',
  ),
  [final unknown, ...] => (
    code: misuse,
    out: '',
    err: "no command named '$unknown'",
  ),
};

Outcome _add(String amount, String note) {
  final pence = penceFrom(amount);
  if (pence == null) {
    return (code: misuse, out: '', err: "'$amount' is not an amount");
  }
  try {
    return (
      code: okay,
      out: '${Money.fromPence(pence).asText}  $note',
      err: '',
    );
  } on ArgumentError catch (error) {
    return (code: refused, out: '', err: '${error.message}');
  }
}
// #endregion run
