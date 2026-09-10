// #region serve
import 'dart:io';

import 'package:ch35_expenses/expenses.dart';
import 'package:ch35_expenses/src/server.dart';
import 'package:shelf/shelf_io.dart' as io;

/// The same server, taking the dependency.
///
/// `serve` answers a `Future<HttpServer>` — the `dart:io` type the file beside
/// this one bound by hand. `shelf` did not replace `dart:io`; it put a function
/// type in front of it and handed the server back.
Future<void> main(List<String> args) async {
  final store = FileStore(File(fileFrom(args)));
  final server = await io.serve(expensesHandler(store), 'localhost', 8080);
  stdout.writeln('listening on http://localhost:${server.port}');
}
// #endregion serve
