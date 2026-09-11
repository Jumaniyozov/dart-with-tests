import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'budget.dart';
import 'category.dart';
import 'day.dart';
import 'expense.dart';
import 'money.dart';
import 'period.dart';
import 'tracker.dart';

// #region api
/// The whole HTTP edge: what happens to every request, in the order it happens.
///
/// A [Pipeline] is read outside-in. The first middleware added is the outermost
/// one, so [faults] wraps [onlyWithKey] wraps the routes — which is the order
/// this program needs and not a detail. Put the key check outside and a bug in
/// it would answer a stranger with a stack trace.
///
/// **[report] is the seam, and it is study 27's argument again.** Something has
/// to be told when this program is wrong, and `stderr` is the world. So it is
/// handed in rather than fetched: `lib/` still has exactly one file that has
/// heard of `dart:io`, the test can assert what was reported without a process
/// to capture, and `bin/serve.dart` is where the decision to write to a
/// terminal is made — by the file that already reads the environment and opens
/// the port.
Handler expensesApi(
  Tracker tracker, {
  required String key,
  required void Function(Object error, StackTrace stack) report,
}) => const Pipeline()
    .addMiddleware(faults(report))
    .addMiddleware(onlyWithKey(key))
    // `.call` and not the bare object: a [Router] is a class with a `call`
    // method rather than a function, and `implicit_call_tearoffs` asks for
    // the difference to be written down.
    .addHandler(expensesRoutes(tracker).call);
// #endregion api

// #region faults
/// The last line of defence, and a line every route is written to never reach.
///
/// **It is not here to stop the error text reaching the caller, because that
/// was never happening.** Measured: throw out of a handler with nothing
/// catching it and `shelf_io` answers `500` with the body `Internal Server
/// Error` and puts the message in its own log. The outline predicted this
/// middleware would exist to plug a leak; there was no leak.
///
/// What it is here for is two things that *are* wrong with that default. The
/// body is plain text, and it is then the only answer this server gives that is
/// not a JSON document with a `problem` in it — a caller would need a second
/// parser for the one case it is least able to handle. And `shelf`'s log line
/// carries a timestamp, which ADR 0005 forbids this book's server outright: a
/// transcript with a clock reading in it cannot be re-run, and re-running them
/// is the only thing that stops one quietly becoming false.
///
/// So the shape is this program's and the report is handed to [report], which
/// is where `bin/serve.dart` decides that a fault belongs on `stderr`. Both
/// halves are asserted — an error that reaches nobody is the more common of the
/// two mistakes, and a fixed sentence that is never sent is not a guard.
///
/// It catches everything, which is a guideline this study declines on purpose
/// and says so on the page. By the time something has been thrown out of a
/// route, the question of which kind it was has already been answered wrongly:
/// every failure a caller can cause is checked for and returned, in this file,
/// before anything is built.
Middleware faults(void Function(Object error, StackTrace stack) report) =>
    createMiddleware(
      errorHandler: (error, stack) {
        report(error, stack);
        return _problem(500, 'this program is wrong');
      },
    );
// #endregion faults

// #region key
/// One shared key, and it authenticates a **caller** rather than a person.
///
/// `CONTEXT.md` says this program has no Account: one person, one file, and
/// nothing anywhere in it that models who somebody is. So there is no user to
/// authenticate and this does not pretend there is. It answers one question —
/// *is whoever sent this allowed to talk to this server at all?* — and `401`
/// is the status that asks it, because `403` means *I know who you are and the
/// answer is still no*, which needs a who.
///
/// `null` from a [createMiddleware] request handler means *carry on to the
/// inner handler*, which is what makes this readable as a guard rather than as
/// a branch around the whole program.
Middleware onlyWithKey(String key) => createMiddleware(
  requestHandler: (request) => request.headers['authorization'] == 'Bearer $key'
      ? null
      : _problem(401, 'who is asking?'),
);
// #endregion key

