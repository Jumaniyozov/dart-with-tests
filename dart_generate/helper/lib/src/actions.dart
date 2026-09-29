import 'dart:math';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:dart_generate/assists.dart';
import 'package:generate_core/generate_core.dart';

import 'stale.dart';

/// Receives the failure of an assist.
typedef OnError = void Function(
  String generator,
  String file,
  Object error,
  StackTrace stack,
);

/// Resolves the request's file again, with new text.
typedef Resolve = Future<(ResolvedLibraryResult, ResolvedUnitResult)?> Function(
  String text,
);

const internalError = 'internal error: see Output › Dart Generate';

/// The assists, by action ID, in menu order.
final _assists =
    <
      String,
      GenerateAssist Function({required CorrectionProducerContext context})
    >{
      'toString': GenerateToString.new,
      'equality': GenerateEquality.new,
      'copyWith': GenerateCopyWith.new,
      'json': GenerateJson.new,
      'getter': GenerateGetter.new,
      'primaryConstructor': ConvertToPrimaryConstructor.new,
    };

/// The steps of "Generate data class", in order, with the names that a
/// skipped-step message uses.
const _steps = {
  'toString': 'toString()',
  'equality': '==() and hashCode',
  'copyWith': 'copyWith()',
  'json': 'JSON',
};

/// What one assist gives at one position.
final class Result(
  final GenerateAssist assist,
  final List<SourceEdit> edits,
  final bool failed,
) {
  String get title => assist.assistKind!.message.replaceAll('{0}', assist.verb);

  bool get regenerates => assist.verb == 'Regenerate';

  /// The greyed-out text, or `null` when the action gives an edit or does
  /// not apply here.
  String? get disabled => failed
      ? internalError
      : switch (assist.reason) {
          final r? => describe(r),
          null => null,
        };
}

/// The reason text that the menu shows: `a field is not final (mutableClass)`.
String describe(Reason r) => '${r.message} (${r.name})';

/// One request's file, resolved, with its line ending.
final class Document(
  final ResolvedLibraryResult library,
  final ResolvedUnitResult unit,
  final String eol,
  final OnError onError,
) {
  /// Runs the assist of [id] at [offset] and [length].
  Future<Result> run(
    String id,
    int offset,
    int length, {
    bool anywhere = false,
    Set<String>? fields,
  }) async {
    var failed = false;
    final assist = _assists[id]!(
      context: CorrectionProducerContext.createResolved(
        libraryResult: library,
        unitResult: unit,
        selectionOffset: offset,
        selectionLength: length,
      ),
    );
    assist
      ..anywhereInClass = anywhere
      ..fields = fields
      ..onError = (generator, file, error, stack) {
        failed = true;
        onError(generator, file, error, stack);
      };
    final builder = ChangeBuilder(session: unit.session, defaultEol: eol);
    await assist.compute(builder);
    final edits = [for (final f in builder.sourceChange.edits) ...f.edits];
    return Result(assist, edits, failed);
  }
}

