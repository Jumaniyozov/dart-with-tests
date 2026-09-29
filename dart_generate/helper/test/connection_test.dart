import 'dart:async';
import 'dart:convert';

import 'package:dart_generate_helper/src/connection.dart';
import 'package:test/test.dart';

/// One framed message, as `vscode-jsonrpc` writes it.
List<int> frame(Map<String, Object?> message) {
  final body = utf8.encode(jsonEncode({'jsonrpc': '2.0', ...message}));
  return [...ascii.encode('Content-Length: ${body.length}\r\n\r\n'), ...body];
}

void main() {
  late StreamController<List<int>> input;
  late List<Map<String, Object?>> replies;
  late List<String> errors;
  late Completer<void> gate;

  setUp(() {
    input = StreamController<List<int>>();
    final output = StreamController<List<int>>();
    replies = [];
    errors = [];
    gate = Completer<void>();
    Connection(
      input.stream,
      output.sink,
      (method, params) async => switch (method) {
        'echo' => params['text'],
        'slow' => gate.future.then((_) => 'slow'),
        'fail' => throw StateError('broken'),
        _ => null,
      },
      onError: (method, error, stack) => errors.add('$method: $error'),
    );
    final buffer = <int>[];
    output.stream.listen((bytes) {
      buffer.addAll(bytes);
      while (true) {
        final text = latin1.decode(buffer);
        final headerEnd = text.indexOf('\r\n\r\n');
        if (headerEnd < 0) return;
        final length = int.parse(text.substring(16, headerEnd));
        if (buffer.length < headerEnd + 4 + length) return;
        final body = buffer.sublist(headerEnd + 4, headerEnd + 4 + length);
        buffer.removeRange(0, headerEnd + 4 + length);
        replies.add(jsonDecode(utf8.decode(body)) as Map<String, Object?>);
      }
    });
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'a message split across chunks, with UTF-8 text, gets its answer',
    () async {
      final bytes = frame({
        'id': 1,
        'method': 'echo',
        'params': {'text': 'Generate…'},
      });
      input
        ..add(bytes.sublist(0, 10))
        ..add(bytes.sublist(10, bytes.length - 3))
        ..add(bytes.sublist(bytes.length - 3));
      await settle();
      await settle();
      expect(replies, [
        {'jsonrpc': '2.0', 'id': 1, 'result': 'Generate…'},
      ]);
    },
  );

  test('requests answer in arrival order, one at a time', () async {
    input
      ..add(frame({'id': 1, 'method': 'slow'}))
      ..add(
        frame({
          'id': 2,
          'method': 'echo',
          'params': {'text': 'fast'},
        }),
      );
    await settle();
    expect(replies, isEmpty);
    gate.complete();
    await settle();
    await settle();
    expect([for (final r in replies) r['id']], [1, 2]);
  });

  test('a cancelled request that waits gets -32800', () async {
    input
      ..add(frame({'id': 1, 'method': 'slow'}))
      ..add(
        frame({
          'id': 2,
          'method': 'echo',
          'params': {'text': 'late'},
        }),
      )
      ..add(
        frame({
          'method': r'$/cancelRequest',
          'params': {'id': 2},
        }),
      );
    await settle();
    gate.complete();
    await settle();
    await settle();
    expect(replies[0]['result'], 'slow');
    expect(replies[1]['id'], 2);
    expect((replies[1]['error']! as Map)['code'], -32800);
  });

  test('a failing handler gets -32603 and reaches onError', () async {
    input.add(frame({'id': 7, 'method': 'fail'}));
    await settle();
    await settle();
    expect(replies.single['id'], 7);
    expect((replies.single['error']! as Map)['code'], -32603);
    expect(errors, ['fail: Bad state: broken']);
  });

  test('a notification gets no answer', () async {
    input.add(
      frame({
        'method': 'echo',
        'params': {'text': 'x'},
      }),
    );
    await settle();
    await settle();
    expect(replies, isEmpty);
  });
}
