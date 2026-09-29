import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A minimal LSP client over `dart language-server`: enough to open files,
/// ask for code actions and apply their edits.
final class Lsp {
  Lsp._(this._process) {
    _process.stdout.listen(_onBytes);
    _process.stderr.drain<void>();
    _process.exitCode.then(_onExit);
  }

  final Process _process;
  final _pending = <int, Completer<Object?>>{};
  final _buffer = <int>[];
  var _nextId = 0;

  /// Set when the server process has ended.
  StateError? _exited;

  /// Starts the server on [root]. [log] becomes `DART_GENERATE_LOG`.
  static Future<Lsp> start(String root, {required String log}) async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['language-server', '--protocol=lsp'],
      environment: {'DART_GENERATE_LOG': log},
    );
    final lsp = Lsp._(process);
    try {
      await lsp.request('initialize', {
        'processId': pid,
        'rootUri': Uri.directory(root).toString(),
        'capabilities': {
          'textDocument': {
            'codeAction': {
              'codeActionLiteralSupport': {
                'codeActionKind': {
                  'valueSet': ['', 'quickfix', 'refactor', 'source'],
                },
              },
            },
          },
        },
      });
    } catch (_) {
      // Nobody else holds the process yet, so stop it here.
      await lsp.stop();
      rethrow;
    }
    lsp.notify('initialized', {});
    return lsp;
  }

  Future<Object?> request(String method, Map<String, Object?> params) {
    if (_exited case final error?) return Future.error(error);
    final id = ++_nextId;
    final completer = _pending[id] = Completer<Object?>();
    _send({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params});
    return completer.future;
  }

  void notify(String method, Map<String, Object?> params) =>
      _send({'jsonrpc': '2.0', 'method': method, 'params': params});

  Future<void> stop() async {
    _process.kill();
    await _process.exitCode;
  }

  void _send(Map<String, Object?> message) {
    final body = utf8.encode(jsonEncode(message));
    _process.stdin
      ..add(ascii.encode('Content-Length: ${body.length}\r\n\r\n'))
      ..add(body);
  }

  /// A dead server answers nothing, so every waiting request fails now
  /// instead of hanging.
  void _onExit(int code) {
    final error = _exited = StateError('The server exited with code $code.');
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
      _onMessage(jsonDecode(body) as Map<String, Object?>);
    }
  }

  void _onMessage(Map<String, Object?> message) {
    final id = message['id'];
    if (message.containsKey('method')) {
      // A request from the server, such as client/registerCapability.
      if (id != null) _send({'jsonrpc': '2.0', 'id': id, 'result': null});
      return;
    }
    final completer = _pending.remove(id);
    if (message['error'] case final error?) {
      completer?.completeError(StateError('LSP error: $error'));
    } else {
      completer?.complete(message['result']);
    }
  }
}

/// An LSP position for [offset] in [text]. The fixtures are ASCII, so UTF-16
/// columns equal byte columns.
Map<String, int> position(String text, int offset) {
  final before = text.substring(0, offset);
  final line = '\n'.allMatches(before).length;
  return {'line': line, 'character': offset - (before.lastIndexOf('\n') + 1)};
}

int offsetOf(String text, Map<String, Object?> position) {
  final lines = text.split('\n');
  final line = position['line']! as int;
  var offset = 0;
  for (var i = 0; i < line; i++) {
    offset += lines[i].length + 1;
  }
  return offset + (position['character']! as int);
}

/// Applies the text edits of a code action to [text].
String applyEdit(String text, String uri, Map<String, Object?> action) {
  final edit = action['edit']! as Map<String, Object?>;
  final changes = edit['changes']! as Map<String, Object?>;
  final edits = [
    for (final e in changes[uri]! as List<Object?>)
      if (e case {
        'range': final Map<String, Object?> range,
        'newText': final String text,
      })
        (range: range, text: text),
  ];
  int at(Object? position) => offsetOf(text, position! as Map<String, Object?>);
  // Apply from the end, so earlier offsets stay valid.
  edits.sort((a, b) => at(b.range['start']).compareTo(at(a.range['start'])));
  var result = text;
  for (final e in edits) {
    result = result.replaceRange(
      at(e.range['start']),
      at(e.range['end']),
      e.text,
    );
  }
  return result;
}
