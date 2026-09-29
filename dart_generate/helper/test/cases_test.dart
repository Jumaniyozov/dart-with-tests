/// The helper's own behavior: pickers, composite actions, stale members,
/// plugin folders and files from disk. Inputs are in `test/cases/input/`.
///
/// `DART_GENERATE_UPDATE=1` writes each generated file to
/// `test/cases/expected/` instead of comparing: review that diff.
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:test/test.dart';

import 'client.dart';

final _update = Platform.environment['DART_GENERATE_UPDATE'] == '1';

String _input(String name) => File('test/cases/input/$name').readAsStringSync();

void _expect(String name, String actual) {
  final file = File('test/cases/expected/$name');
  if (_update) {
    file.writeAsStringSync(actual);
  } else {
    expect(actual, file.readAsStringSync());
  }
}

void main() {
  late Directory root;
  late Directory plugin;
  late Client helper;

  setUpAll(() async {
    root = await package({
      for (final f in Directory(
        'test/cases/input',
      ).listSync().whereType<File>())
        f.uri.pathSegments.last: f.readAsStringSync(),
    });
    // The options name the plugin. The helper only reads the name, so the
    // path does not need to exist.
    plugin = await package({
      'gaps.dart': _input('gaps.dart'),
    }, options: 'plugins:\n  dart_generate:\n    path: /nowhere\n');
    helper = await Client.start([root.path, plugin.path]);
  });

  tearDownAll(() async {
    await helper.stop();
    root.deleteSync(recursive: true);
    plugin.deleteSync(recursive: true);
  });

  String path(String name) => '${root.path}/lib/$name';

  Future<List<Map<String, Object?>>> actions(
    String file,
    String text,
    int offset, {
    int length = 0,
    required bool explicit,
  }) async {
    final result = await helper.request('actions', {
      'path': file,
      'text': text,
      'eol': '\n',
      'offset': offset,
      'length': length,
      'explicit': explicit,
    });
    return [
      for (final a in result! as List<Object?>) a! as Map<String, Object?>,
    ];
  }

  Future<Map<String, Object?>> generate(
    String name,
    String text,
    String action,
    int offset, {
    List<String>? fields,
  }) async =>
      (await helper.request('generate', {
            'path': path(name),
            'text': text,
            'eol': '\n',
            'offset': offset,
            'length': 0,
            'action': action,
            'fields': fields,
          }))!
          as Map<String, Object?>;

  Map<String, Object?> byId(List<Map<String, Object?>> list, String id) =>
      list.firstWhere((a) => a['id'] == id);

  test(
    'Generate… lists every action in menu order, from inside a method',
    () async {
      final text = _input('gaps.dart');
      final menu = await actions(
        path('gaps.dart'),
        text,
        text.indexOf('width *'),
        explicit: true,
      );
      expect(
        [for (final a in menu) a['id']],
        [
          'dataClass',
          'toString',
          'equality',
          'copyWith',
          'json',
          'getter',
          'primaryConstructor',
        ],
      );
      expect(
        [for (final a in menu) a['title']],
        [
          'Generate data class',
          'Generate toString()…',
          'Generate ==() and hashCode…',
          'Generate copyWith()',
          'Generate toJson() and fromJson()',
          'Generate getter…',
          'Convert to primary constructor',
        ],
      );
      expect(byId(menu, 'toString')['pick'], {
        'fields': [
          {'name': 'width', 'type': 'int'},
          {'name': 'height', 'type': 'int'},
          {'name': 'depth', 'type': 'int'},
        ],
        'ticked': ['width', 'height', 'depth'],
      });
      expect(
        byId(menu, 'getter')['disabledReason'],
        'the class has no field that this action can use (noFields)',
      );
      expect(byId(menu, 'primaryConstructor')['disabledReason'], isNull);
    },
  );

  test('toString with picked fields that have a gap', () async {
    final text = _input('gaps.dart');
    final result = await generate(
      'gaps.dart',
      text,
      'toString',
      text.indexOf('width *'),
      fields: ['width', 'depth'],
    );
    expect(result['replaces'], false);
    _expect('gaps.dart', applyEdits(text, result['edits']));
  });

  test('the getter picker lists private fields without a getter', () async {
    final text = _input('getters.dart');
    final menu = await actions(
      path('getters.dart'),
      text,
      text.indexOf('Counter'),
      explicit: false,
    );
    expect(byId(menu, 'getter'), {
      'id': 'getter',
      'title': 'Generate getter…',
      'disabledReason': null,
      'pick': {
        'fields': [
          {'name': '_count', 'type': 'int'},
          {'name': '_step', 'type': 'int'},
        ],
        'ticked': <String>[],
      },
    });
  });

  test(
    'in an enum every action is greyed out, outside a class none shows',
    () async {
      final text = _input('shapes.dart');
      final menu = await actions(
        path('shapes.dart'),
        text,
        text.indexOf('circle,'),
        explicit: true,
      );
      expect(menu, hasLength(7));
      for (final a in menu) {
        expect(
          a['disabledReason'],
          'the cursor is in an enum, a mixin or an extension type (notAClass)',
          reason: '${a['id']}',
        );
      }
      expect(
        await actions(path('shapes.dart'), text, 0, explicit: true),
        isEmpty,
      );
    },
  );

  test('a plugin folder hides Cmd+. actions and keeps Generate…', () async {
    final file = '${plugin.path}/lib/gaps.dart';
    final text = _input('gaps.dart');
    final at = text.indexOf('Box');
    expect(await actions(file, text, at, explicit: false), isEmpty);
    expect(await actions(file, text, at, explicit: true), hasLength(7));
    // A changed analysis_options.yaml rebuilds the analysis.
    File('${plugin.path}/analysis_options.yaml').writeAsStringSync('');
    expect(await actions(file, text, at, explicit: false), isNotEmpty);
  });

  test(
    'other files: an overlay stays until closed, disk after filesChanged',
    () async {
      final paint = _input('paint.dart');
      Future<String> toJson() async {
        final result = await generate(
          'paint.dart',
          paint,
          'json',
          paint.indexOf('Paint'),
        );
        return applyEdits(paint, result['edits']);
      }

      expect(await toJson(), contains("'color': color.name"));
      // A request for colors.dart puts its editor text on the overlay.
      await actions(
        path('colors.dart'),
        'class Color {\n  String toJson() => "";\n}\n',
        0,
        explicit: false,
      );
      expect(await toJson(), contains("'color': color.toJson()"));
      helper.notify('closed', {'path': path('colors.dart')});
      expect(await toJson(), contains("'color': color.name"));
      File(path('colors.dart'))
          .writeAsStringSync('class Color {\n  String toJson() => "";\n}\n');
      helper.notify('filesChanged', {
        'paths': [path('colors.dart')],
      });
      expect(await toJson(), contains("'color': color.toJson()"));
    },
  );

  test('other files: a composite puts the request text back', () async {
    final box = _input('gaps.dart');
    final result = await generate(
      'gaps.dart',
      box,
      'dataClass',
      box.indexOf('Box'),
    );
    expect(
      applyEdits(box, result['edits']),
      contains('Map<String, Object?> toJson()'),
    );
    // spec takes its type from Box.toJson. The editor's Box has no toJson,
    // so JSON must not read spec as a map.
    const parcel = '''
import 'gaps.dart';

class Parcel {
  Parcel(this.box, this.spec);

  final Box box;
  var spec = const Box(1, 2, 3).toJson();
}
''';
    addTearDown(() => helper.notify('closed', {'path': path('parcel.dart')}));
    final json = await generate(
      'parcel.dart',
      parcel,
      'json',
      parcel.indexOf('Parcel'),
    );
    expect(
      applyEdits(parcel, json['edits']),
      isNot(contains('Map<String, Object?> spec')),
    );
  });

  test('data class adds the collection import and skips JSON', () async {
    final text = _input('data_class.dart');
    final result = await generate(
      'data_class.dart',
      text,
      'dataClass',
      text.indexOf('id;'),
    );
    expect(result['edits'], hasLength(1));
    expect(result['replaces'], false);
    expect(result['skipped'], [
      'JSON: a map key is not String (nonStringMapKey)',
    ]);
    _expect('data_class.dart', applyEdits(text, result['edits']));
  });

  test('the getter picker adds two getters', () async {
    final text = _input('getters.dart');
    final result = await generate(
      'getters.dart',
      text,
      'getter',
      text.indexOf('Counter'),
      fields: ['_count', '_step'],
    );
    expect(result['skipped'], isEmpty);
    _expect('getters.dart', applyEdits(text, result['edits']));
  });

  test('Regenerate ticks the fields that the member uses', () async {
    final text = _input('stale.dart');
    final at = text.indexOf('class Point') + 6;
    final menu = await actions(path('stale.dart'), text, at, explicit: true);
    expect(byId(menu, 'toString')['title'], 'Regenerate toString()…');
    expect((byId(menu, 'toString')['pick']! as Map)['ticked'], ['x']);
    expect((byId(menu, 'equality')['pick']! as Map)['ticked'], ['x']);
    final field = text.indexOf('final int y;');
    final selected = await actions(
      path('stale.dart'),
      text,
      field,
      length: 'final int y;'.length,
      explicit: true,
    );
    expect((byId(selected, 'toString')['pick']! as Map)['ticked'], ['y']);
    final money = text.indexOf('class Money') + 6;
    final read = await actions(path('stale.dart'), text, money, explicit: true);
    expect((byId(read, 'toString')['pick']! as Map)['ticked'], ['_pence']);
  });

  test('each stale member gets its mark', () async {
    final text = _input('stale.dart');
    final result = await helper.request('stale', {
      'path': path('stale.dart'),
      'text': text,
    });
    final items = [
      for (final i in (result! as Map)['items'] as List<Object?>)
        i! as Map<String, Object?>,
    ];
    expect(
      [
        for (final i in items)
          (
            text.substring(
              i['offset']! as int,
              (i['offset']! as int) + (i['length']! as int),
            ),
            i['severity'],
            i['message'],
          ),
      ],
      [
        ('copyWith', 'warning', 'copyWith() does not cover note.'),
        ('toJson', 'warning', 'toJson() does not cover note.'),
        ('fromJson', 'warning', 'fromJson() does not cover note.'),
        ('toString', 'hint', 'toString() does not show y.'),
        ('==', 'hint', '==() and hashCode do not use y.'),
      ],
    );
  });

  test('a syntax error skips the scan', () async {
    final result = await helper.request('stale', {
      'path': path('stale.dart'),
      'text': 'class A {\n  final int x;\n  String toString() =>\n}\n',
    });
    expect(result, {'skipped': true});
  });

  test('overlapping requests each answer for their own text', () async {
    final text = _input('stale.dart');
    final fixed = text.replaceFirst(
      "'Point(x: \$x)'",
      "'Point(x: \$x, y: \$y)'",
    );
    final answers = await Future.wait([
      for (var i = 0; i < 10; i++)
        helper.request('stale', {
          'path': path('stale.dart'),
          'text': i.isEven ? text : fixed,
        }),
    ]);
    for (final (i, answer) in answers.indexed) {
      final messages = [
        for (final item in (answer! as Map)['items'] as List<Object?>)
          (item! as Map)['message'],
      ];
      expect(
        messages.contains('toString() does not show y.'),
        i.isEven,
        reason: 'request $i',
      );
    }
  });

  test('the helper logged no error', () {
    expect(helper.log.where((l) => l.startsWith('ERROR')), isEmpty);
  });
}
