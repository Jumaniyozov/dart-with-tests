import 'dart:io';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:generate_core/generate_core.dart';

import 'placement.dart';
import 'read_class.dart';

/// The base of every dart_generate assist.
///
/// A failure stays inside its own assist (ADR 0006): the edit is built in a
/// draft, and only a finished draft reaches the server's builder. Every error
/// except `InconsistentAnalysisException` goes to the log, and the menu shows
/// the other actions.
abstract class GenerateAssist extends ResolvedCorrectionProducer {
  GenerateAssist({required super.context});

  /// `Generate`, or `Regenerate` when a member already exists.
  String verb = 'Generate';

  /// The fields for toString and `==`, in place of the fields that the
  /// selection covers. The VS Code helper sets it from its field picker.
  Set<String>? fields;

  /// Whether any position inside the class counts, not only the header, a
  /// field or a selection. The VS Code helper sets it for an explicit choice.
  bool anywhereInClass = false;

  /// Why the action gives no edit. `null` when it gives an edit, or when it
  /// does not apply at this position.
  Reason? reason;

  /// Receives a failure. The VS Code helper writes it to stderr.
  void Function(String generator, String file, Object error, StackTrace stack)
  onError = writeLog;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  List<String> get assistArguments => [verb];

  /// Adds the edit to [draft], or returns without one when the action does
  /// not apply here.
  Future<void> generate(ChangeBuilder draft);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    try {
      final draft = ChangeBuilder(
        session: unitResult.session,
        defaultEol: builder.defaultEol,
      );
      await generate(draft);
      for (final fileEdit in draft.sourceChange.edits) {
        await builder.addDartFileEdit(fileEdit.file, (b) {
          for (final e in fileEdit.edits) {
            b.addSimpleReplacement(
              SourceRange(e.offset, e.length),
              e.replacement,
            );
          }
        });
      }
    } on InconsistentAnalysisException {
      rethrow;
    } catch (error, stack) {
      // This includes ConflictingEditException. The edits are built in the
      // draft, so a conflict comes from our own placement code: our bug.
      onError(assistKind!.id, file, error, stack);
    }
  }

  /// The class whose header or field the cursor is on, with its model.
  ///
  /// `null` when the cursor is anywhere else, or in an enum, mixin or
  /// extension type (`notAClass`). With [anywhereInClass], any position in
  /// the class counts.
  ClassTarget? classTarget() {
    final cls = enclosingClass();
    if (cls == null) return null;
    final element = cls.declaredFragment?.element;
    if (element == null) return null;
    final names = fieldNames(cls);
    final selected = selectionLength == 0
        ? null
        : {
            for (final (name, offset) in names)
              if (offset >= selectionOffset && offset < selectionEnd) name,
          };
    final bodyStart = cls.body.beginToken.offset;
    final onHeader =
        selectionOffset >= cls.offset && selectionOffset < bodyStart;
    final onField = node.thisOrAncestorOfType<FieldDeclaration>() != null;
    final onSelection = selected != null && selected.isNotEmpty;
    if (!anywhereInClass && !onHeader && !onField && !onSelection) return null;
    return ClassTarget(
      cls,
      readClass(element, typeSystem),
      fields ?? (onSelection ? selected : null),
    );
  }

  /// The class around the cursor, or `null`. In an enum, a mixin or an
  /// extension type, it sets [reason] to `notAClass`.
  ClassDeclaration? enclosingClass() {
    final cls = node.thisOrAncestorOfType<ClassDeclaration>();
    if (cls == null &&
        node.thisOrAncestorMatching(
              (n) =>
                  n is EnumDeclaration ||
                  n is MixinDeclaration ||
                  n is ExtensionTypeDeclaration,
            ) !=
            null) {
      reason = Reason.notAClass;
    }
    return cls;
  }

  /// Writes [outcome] into [cls] and sets [verb], or sets [reason].
  Future<void> write(
    ChangeBuilder draft,
    ClassDeclaration cls,
    Outcome outcome,
  ) async {
    switch (outcome) {
      case Generated(:final members, :final imports):
        await draft.addDartFileEdit(file, (b) {
          if (writeMembers(b, cls, members)) verb = 'Regenerate';
          for (final uri in imports) {
            b.importLibrary(Uri.parse(uri));
          }
        });
      case NotOffered(reason: final why):
        reason = why;
    }
  }
}

/// The class an action works on.
final class ClassTarget(
  final ClassDeclaration node,
  final ClassModel model,

  /// The names of the fields that the selection covers, or `null`.
  final Set<String>? only,
);

/// The name and name offset of each field of the class: body fields, header
/// fields, and header `this.` and `super.` parameters. A plain header
/// parameter is not a field.
List<(String, int)> fieldNames(ClassDeclaration cls) => [
  if (cls.namePart case PrimaryConstructorDeclaration(:final formalParameters))
    for (final p in formalParameters.parameters)
      if (p.name case final name?)
        if (p.declaredFragment?.element
            case FieldFormalParameterElement() || SuperFormalParameterElement())
          (name.lexeme, name.offset),
  for (final member in cls.body.members)
    if (member is FieldDeclaration && !member.isStatic)
      for (final v in member.fields.variables) (v.name.lexeme, v.name.offset),
];

/// Appends a failure to the log, and empties the log when it passes 1 MB.
///
/// The path is `DART_GENERATE_LOG`, or `~/.dartServer/dart_generate.log`.
void writeLog(String generator, String file, Object error, StackTrace stack) {
  try {
    final env = Platform.environment;
    final path =
        env['DART_GENERATE_LOG'] ??
        '${env['HOME']}/.dartServer/dart_generate.log';
    final log = File(path);
    if (log.existsSync() && log.lengthSync() > 1024 * 1024) {
      log.writeAsStringSync('');
    }
    log.writeAsStringSync(
      '${DateTime.now().toIso8601String()} $generator $file\n$error\n$stack\n',
      mode: FileMode.append,
    );
  } on FileSystemException {
    // The log is best effort. A failure here must not hide the other actions.
  }
}
