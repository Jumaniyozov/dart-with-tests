import 'package:args/args.dart';

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
/// You asked for something the program will not do.
const refused = 1;

/// The program could not tell what you asked for.
const misuse = 2;
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

// #region parser
/// Every option and every command this program has, declared once.
///
/// `addCommand` gives each command word its own parser, so `--anyway` belongs
/// to `add` and nowhere else. Study 32 had to strip that flag out of the
/// arguments by hand before the patterns could read them, because
/// `['add', …, ...final note]` would otherwise have swallowed it into
/// somebody's note. A parser knows the difference between a flag and a word,
/// and that is the whole of what the hand-rolled version was for.
final _parser = ArgParser()
  ..addFlag('help', abbr: 'h', negatable: false, help: 'print this and stop')
  ..addOption(
    'file',
    abbr: 'f',
    valueHelp: 'path',
    defaultsTo: _defaultPath,
    help: 'where the tracker keeps what it is told',
  )
  ..addCommand(
    'add',
    ArgParser()..addFlag(
      'anyway',
      negatable: false,
      help: 'record it even if it breaks a budget',
    ),
  )
  ..addCommand('list', ArgParser())
  ..addCommand('budget', ArgParser());

/// The file the tracker uses when nobody says otherwise.
const _defaultPath = 'expenses.txt';
// #endregion parser

// #region file
/// Where the tracker should keep what it is told, according to the arguments.
///
/// Study 28 put this path in a `const` in `bin/`, called it the only thing that
/// knew where the tracker lives, and promised this study would let you say.
///
/// It answers a `String`. No `ArgResults` crosses this boundary, so
/// `package:args` is something this library *uses* rather than something it
/// makes its callers use — study 34 is about that difference.
///
/// Total, because it runs before anything else does. A bad argument is [run]'s
/// to report, and reporting it twice would be worse than not reporting it here.
String fileFrom(List<String> args) {
  try {
    return _parser.parse(args).option('file') ?? _defaultPath;
  } on ArgParserException {
    return _defaultPath;
  }
}
// #endregion file

// #region usage
/// What to print when nobody said anything useful.
///
/// Study 24's `usage` was a `const` string written out beside the parser, which
/// is a claim nothing checks: add a flag, forget the line, and the help is
/// wrong until somebody reads both. Half of this is now generated from the
/// parser and cannot disagree with it.
///
/// Only half. `ArgParser` models **options**; the words after a command word
/// are a plain list it has no opinion about, so the shape of an `add` line is
/// still written by hand and can still drift. Knowing which half a dependency
/// took over is the point.
String get usage =>
    '''
usage: expenses [options] <command> [arguments]

commands:
$_grammar
  help                             print this

options:
${_parser.usage}

  add also takes:
${_indented(_parser.commands['add']!.usage)}''';

/// `ArgParser.usage` is a plain `String`, so lining it up under a heading is
/// this program's business and not the parser's.
String _indented(String usage) =>
    usage.split('\n').map((line) => '  $line').join('\n');

/// The positional grammar, which [ArgParser] does not model.
const _grammar = '''
  add <amount> <category> <note>   record what you spent
  list [YYYY-MM]                   show what has been recorded, all of it
                                   or one calendar month of it
  budget [<category> <amount>]     show this month against its limits,
                                   or set the limit on a category''';
// #endregion usage

// #region run
/// One run of the program, start to finish.
///
/// Study 24 switched over the raw `List<String>`; this switches over what the
/// parser made of it. The shape is the same — study 14's patterns, over a
/// record of the command word and the words after it — and the flag has
/// stopped being a word that has to be fished out first.
///
/// The `catch` is licensed rather than convenient. `ArgParserException` is a
/// `FormatException`, measured, so it is an `Exception` and not an `Error`:
/// someone mistyping an option is the ordinary use of a terminal, which is
/// study 26's rule for which of the two a failure should be.
Future<Outcome> run(List<String> args, Store store, Day today) async {
  final ArgResults parsed;
  try {
    parsed = _parser.parse(args);
  } on ArgParserException catch (error) {
    return (code: misuse, out: '', err: error.message);
  }

  final command = parsed.command;
  if (parsed.flag('help') || (command == null && parsed.rest.isEmpty)) {
    return (code: okay, out: usage, err: '');
  }
  if (command == null) {
    final [first, ...] = parsed.rest;
    return first == 'help'
        ? (code: okay, out: usage, err: '')
        : (code: misuse, out: '', err: "no command named '$first'");
  }

  return switch ((command.name, command.rest)) {
    ('add', [final amount, final category, ...final note])
        when note.isNotEmpty =>
      await _add(
        store,
        today,
        amount,
        category,
        note.join(' '),
        acknowledged: command.flag('anyway'),
      ),
    ('add', _) => (
      code: misuse,
      out: '',
      err: 'usage: expenses add <amount> <category> <note>',
    ),
    ('list', []) => await _list(store, null),
    ('list', [final month]) => await _listMonth(store, month),
    ('list', _) => (
      code: misuse,
      out: '',
      err: 'usage: expenses list [YYYY-MM]',
    ),
    ('budget', []) => await _showBudgets(store, today),
    ('budget', [final category, final amount]) => await _setLimit(
      store,
      category,
      amount,
    ),
    ('budget', _) => (
      code: misuse,
      out: '',
      err: 'usage: expenses budget [<category> <amount>]',
    ),
    _ => (code: misuse, out: '', err: "no command named '${command.name}'"),
  };
}

// #endregion run

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

// #region listing
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
// #endregion listing
