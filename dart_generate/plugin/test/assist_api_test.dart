/// The API that the VS Code helper uses: the four fields of GenerateAssist,
/// run outside the analysis server as the helper runs them.
library;

import 'dart:io';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:dart_generate/assists.dart';
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

typedef Make = GenerateAssist Function({
  required CorrectionProducerContext context,
});

void main() {
  final dir = Directory(
    Directory.systemTemp
        .createTempSync('dart_generate_api_')
        .resolveSymbolicLinksSync(),
  );
  final collection = AnalysisContextCollection(includedPaths: [dir.path]);
  var files = 0;

  tearDownAll(() => dir.deleteSync(recursive: true));

  /// Runs [make] on [source] with the cursor at [at], and returns the
  /// assist and the source after its edits.
  Future<(GenerateAssist, String)> run(
    Make make,
    String source,
    String at, {
    Set<String>? fields,
    bool anywhere = false,
  }) async {
    final path = '${dir.path}/file${files++}.dart';
    File(path).writeAsStringSync(source);
    final session = collection.contextFor(path).currentSession;
    final library =
        await session.getResolvedLibrary(path) as ResolvedLibraryResult;
    final assist = make(
      context: CorrectionProducerContext.createResolved(
        libraryResult: library,
        unitResult: library.units.single,
        selectionOffset: source.indexOf(at),
      ),
    );
    assist
      ..fields = fields
      ..anywhereInClass = anywhere;
    final builder = ChangeBuilder(session: session);
    await assist.compute(builder);
    final edits = [for (final f in builder.sourceChange.edits) ...f.edits];
    return (assist, SourceEdit.applySequence(source, edits));
  }

  const point = '''
class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

  int get sum => x + y;
}
''';

  test('fields replaces the fields of the selection', () async {
    final (_, result) = await run(
      GenerateToString.new,
      point,
      'Point {',
      fields: {'y'},
    );
    expect(result, contains(r"String toString() => 'Point(y: $y)';"));
  });

  test('anywhereInClass accepts a position inside a method', () async {
    final (plain, before) = await run(GenerateToString.new, point, 'x + y');
    expect((before, plain.reason), (point, null));
    final (_, after) = await run(
      GenerateToString.new,
      point,
      'x + y',
      anywhere: true,
    );
    expect(after, contains('String toString()'));
  });

  test('reason names why an action gives no edit', () async {
    final (equality, _) = await run(
      GenerateEquality.new,
      'class Counter {\n  int count = 0;\n}\n',
      'Counter',
    );
    expect(equality.reason, Reason.mutableClass);
    final (inEnum, _) = await run(
      GenerateToString.new,
      'enum Size { small, large }\n',
      'small',
    );
    expect(inEnum.reason, Reason.notAClass);
    final (convert, _) = await run(
      ConvertToPrimaryConstructor.new,
      'class const Money(final int pence);\n',
      'Money',
    );
    expect(convert.reason, Reason.notConvertible);
  });

  test('onError receives a failure', () async {
    final failures = <String>[];
    final (_, result) = await run(
      ({required context}) {
        return _Broken(context: context)
          ..onError = (generator, file, error, stack) =>
              failures.add('$generator $error');
      },
      point,
      'Point {',
    );
    expect(result, point);
    expect(failures, ['generate.broken Bad state: broken']);
  });
}

/// An assist that always fails.
final class _Broken extends GenerateAssist {
  _Broken({required super.context});

  @override
  AssistKind get assistKind => AssistKind('generate.broken', 30, 'Broken');

  @override
  Future<void> generate(ChangeBuilder draft) async =>
      throw StateError('broken');
}