/// The actions at [offset], in menu order. Empty when the offset is not in
/// a class, an enum, a mixin or an extension type.
///
/// [explicit] is a Generate… request: every action shows, greyed out with
/// its reason when it gives no edit, and toString and `==` open a picker.
/// Otherwise (Cmd+.) only the actions that give an edit show.
Future<List<Map<String, Object?>>> actions(
  Document doc,
  int offset,
  int length, {
  required bool explicit,
}) async {
  final results = {
    for (final id in _assists.keys)
      id: await doc.run(id, offset, length, anywhere: explicit),
  };
  if (results.values.every(
    (r) => r.edits.isEmpty && r.assist.reason == null && !r.failed,
  )) {
    return const [];
  }
  final cls = _classAt(doc.unit, offset);
  final element = cls?.declaredFragment?.element;
  final out = <Map<String, Object?>>[];

  // "Generate data class" carries no edit: choosing it sends `generate`.
  final steps = [for (final id in _steps.keys) results[id]!];
  final applies = steps.any((r) => r.edits.isNotEmpty);
  if (explicit || applies) {
    final reasons = {for (final r in steps) r.disabled};
    out.add({
      'id': 'dataClass',
      'title':
          '${steps.any((r) => r.regenerates) ? 'Regenerate' : 'Generate'} '
          'data class',
      'disabledReason': applies
          ? null
          : reasons.length == 1
          ? reasons.single
          : 'no step applies',
    });
  }

  for (final id in ['toString', 'equality']) {
    final r = results[id]!;
    if (explicit) {
      out.add({
        'id': id,
        'title': '${r.title}…',
        'disabledReason': r.disabled,
        if (r.disabled == null && cls != null && element != null)
          'pick': _pick(cls, element, doc.unit, id, offset, length),
      });
    } else if (r.edits.isNotEmpty) {
      out.add(_withEdits(id, r));
    }
  }

  for (final id in ['copyWith', 'json']) {
    final r = results[id]!;
    if (explicit || r.edits.isNotEmpty) out.add(_withEdits(id, r));
  }

  // The getter: at once for the private field under the cursor, or with a
  // picker from the class header or from Generate….
  final getter = results['getter']!;
  final onField =
      getter.edits.isNotEmpty ||
      getter.assist.reason == Reason.publicNameTaken ||
      getter.failed;
  final onHeader =
      cls != null &&
      offset >= cls.offset &&
      offset < cls.body.beginToken.offset;
  if (onField) {
    if (explicit || getter.edits.isNotEmpty) {
      out.add(_withEdits('getter', getter));
    }
  } else if (cls != null && element != null && (explicit || onHeader)) {
    final fields = _getterFields(cls, element);
    if (explicit || fields.isNotEmpty) {
      final anyPrivate = fieldNames(cls).any((f) => f.$1.startsWith('_'));
      out.add({
        'id': 'getter',
        'title': 'Generate getter…',
        'disabledReason': fields.isNotEmpty
            ? null
            : describe(anyPrivate ? Reason.publicNameTaken : Reason.noFields),
        if (fields.isNotEmpty)
          'pick': {
            'fields': [
              for (final (name, type) in fields) {'name': name, 'type': type},
            ],
            'ticked': const <String>[],
          },
      });
    }
  } else if (explicit) {
    out.add(_withEdits('getter', getter));
  }

  final convert = results['primaryConstructor']!;
  if (explicit || convert.edits.isNotEmpty) {
    out.add(_withEdits('primaryConstructor', convert));
  }
  return out;
}

Map<String, Object?> _withEdits(String id, Result r) => {
  'id': id,
  'title': r.title,
  'disabledReason': r.disabled,
  'edits': _encode(r.edits),
  'replaces': r.regenerates || id == 'primaryConstructor',
};

/// [edits] as the JSON that the extension reads.
List<Map<String, Object?>> _encode(List<SourceEdit> edits) => [
  for (final e in edits)
    {'offset': e.offset, 'length': e.length, 'text': e.replacement},
];

/// The picker of toString or `==`: the fields that the action can use, and
/// the ones ticked at the start. A selection ticks the fields that it
/// covers. Otherwise an existing member ticks the fields that it uses, so a
/// deliberate subset stays. Otherwise every field is ticked.
Map<String, Object?> _pick(
  ClassDeclaration cls,
  ClassElement element,
  ResolvedUnitResult unit,
  String id,
  int offset,
  int length,
) {
  final fields = usedFields(readClass(element, unit.typeSystem), null);
  final names = {for (final f in fields) f.name};
  final selected = {
    for (final (name, at) in fieldNames(cls))
      if (length > 0 && at >= offset && at < offset + length) name,
  }.intersection(names);
  final member = id == 'equality' ? '==' : id;
  final ticked = selected.isNotEmpty
      ? selected
      : findMember(cls, member) != null
      ? usedBy(cls, element, member).intersection(names)
      : names;
  return {
    'fields': [
      for (final f in fields) {'name': f.name, 'type': f.type.code},
    ],
    'ticked': [
      for (final f in fields)
        if (ticked.contains(f.name)) f.name,
    ],
  };
}

