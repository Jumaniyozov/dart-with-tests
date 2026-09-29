import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:dart_generate_helper/src/workspace.dart';
import 'package:test/test.dart';

import 'client.dart';

void main() {
  const built =
      '3.13.2 (stable) (Tue Aug 25 01:01:12 2026 -0700) on "macos_arm64"';

  test('a patch release gives no warning', () {
    expect(versionWarning('3.13.5\n', built), isNull);
  });

  test('another minor version gives the rebuild warning', () {
    expect(
      versionWarning('3.14.0\n', built),
      'Dart Generate was built for Dart 3.13 and your SDK is 3.14. '
      'Rebuild the extension.',
    );
  });

  group('two packages in one folder', () {
    late Directory root;
    late Workspace workspace;

    setUp(() async {
      root = Directory(
        Directory.systemTemp
            .createTempSync('dart_generate_helper_')
            .resolveSymbolicLinksSync(),
      );
      for (final (name, pubspec, lib) in [
        ('a', 'name: a\n', 'class A {\n  final int x = 0;\n}\n'),
        (
          'b',
          'name: b\ndependencies:\n  a:\n    path: ../a\n',
          "import 'package:a/a.dart';\n\nfinal a = A();\n",
        ),
      ]) {
        Directory('${root.path}/$name/lib').createSync(recursive: true);
        File('${root.path}/$name/pubspec.yaml').writeAsStringSync('''
$pubspec
environment:
  sdk: ^3.13.0
''');
        File('${root.path}/$name/lib/$name.dart').writeAsStringSync(lib);
      }
      for (final name in ['a', 'b']) {
        final pubGet = await Process.run(Platform.resolvedExecutable, [
          'pub',
          'get',
          '--offline',
        ], workingDirectory: '${root.path}/$name');
        expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}${pubGet.stderr}');
      }
      workspace = Workspace(Client.sdkPath, [root.path]);
    });

    tearDown(() async {
      await workspace.dispose();
      root.deleteSync(recursive: true);
    });

    test('an overlay of a reaches the context of b, which imports a', () async {
      final b = '${root.path}/b/lib/b.dart';
      final a = '${root.path}/a/lib/a.dart';
      Future<List<String>> fieldsOfA() async {
        final (_, unit) = (await workspace.resolve(
          b,
          File(b).readAsStringSync(),
        ))!;
        final variable =
            unit.unit.declaredFragment!.element.topLevelVariables.single;
        final cls = variable.type.element! as ClassElement;
        return [for (final f in cls.fields) f.displayName];
      }

      expect(await fieldsOfA(), ['x']);
      await workspace.resolve(
        a,
        'class A {\n  final int x = 0;\n  final int y = 0;\n}\n',
      );
      expect(await fieldsOfA(), ['x', 'y']);
    });
  });
}
