import 'package:shelf/shelf.dart';

import 'store.dart';

// #region handler
/// What this program answers when somebody calls it over HTTP.
///
/// A `Handler` is `FutureOr<Response> Function(Request)` — a type this package
/// does not declare and does not have to. Study 27 said a seam is a parameter
/// and only one of them wants an interface; this is the case where even the
/// parameter was already there. The store goes in, a function comes out, and a
/// test calls the function.
///
/// It answers **one sentence, at every path**. Not because routing is hard —
/// study 37 does it in one line — but because a count is the whole of what this
/// program can say without reaching inside itself. `_add`, `_list` and
/// `_setLimit` are private to `command.dart`, and `run` answers an `Outcome`,
/// which is an exit code and text for a person. Study 36 is where that changes.
///
/// This is also the thing study 28 made a bet on. `Store.all` is a `Future`
/// because *a server that blocks on a disk stops answering everybody*, and this
/// is the first line in the book that could not have been written otherwise.
Handler expensesHandler(Store store) => (Request request) async {
  final expenses = await store.all;
  return Response.ok('recorded: ${expenses.length}\n');
};
// #endregion handler