// #region routes
/// Every path this program answers, as a table.
///
/// Study 35 answered one sentence at every path and study 36 answered the
/// expenses at every path, because neither had a way to tell paths apart that
/// was not a chain of `if`s over `request.url`. A [Router] is that chain,
/// written as data: a verb, a pattern, and what to run.
///
/// Two things it hands over for nothing. **The 404 for a path that is not
/// here** — the hand-rolled server in study 35 wrote that branch itself, and
/// this is the line that argument was about. And `<category>`, which matches
/// one path segment and passes it to the handler as a `String` argument, so a
/// route with a hole in it is still one entry in the table.
///
/// The verb is part of the key. `POST /budgets` matches no row here, and what
/// comes back is the same 404 as `/nowhere` — measured, because a router that
/// answered `405 Method Not Allowed` would be a different claim.
///
/// **The 404 it gives away is its own, and one named argument makes it this
/// program's.** Without [notFoundHandler] a path the table has not got answers
/// `Route not found` as plain text, which is a different shape from every other
/// refusal here and would make a caller parse two things.
Router expensesRoutes(Tracker tracker) =>
    Router(notFoundHandler: (request) => _problem(404, 'no such path'))
      ..get('/expenses', (Request request) => _list(tracker, request))
      ..post('/expenses', (Request request) => _record(tracker, request))
      ..get('/budgets', (Request request) => _budgets(tracker))
      ..get(
        '/budgets/<category>',
        (Request request, String category) => _budget(tracker, category),
      );

/// One document, one status, and the header that says which of the two the
/// bytes are.
///
/// The trailing newline is for the terminal the reader is holding. `curl`
/// prints a body exactly as it arrives, so a document without one leaves the
/// next prompt halfway along the line.
Response _json(int status, Object? document) => Response(
  status,
  body: '${jsonEncode(document)}\n',
  headers: const {'content-type': 'application/json'},
);

/// Every answer that is not the thing the caller asked for, in one shape.
///
/// A caller parsing this should not need a second shape to find out what went
/// wrong, so `problem` is on every one of them and the rest of the document is
/// whatever that particular refusal knows.
Response _problem(int status, String problem) =>
    _json(status, {'problem': problem});
// #endregion routes

// #region bound
/// What has been recorded, optionally one month of it, optionally less of it.
///
/// **`limit` was a lie until study 39 and is not one now.** Study 37 shipped
/// this route slicing the answer *after* [Tracker.expenses] had found every
/// expense there was, so the document got smaller and the work did not — a
/// counting double measured a thousandth of the reply for exactly the same
/// reads. Both narrowings are arguments now, and they go all the way down to
/// the `WHERE` and the `LIMIT`. The route did not get cleverer; it stopped
/// answering a question it had not asked.
///
/// The two failures are different and the statuses are too. A month nobody can
/// read is the caller garbling the request — `400`, study 24's `misuse` with a
/// number the whole web agrees on. A month with nothing in it is a perfectly
/// good answer and is `200` with an empty list.
Future<Response> _list(Tracker tracker, Request request) async {
  final asked = request.url.queryParameters;

  final month = asked['month'];
  final period = month == null ? null : Period.parse(month);
  if (month != null && period == null) {
    return _problem(400, '"$month" is not a month; write it as 2026-09');
  }

  final wanted = asked['limit'];
  final bound = wanted == null ? null : _count(wanted);
  if (wanted != null && bound == null) {
    return _problem(400, '"$wanted" is not a number of expenses');
  }

  final expenses = await tracker.expenses(period: period, count: bound);
  return _json(200, [for (final expense in expenses) expense.toJson()]);
}

/// A count somebody typed into a query string, or `null` for anything else.
///
/// `int.tryParse` is more generous than the sentence you would write about it:
/// it reads `0x10` as 16 and takes a sign wherever it is handed one. Studies 20
/// and 24 both shipped a bug that trusted it, and this is the same check that
/// fixed them, at an edge where the caller is a stranger rather than somebody
/// mistyping at their own keyboard.
/// The regex first and [int.tryParse] second, so the parse is only ever handed
/// text it has no room to be generous about — and still `tryParse`, because a
/// run of digits longer than an `int` is exactly the input a stranger sends.
int? _count(String text) =>
    RegExp(r'^[0-9]+$').hasMatch(text) ? int.tryParse(text) : null;
// #endregion bound

// #region reads
/// Every budget in force this month.
Future<Response> _budgets(Tracker tracker) async =>
    _json(200, [for (final budget in await tracker.budgets()) _asJson(budget)]);

