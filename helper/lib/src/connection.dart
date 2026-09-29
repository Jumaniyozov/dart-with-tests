import 'dart:async';
import 'dart:convert';

/// Answers one request or notification: the method name and its params.
typedef Handler = Future<Object?> Function(
  String method,
  Map<String, Object?> params,
);

/// A JSON-RPC 2.0 connection with `Content-Length` framing, the format of
/// `vscode-jsonrpc`.
///
/// Messages run one at a time, in arrival order, so a new overlay never lands
/// while an older request resolves. `$/cancelRequest` skips a request that
/// still waits, and it gets the error code -32800.
final class Connection {
  Connection(
    Stream<List<int>> input,
    this._output,
    this._handle, {
    required this.onError,
  }) {
    input.listen(_onBytes, onDone: _closed.complete);
  }

  final Sink<List<int>> _output;
  final Handler _handle;

  /// Receives the failure of a handler. The connection answers the request
  /// with the error code -32603.
  final void Function(String method, Object error, StackTrace stack) onError;

  final _buffer = <int>[];
  final _closed = Completer<void>();

  /// The IDs of requests that wait in the queue.
  final _waiting = <Object>{};
  var _queue = Future<void>.value();

  /// Completes when the input closes and every queued message ran.
  Future<void> get done => _closed.future.then((_) => _queue);

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
    // A message without a method is a response. The helper sends no
    // requests, so it ignores responses.
    if (message['method'] case final String method) {
      final id = message['id'];
      final params = message['params'] as Map<String, Object?>? ?? const {};
      if (method == r'$/cancelRequest') {
        _waiting.remove(params['id']);
        return;
      }
      if (id != null) _waiting.add(id);
      _queue = _queue.then((_) => _run(id, method, params));
    }
  }

  Future<void> _run(
    Object? id,
    String method,
    Map<String, Object?> params,
  ) async {
    if (id != null && !_waiting.remove(id)) {
      _send({
        'id': id,
        'error': {'code': -32800, 'message': 'The request was cancelled.'},
      });
      return;
    }
    try {
      final result = await _handle(method, params);
      if (id != null) _send({'id': id, 'result': result});
    } catch (error, stack) {
      onError(method, error, stack);
      if (id != null) {
        _send({
          'id': id,
          'error': {'code': -32603, 'message': '$error'},
        });
      }
    }
  }

  void _send(Map<String, Object?> message) {
    final body = utf8.encode(jsonEncode({'jsonrpc': '2.0', ...message}));
    _output
      ..add(ascii.encode('Content-Length: ${body.length}\r\n\r\n'))
      ..add(body);
  }
}
