import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'expense.dart';
import 'tracker.dart';

// #region handler
/// What this program answers when somebody calls it over HTTP.
///
/// **It takes a [Tracker] now, and that one word is the study.** Study 35's
/// version took a `Store` and could say only how many rows were in it, because
/// every use case the tracker had was private to `command.dart` and the one
/// public way in answered an `Outcome` — an exit code and a line of English
/// written for somebody standing at a terminal. Neither is something a second
/// caller can use. `Tracker` is what the private functions became once a second
/// edge needed them, and the diff that made it is the evidence: their parameters
/// did not change.
///
/// Still one sentence at every path. Routing is study 37, and so is deciding
/// what an HTTP status means — this answers `200` and a document because it is
/// the only thing it can currently be asked.
///
/// `toJson` is study 29's, written for a file. Nothing here invented a second
/// representation, which is worth noticing: a JSON document was already the
/// thing this program stored, so the wire asked for nothing new.
Handler expensesHandler(Tracker tracker) => (Request request) async {
  final expenses = await tracker.expenses();
  return Response.ok(
    jsonEncode([for (final expense in expenses) expense.toJson()]),
    headers: {'content-type': 'application/json'},
  );
};
// #endregion handler
