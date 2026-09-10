// #region byhand
import 'dart:io';

import 'package:ch35_expenses/expenses.dart';

/// The same answer, with nothing between this program and the socket.
///
/// Written first so that the next file has something to be compared against.
/// Every line here is a decision somebody has to make, and two of them are
/// decisions this version makes by not making them.
Future<void> main(List<String> args) async {
  final store = FileStore(File(fileFrom(args)));
  final server = await HttpServer.bind('localhost', 8080);
  stdout.writeln('listening on http://localhost:8080');
  await for (final request in server) {
    final expenses = await store.all;
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.text
      ..write('recorded: ${expenses.length}\n');
    await request.response.close();
  }
}
// #endregion byhand
