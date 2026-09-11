// Study 37 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are at the edge, because that is where this study lives. One turns
// a domain answer into a number the web agrees on, one refuses a request before
// anything looks at it, and one is a table — with a trap in it that only a
// router has.

import 'package:ch37_expenses/expenses.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// 1. The same verdict, as an HTTP status.
///
///    Study 36's challenge 2 wrote this function for a shell and said this
///    study would write it again for a wire. Same [Verdict], same question,
///    different vocabulary — which is the argument for a verdict being a value
///    rather than a message.
///
///    `200` when nothing stood in the way: a `null` verdict, a [Within], or a
///    [Breach] the person acknowledged. `409` for a [Breach] they did not,
///    because the request was read, understood, and refused by the state of
///    that month's budget.
///
///    `Verdict.refuses` takes an [Expense], because that is where study 32 put
///    the acknowledgement. This takes the flag, because the caller here has one
///    and no expense — which is worth noticing rather than working around.
int statusFor(Verdict? verdict, {required bool acknowledged}) =>
    throw UnimplementedError('1');

/// 2. A middleware that refuses a request before anything reads it.
///
///    A `POST` carrying something that is not JSON is not this program's to
///    parse, so it never gets as far as a handler. Answer `415` — *unsupported
///    media type* — and let everything else through.
///
///    * A `GET` goes through whatever it says, because it has no body.
///    * A `POST` whose `content-type` starts with `application/json` goes
///      through.
///    * Any other `POST` is `415`.
///
///    [createMiddleware]'s `requestHandler` answers `null` to mean *carry on*,
///    which is what makes a guard read as a guard. Headers arrive lower-cased,
///    so `request.headers['content-type']` is the one to ask.
Middleware onlyJson() => throw UnimplementedError('2');

/// 3. Two routes under `/budgets/`, one of which is a trap.
///
///    * `GET /budgets/total` answers `200` and `{"limit": <pence>}`, where the
///      number is every limit's amount added up.
///    * `GET /budgets/<category>` answers `200` and
///      `{"category": <name>, "limit": <pence>}` for a category with a limit
///      on it, and `404` for one without.
///
///    Both bodies are `jsonEncode`d, with no trailing newline, and the status
///    is all the tests check on the 404.
///
///    **A [Router] matches in the order the routes were added**, and `<…>`
///    matches any one segment. Write these two in the wrong order and one of
///    them can never be reached — which is the whole of the exercise, and is
///    the thing a chain of `if`s over `request.url.path` would have made
///    obvious.
Router budgetRoutes(Tracker tracker) => throw UnimplementedError('3');
