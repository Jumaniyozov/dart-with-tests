import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A JSON-RPC client over the helper's stdin and stdout, with its stderr
/// kept for the checks.
final class Client {
  Client._(this._process) {
    _process.stdout.listen(_onBytes);
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(log.add);
    _process.exitCode.then(_onExit);
  }

  final Process _process;
  final _pending = <int, Completer<Object?>>{};
  final _buffer = <int>[];
  var _nextId = 0;
  StateError? _exited;

  /// The helper's stderr lines.
  final log = <String>[];

  /// The SDK of the Dart that runs the tests.
  static final sdkPath = File(Platform.resolvedExecutable).parent.parent.path;

  /// Starts `bin/helper.dart` and initializes it on [folders].
  static Future<Client> start(List<String> folders) async {
    final process = await Process.start(Platform.resolvedExecutable, [
      'bin/helper.dart',
    ]);
    final client = Client._(process);
    await client.request('initialize', {
      'sdkPath': sdkPath,
      'folders': folders,
    });
    return client;
  }

  /// Sends a request. After 60 s without an answer, it fails with the method
  /// and the last 20 stderr lines, so a hung helper explains itself.
  Future<Object?> request(String method, Map<String, Object?> params) {
    if (_exited case final error?) return Future.error(error);
    final id = ++_nextId;
    final completer = _pending[id] = Completer<Object?>();
    _send({'id': id, 'method': method, 'params': params});
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _pending.remove(id);
        final tail = log.skip(log.length > 20 ? log.length - 20 : 0);
        throw TimeoutException(
          '$method: no answer in 60 s. The last stderr lines:\n'
          '${tail.join('\n')}',
        );
      },
    );
  }

  void notify(String method, Map<String, Object?> params) =>
      _send({'method': method, 'params': params});

  Future<void> stop() async {
    await _process.stdin.close();
    await _process.exitCode;
  }

  void _send(Map<String, Object?> message) {
    final body = utf8.encode(jsonEncode({'jsonrpc': '2.0', ...message}));
    _process.stdin
      ..add(ascii.encode('Content-Length: ${body.length}\r\n\r\n'))
      ..add(body);
  }

  void _onExit(int code) {
    final error = _exited = StateError('The helper exited with code $code.');
    for (final completer in _pending.values) {
      completer.completeError(error);
    }
    _pending.clear();
  }

  void _onBytes(List<int> bytes) {
    _buffer.addAll(bytes);
    while (true) {
      final text = latin1.decode(_buffer);
      final headerEnd = text.indexOf('\r\n\r\n');
      if (headerEnd < 0) return;
      final length = int.parse(
        RegExp(r'Content-Length: (\d+)').firstMatch(text)!.group(1)!,
      );
      final start = headerEnd + 4;
      if (_buffer.length < start + length) return;
      final body = utf8.decode(_buffer.sublist(start, start + length));
      _buffer.removeRange(0, start + length);
      final message = jsonDecode(body) as Map<String, Object?>;
      final completer = _pending.remove(message['id']);
      if (message['error'] case final error?) {
        completer?.completeError(StateError('helper error: $error'));
      } else {
        completer?.complete(message['result']);
      }
    }
  }
}

/// Applies `{offset, length, text}` edits to [text].
String applyEdits(String text, Object? edits) {
  final list = [
    for (final e in edits! as List<Object?>) e! as Map<String, Object?>,
  ]..sort((a, b) => (b['offset']! as int).compareTo(a['offset']! as int));
  var result = text;
  for (final e in list) {
    final offset = e['offset']! as int;
    result = result.replaceRange(
      offset,
      offset + (e['length']! as int),
      e['text']! as String,
    );
  }
  return result;
}

/// A temporary package with [files] under `lib/`, after `dart pub get`.
Future<Directory> package(
  Map<String, String> files, {
  String options = '',
}) async {
  final root = Directory.systemTemp.createTempSync('dart_generate_helper_');
  final dir = Directory(root.resolveSymbolicLinksSync());
  Directory('${dir.path}/lib').createSync();
  for (final MapEntry(:key, :value) in files.entries) {
    File('${dir.path}/lib/$key').writeAsStringSync(value);
  }
  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: cases
environment:
  sdk: ^3.13.0
dependencies:
  collection: ^1.19.1
''');
  if (options.isNotEmpty) {
    File('${dir.path}/analysis_options.yaml').writeAsStringSync(options);
  }
  final pubGet = await Process.run(Platform.resolvedExecutable, [
    'pub',
    'get',
    '--offline',
  ], workingDirectory: dir.path);
  if (pubGet.exitCode != 0) {
    throw StateError('dart pub get failed:\n${pubGet.stdout}${pubGet.stderr}');
  }
  return dir;
}
