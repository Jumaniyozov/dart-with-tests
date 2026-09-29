/// Runs every fixture marker through the helper process, as the plugin e2e
/// test runs them through the analysis server.
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../plugin/test/markers.dart';
import 'client.dart';

final _input = Directory('../fixtures/input');
final _expected = Directory('../fixtures/lib');

void main() {
  final names = [
    for (final f in _input.listSync().whereType<File>())
      if (f.path.endsWith('.dart')) f.uri.pathSegments.last,
  ]..sort();
  late Directory root;
  late Client helper;

  setUpAll(() async {
    root = await package({
      for (final name in names)
        name: File('${_input.path}/$name').readAsStringSync(),
    });
    helper = await Client.start([root.path]);
  });

  tearDownAll(() async {
    await helper.stop();
    root.deleteSync(recursive: true);
  });

  Future<List<Map<String, Object?>>> actions(
    String path,
    String text,
    (int, int) selection, {
    required bool explicit,
  }) async {
    final (start, end) = selection;
    final result = await helper.request('actions', {
      'path': path,
      'text': text,
      'eol': '\n',
      'offset': start,
      'length': end - start,
      'explicit': explicit,
    });
    return [
      for (final a in result! as List<Object?>) a! as Map<String, Object?>,
    ];
  }

  for (final name in names) {
    test(name, () async {
      final path = '${root.path}/lib/$name';
      var text = File(path).readAsStringSync();
      final markers = parseMarkers(text);
      for (final marker in markers.where((m) => m.expected)) {
        for (final generator in marker.names) {
          final found = await actions(
            path,
            text,
            target(text, marker),
            explicit: false,
          );
          final action = found.where((a) => a['id'] == generator).firstOrNull;
          if (action == null) {
            fail('$name: marker ${marker.index}: no $generator');
          }
          final fixed = switch (generator) {
            'getter' => 'Generate getter',
            'primaryConstructor' => 'Convert to primary constructor',
            _ => null,
          };
          expect(
            action['title'],
            fixed ?? startsWith('${marker.verb} '),
            reason: '$name: marker ${marker.index}: $generator title',
          );
          expect(
            action['replaces'],
            marker.verb == 'Regenerate' || generator == 'primaryConstructor',
            reason: '$name: marker ${marker.index}: $generator replaces',
          );
          text = applyEdits(text, action['edits']);
        }
      }
      for (final marker in markers.where((m) => !m.expected)) {
        final selection = target(text, marker);
        final generator = marker.names.single;
        final quiet = await actions(path, text, selection, explicit: false);
        expect(
          quiet.map((a) => a['id']),
          isNot(contains(generator)),
          reason: '$name: marker ${marker.index}: Cmd+. shows $generator',
        );
        final menu = await actions(path, text, selection, explicit: true);
        final action = menu.firstWhere((a) => a['id'] == generator);
        expect(
          action['disabledReason'],
          endsWith('(${marker.reason})'),
          reason: '$name: marker ${marker.index}: $generator reason',
        );
      }
      expect(text, File('${_expected.path}/$name').readAsStringSync());
    });
  }

  test('the helper logged no error', () {
    expect(helper.log.where((l) => l.startsWith('ERROR')), isEmpty);
  });
}
