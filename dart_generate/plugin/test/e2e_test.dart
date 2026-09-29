/// Runs every fixture through the real analysis server over LSP.
///
/// Run with `dart test -t e2e`. `DART_GENERATE_UPDATE=1` writes the output to
/// `fixtures/lib/` instead of comparing: review that diff before you commit.
@Tags(['e2e'])
@Timeout(Duration(minutes: 20))
library;

import 'dart:io';

import 'package:dart_generate/src/assists.dart';
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'lsp.dart';
import 'markers.dart';

final _input = Directory('../fixtures/input');
final _expected = Directory('../fixtures/lib');
final _update = Platform.environment['DART_GENERATE_UPDATE'] == '1';

List<String> _dartFiles(Directory dir) => dir.existsSync()
    ? ([
        for (final f in dir.listSync().whereType<File>())
          if (f.path.endsWith('.dart')) f.uri.pathSegments.last,
      ]..sort())
    : [];

/// A short hash of [text] that stays the same from run to run.
String _hash(String text) => text.codeUnits
    .fold(0, (h, c) => (h * 31 + c) & 0x7fffffff)
    .toRadixString(16);

void main() {
  final names = _dartFiles(_input);
  // The server keys its plugin cache in `~/.dartServer/.plugin_manager` by
  // the root path. One fixed path, with its symlinks resolved, reuses one
  // entry. The hash of the checkout path keeps two checkouts from sharing a
  // root.
  final root = Directory(
    '${Directory.systemTemp.resolveSymbolicLinksSync()}/dart_generate_e2e_'
    '${_hash(Directory.current.absolute.path)}',
  );
  final log = File('${root.path}/dart_generate.log');
  // `null` until setUpAll starts the server. It stays `null` when setUpAll
  // fails before that.
  Lsp? server;
  // A lock file next to the root makes a second run in the same checkout
  // wait for the first, instead of racing it for the same root.
  RandomAccessFile? lock;

  setUpAll(() async {
    final lockFile = lock = File('${root.path}.lock')
        .openSync(mode: FileMode.write);
    try {
      lockFile.lockSync(FileLock.exclusive);
    } on FileSystemException {
      // A blocking lock gives no output, so a second run looks hung. Say
      // why before it waits.
      print('Waiting for another e2e run in this checkout.');
      lockFile.lockSync(FileLock.blockingExclusive);
    }
    if (root.existsSync()) root.deleteSync(recursive: true);
    Directory('${root.path}/lib').createSync(recursive: true);
    for (final name in names) {
      File('${_input.path}/$name').copySync('${root.path}/lib/$name');
    }
    File('${root.path}/pubspec.yaml').writeAsStringSync('''
name: e2e
environment:
  sdk: ^3.13.0
dependencies:
  collection: ^1.19.1
dev_dependencies:
  lints: ^6.1.0
''');
    File('${root.path}/analysis_options.yaml').writeAsStringSync('''
include: package:lints/recommended.yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
plugins:
  dart_generate:
    path: ${Directory.current.absolute.path}
''');
    final pubGet = await _run(['pub', 'get', '--offline'], root.path);
    if (pubGet.exitCode != 0) {
      fail(
        'dart pub get --offline exited with ${pubGet.exitCode}:\n'
        '${pubGet.output}',
      );
    }
    // `dart analyze` compiles the plugin and prints plugin errors, which the
    // editor never shows.
    final analyze = await _run(['analyze'], root.path, log: log.path);
    expect(
      analyze.output,
      isNot(contains('An error occurred while executing an analyzer plugin')),
    );
    server = await Lsp.start(root.path, log: log.path);
  });

  tearDownAll(() async {
    try {
      await server?.stop();
    } finally {
      if (root.existsSync()) root.deleteSync(recursive: true);
      // Closing the file releases the lock. If a run dies, the OS releases
      // it too.
      lock?.closeSync();
    }
  });

  test('markers cover every generator and adapter reason', () {
    expect(names, isNotEmpty, reason: 'fixtures/input is missing or empty');
    if (!_update) expect(_dartFiles(_expected), names);
    final markers = [
      for (final name in names)
        ...parseMarkers(File('${_input.path}/$name').readAsStringSync()),
    ];
    expect(markers, isNotEmpty);
    for (final m in markers) {
      expect(generatorNames, containsAll(m.names));
    }
    final generated = {
      for (final m in markers)
        if (m.expected) ...m.names,
    };
    expect(generated, containsAll(generatorNames));
    final reasons = <String>{
      for (final m in markers)
        if (!m.expected) m.reason!,
    };
    for (final r in Reason.values.where((r) => r.owner == Owner.adapter)) {
      expect(reasons, contains(r.name));
    }
  });

  for (final name in names) {
    test(name, () async {
      final lsp = server!;
      final path = '${root.path}/lib/$name';
      final uri = Uri.file(path).toString();
      var text = File(path).readAsStringSync();
      var version = 1;
      lsp.notify('textDocument/didOpen', {
        'textDocument': {
          'uri': uri,
          'languageId': 'dart',
          'version': version,
          'text': text,
        },
      });

      Future<List<Map<String, Object?>>> actions((int, int) selection) async {
        final (start, end) = selection;
        final result = await lsp.request('textDocument/codeAction', {
          'textDocument': {'uri': uri},
          'range': {'start': position(text, start), 'end': position(text, end)},
          'context': {
            'diagnostics': <Object?>[],
            'only': ['refactor.generate'],
          },
        });
        return [
          for (final a in (result as List<Object?>?) ?? const [])
            a! as Map<String, Object?>,
        ];
      }

      // Polls until [found] accepts the actions, or the time is up.
      Future<List<Map<String, Object?>>> poll(
        (int, int) Function() selection,
        bool Function(List<Map<String, Object?>>) found,
      ) async {
        final deadline = DateTime.now().add(const Duration(seconds: 120));
        while (true) {
          final result = await actions(selection());
          if (found(result) || DateTime.now().isAfter(deadline)) return result;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }

      final markers = parseMarkers(text);
      for (final marker in markers.where((m) => m.expected)) {
        for (final generator in marker.names) {
          final kind = 'refactor.generate.$generator';
          final result = await poll(
            () => target(text, marker),
            (r) => r.any((a) => a['kind'] == kind),
          );
          final action = result.where((a) => a['kind'] == kind).firstOrNull;
          if (action == null) fail('$name: marker ${marker.index}: no $kind');
          // getter and primaryConstructor have one fixed title each.
          final title = switch (generator) {
            'getter' => 'Generate getter',
            'primaryConstructor' => 'Convert to primary constructor',
            _ => null,
          };
          if (title != null) {
            expect(
              marker.verb,
              'Generate',
              reason:
                  '$name: marker ${marker.index}: $kind has no "Regenerate"',
            );
          }
          expect(
            action['title'],
            title ?? startsWith('${marker.verb} '),
            reason: '$name: marker ${marker.index}: $kind title',
          );
          text = applyEdit(text, uri, action);
          lsp.notify('textDocument/didChange', {
            'textDocument': {'uri': uri, 'version': ++version},
            'contentChanges': [
              {'text': text},
            ],
          });
        }
      }

      final absent = markers.where((m) => !m.expected).toList();
      if (absent.isNotEmpty) {
        // An empty answer proves nothing until the plugin answers somewhere
        // in this file.
        final deadline = DateTime.now().add(const Duration(seconds: 120));
        var answered = false;
        while (!answered && DateTime.now().isBefore(deadline)) {
          for (final m in markers) {
            if ((await actions(target(text, m))).isNotEmpty) answered = true;
          }
          if (!answered) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
        }
        if (!answered) {
          fail('$name: no action appeared, so @not proves nothing');
        }
        for (final marker in absent) {
          final kinds = (await actions(target(text, marker)))
              .map((a) => a['kind']);
          expect(
            kinds,
            isNot(contains('refactor.generate.${marker.names.single}')),
            reason: '$name: marker ${marker.index}',
          );
        }
      }

      final expected = File('${_expected.path}/$name');
      if (_update) {
        expected.writeAsStringSync(text);
      } else {
        expect(text, expected.readAsStringSync());
      }
    });
  }

  test('the log is empty', () {
    expect(log.existsSync() ? log.readAsStringSync() : '', isEmpty);
  });
}

Future<({int exitCode, String output})> _run(
  List<String> args,
  String dir, {
  String? log,
}) async {
  final result = await Process.run(
    Platform.resolvedExecutable,
    args,
    workingDirectory: dir,
    environment: {'DART_GENERATE_LOG': ?log},
  );
  return (
    exitCode: result.exitCode,
    output: '${result.stdout}${result.stderr}',
  );
}
