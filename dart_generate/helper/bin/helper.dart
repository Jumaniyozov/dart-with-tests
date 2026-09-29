import 'dart:io';

import 'package:dart_generate_helper/src/connection.dart';
import 'package:dart_generate_helper/src/helper.dart';

/// The dart_generate helper for VS Code: JSON-RPC over stdin and stdout, and
/// the log on stderr.
Future<void> main() async {
  final helper = Helper(stderr.writeln);
  final connection = Connection(
    stdin,
    stdout,
    helper.handle,
    onError: (method, error, stack) =>
        stderr.writeln('ERROR $method\n$error\n$stack'),
  );
  await connection.done;
  exit(0);
}