/// One category's budget, or the other kind of 404.
///
/// The router's 404 means *this program has no such path*. This one means
/// *this path is real and there is no such thing behind it*, which is the
/// answer to a question the command line could not be asked: `budget` with no
/// arguments printed everything, and there was no way to ask about one
/// category and be told no.
Future<Response> _budget(Tracker tracker, String category) async {
  // **The router hands over the segment exactly as it arrived**, so `%20` is
  // three characters here and not a space. Decoding is this program's job, and
  // it has to happen: `food and drink` is a category the command line can make,
  // and a caller asking about it has no other way to spell it.
  //
  // `Uri.decodeComponent` throws an `ArgumentError` for a malformed escape —
  // but not for anything that can reach here, because `Uri.parse` has already
  // turned a stray `%` into `%25`. Measured, and asserted, because *it cannot
  // throw* is exactly the kind of claim that is true two layers away.
  final asked = Uri.decodeComponent(category);

  // Asked before building, for 26.3's reason: `Category` throws for a name
  // that is blank once it is trimmed, and an `Error` is not something an edge
  // catches. `/budgets/%20` is how a stranger spells that.
  if (asked.trim().isEmpty) {
    return _problem(400, 'a category needs a name');
  }

  final wanted = Category(asked);
  for (final budget in await tracker.budgets()) {
    if (budget.category == wanted) return _json(200, _asJson(budget));
  }
  return _problem(404, 'no budget on $wanted');
}

/// A budget as four numbers and a name.
///
/// `remaining` is `null` when the limit has already been passed, and that null
/// is the domain's, unchanged: [Money] has no value meaning *£12.50
/// overspent*, so [Budget.remaining] answers `null` rather than inventing one.
/// The wire is the first place that decision is visible to somebody who never
/// reads this code.
///
/// Every amount is **pence**, which study 19 argued for and JSON insists on
/// twice over: `jsonDecode('20.10')` hands back a `double`, and study 19 is
/// about what a `double` cannot hold.
Map<String, Object?> _asJson(Budget budget) => {
  'category': budget.category.name,
  'limit': budget.limit.amount.pence,
  'spent': budget.spent.pence,
  'remaining': budget.remaining?.pence,
};
// #endregion reads

// #region writes
/// Record an expense, or say why not.
///
/// **The refusal answers in money, and study 36 said this was owed.** The
/// command line had to go back to the store for the limit before it could write
/// *budgeted at £20.00*; a [Breach] now carries the [Limit] it broke, so this
/// hands over the category, the limit and the overspend as three numbers and a
/// name, and whoever asked can write their own sentence in their own language.
///
/// `409` rather than `400`: nothing was wrong with the request. It was read,
/// understood, and refused by the state of this month's food budget, which is
/// what a conflict is. `400` would have told the caller to fix their JSON.
///
/// **Two callers can both get past that check.** `Tracker.record` reads the
/// store, decides, and then writes, and `FileStore` touches a disk in between —
/// so two requests arriving together can both be told there is room and both be
/// recorded, leaving a month over its budget that nothing ever refused. It is
/// declared rather than hidden: study 40 is where the suspension between the
/// decision and the write is measured and closed.
Future<Response> _record(Tracker tracker, Request request) async {
  final expense = _expenseIn(await request.readAsString(), tracker.today());
  if (expense == null) {
    return _problem(400, 'an expense is a pence, a category and a note');
  }

  final verdict = await tracker.record(expense);
  if (verdict.refuses(expense)) {
    final breach = verdict! as Breach;
    return _json(409, {
      'problem': 'over budget',
      'category': breach.limit.category.name,
      'limit': breach.limit.amount.pence,
      'over': breach.over.pence,
    });
  }
  return _json(200, expense.toJson());
}

/// One request body back into an expense, or `null` when it is not one.
///
/// The map pattern is study 29's, doing the same job for a stranger that it did
/// for a file somebody had edited by hand: it is the cast that checks, so a
/// `"pence": "450"` falls through to `null` instead of throwing a `TypeError`
/// out of this handler and into [faults].
///
/// The `when` asks what [Money.fromPence] and [Category] would refuse, before
/// either is built — 26.3's shape, and the reason `400` is a returned value
/// here rather than a caught `ArgumentError`.
///
/// No `day`. The day an expense was filed on is this program's to know, not the
/// caller's, and it is whatever [Tracker.today] answers **when this runs** —
/// which is study 38's whole second half, and is one pair of parentheses wide.
Expense? _expenseIn(String body, Day today) {
  final json = _decoded(body);
  if (json
      case {
        'pence': final int pence,
        'category': final String category,
        'note': final String note,
      }
      when pence >= 0 && category.trim().isNotEmpty) {
    return Expense(
      Money.fromPence(pence),
      Category(category),
      today,
      note,
      // Read off the matched map rather than bound by the pattern, for study
      // 29's reason: a map pattern has no way to say *this key is optional*.
      acknowledged: (json as Map<String, Object?>)['acknowledged'] == true,
    );
  }
  return null;
}

/// A body's worth of JSON, or `null` for a body that is not JSON at all.
Object? _decoded(String body) {
  try {
    return jsonDecode(body);
  } on FormatException {
    return null;
  }
}
// #endregion writes