/// The private fields of [cls] that have no public getter yet, with their
/// types, in declaration order.
List<(String, String)> _getterFields(
  ClassDeclaration cls,
  ClassElement element,
) {
  final seen = <String>{};
  return [
    for (final (name, _) in fieldNames(cls))
      if (name.startsWith('_') && seen.add(name))
        if (element.getField(name) case final field?)
          if (element.getGetter(publicName(name)) == null &&
              element.getMethod(publicName(name)) == null)
            (name, field.type.getDisplayString()),
  ];
}

/// Runs [action] as an explicit choice: a picker result, a quick fix or
/// "Generate data class". [fields] are the picked fields.
Future<Map<String, Object?>> generate(
  Document doc,
  Resolve resolve,
  String action,
  int offset,
  int length,
  List<String>? fields,
) async {
  if (action == 'dataClass') {
    return _composite(doc, resolve, offset, [
      for (final id in _steps.keys) (id, null),
    ]);
  }
  if (action == 'getter' && fields != null) {
    return _composite(doc, resolve, offset, [
      for (final f in fields) ('getter', f),
    ]);
  }
  final r = await doc.run(
    action,
    offset,
    length,
    anywhere: true,
    fields: fields?.toSet(),
  );
  return {
    'edits': _encode(r.edits),
    'replaces': r.regenerates || action == 'primaryConstructor',
    'skipped': [
      if (r.edits.isEmpty && r.disabled != null)
        '${_steps[action] ?? action}: ${r.disabled}',
    ],
  };
}

/// Runs [steps] one after another. Each step is an assist ID, with a field
/// name for a getter. The file is resolved again after each step. At the
/// end, the request's text goes back on the overlay. The result is one edit
/// over the changed span, which includes an import that a step adds at the
/// top of the file.
Future<Map<String, Object?>> _composite(
  Document doc,
  Resolve resolve,
  int offset,
  List<(String, String?)> steps,
) async {
  final before = doc.unit.content;
  // The class name: no step edits it, and only an import moves it.
  final start = _classAt(doc.unit, offset)?.namePart.typeName.offset;
  if (start == null) {
    return {
      'edits': const <Object?>[],
      'replaces': false,
      'skipped': const <Object?>[],
    };
  }
  var at = start;
  var text = before;
  var current = doc;
  var replaces = false;
  final skipped = <String>[];
  try {
    for (final (id, field) in steps) {
      var position = at;
      if (field != null) {
        final cls = _classAt(current.unit, at);
        final found = cls == null
            ? null
            : fieldNames(cls).where((f) => f.$1 == field).firstOrNull;
        if (found == null) {
          skipped.add('$field: the field is gone');
          continue;
        }
        position = found.$2;
      }
      final r = await current.run(id, position, 0, anywhere: true);
      if (r.edits.isEmpty) {
        skipped.add('${field ?? _steps[id]}: ${r.disabled ?? 'no edit'}');
        continue;
      }
      replaces |= r.regenerates;
      for (final e in r.edits) {
        if (e.offset + e.length <= at) at += e.replacement.length - e.length;
      }
      text = SourceEdit.applySequence(text, r.edits);
      final resolved = await resolve(text);
      if (resolved == null) break;
      current = Document(resolved.$1, resolved.$2, doc.eol, doc.onError);
    }
  } finally {
    // The overlay holds the last step's text. Other files must not see
    // members that the editor does not have, such as after a Discard.
    if (text != before) await resolve(before);
  }
  return {
    'edits': [if (text != before) _span(before, text)],
    'replaces': replaces,
    'skipped': skipped,
  };
}

ClassDeclaration? _classAt(ResolvedUnitResult unit, int offset) => unit.unit
    .nodeCovering(offset: offset)
    ?.thisOrAncestorOfType<ClassDeclaration>();

/// One edit from [before] to [after]: the span between their common prefix
/// and their common suffix.
Map<String, Object?> _span(String before, String after) {
  final most = min(before.length, after.length);
  var start = 0;
  while (start < most && before.codeUnitAt(start) == after.codeUnitAt(start)) {
    start++;
  }
  var end = 0;
  while (end < most - start &&
      before.codeUnitAt(before.length - 1 - end) ==
          after.codeUnitAt(after.length - 1 - end)) {
    end++;
  }
  return {
    'offset': start,
    'length': before.length - start - end,
    'text': after.substring(start, after.length - end),
  };
}
