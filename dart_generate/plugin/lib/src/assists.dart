import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:generate_core/generate_core.dart';

import 'assist.dart';
import 'placement.dart';
import 'read_class.dart';

/// The suffix of every assist ID: `generate.<name>`. The e2e markers use the
/// same names.
const generatorNames = [
  'toString',
  'equality',
  'copyWith',
  'json',
  'getter',
  'primaryConstructor',
];

AssistKind _kind(String name, String message) =>
    AssistKind('generate.$name', 30, message);

final class GenerateToString extends GenerateAssist {
  GenerateToString({required super.context});

  @override
  AssistKind get assistKind => _kind('toString', '{0} toString()');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final target = classTarget();
    if (target == null) return;
    // customToString: a hand-written toString is domain text. Keep it.
    if (findMember(target.node, 'toString') case final MethodDeclaration m
        when !isGenerated(m, target.model.name)) {
      reason = Reason.customToString;
      return;
    }
    await write(
      draft,
      target.node,
      generateToString(target.model, only: target.only),
    );
  }

  /// Whether [method] returns `'ClassName(field: ...`, the generated shape.
  /// `'Money(${format()})'` starts like it, but it is hand-written.
  static bool isGenerated(MethodDeclaration method, String className) {
    final body = method.body;
    if (body is! ExpressionFunctionBody) return false;
    final generated = RegExp(
      '^[\'"]${RegExp.escape(className)}'
      r'\([\w$]+: ',
    );
    return generated.hasMatch(body.expression.toSource());
  }
}

final class GenerateEquality extends GenerateAssist {
  GenerateEquality({required super.context});

  @override
  AssistKind get assistKind => _kind('equality', '{0} ==() and hashCode');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final target = classTarget();
    if (target == null) return;
    await write(
      draft,
      target.node,
      generateEquality(target.model, only: target.only),
    );
  }
}

final class GenerateCopyWith extends GenerateAssist {
  GenerateCopyWith({required super.context});

  @override
  AssistKind get assistKind => _kind('copyWith', '{0} copyWith()');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final target = classTarget();
    if (target == null) return;
    final outcome = generateCopyWith(target.model);
    if (outcome is! Generated) {
      reason = (outcome as NotOffered).reason;
      return;
    }
    final cls = target.node;
    final old = findMember(cls, 'copyWith');
    final unset = findMember(cls, '_unset');
    final needsUnset = outcome.members.any((m) => m.name == '_unset');
    final drop =
        !needsUnset &&
        old != null &&
        unset != null &&
        !_usedElsewhere(cls, [unset, old]);
    await draft.addDartFileEdit(file, (b) {
      // The deletion goes through writeMembers, so its one format covers it.
      if (writeMembers(b, cls, outcome.members, delete: [if (drop) unset])) {
        verb = 'Regenerate';
      }
    });
  }

  /// Whether `_unset` appears in [cls] outside [skip].
  bool _usedElsewhere(ClassDeclaration cls, List<AstNode> skip) {
    final source = unitResult.content;
    for (final match in RegExp(r'\b_unset\b').allMatches(source)) {
      final at = match.start;
      if (at < cls.offset || at >= cls.end) continue;
      if (skip.any((n) => at >= n.offset && at < n.end)) continue;
      return true;
    }
    return false;
  }
}

final class GenerateJson extends GenerateAssist {
  GenerateJson({required super.context});

  @override
  AssistKind get assistKind => _kind('json', '{0} toJson() and fromJson()');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final target = classTarget();
    if (target == null) return;
    await write(draft, target.node, generateJson(target.model));
  }
}

final class GenerateGetter extends GenerateAssist {
  GenerateGetter({required super.context});

  @override
  AssistKind get assistKind => _kind('getter', 'Generate getter');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final cls = enclosingClass();
    final element = cls?.declaredFragment?.element;
    if (cls == null || element == null) return;

    // The field under the cursor: in the body, or declared in the header. In
    // a body declaration of one variable, the cursor can be anywhere in it,
    // such as on the type or on `final`.
    String? name;
    FieldDeclaration? declaration;
    final parameter = node.thisOrAncestorOfType<FormalParameter>();
    if (node.thisOrAncestorOfType<FieldDeclaration>() case final d?
        when !d.isStatic) {
      final variables = d.fields.variables;
      final variable = node.thisOrAncestorOfType<VariableDeclaration>();
      if (variable != null && variables.contains(variable)) {
        name = variable.name.lexeme;
      } else if (variables case [final only]) {
        name = only.name.lexeme;
      }
      declaration = d;
    } else if (parameter?.declaredFragment?.element
        case FieldFormalParameterElement(isDeclaring: true)) {
      name = parameter!.name?.lexeme;
    }
    if (name == null || !name.startsWith('_')) return;
    final field = element.getField(name);
    if (field == null) return;
    // publicNameTaken: the class already has this public name.
    final public = publicName(name);
    if (element.getGetter(public) != null ||
        element.getMethod(public) != null) {
      reason = Reason.publicNameTaken;
      return;
    }

    final code = generateGetter(
      FieldModel(name, readType(field.type, typeSystem)),
    ).members.single.code;
    await draft.addDartFileEdit(file, (b) {
      if (declaration != null) {
        insertAfter(b, declaration, code);
      } else {
        insertAtStart(b, cls, code);
      }
    });
  }
}

final class ConvertToPrimaryConstructor extends GenerateAssist {
  ConvertToPrimaryConstructor({required super.context});

  @override
  AssistKind get assistKind =>
      _kind('primaryConstructor', 'Convert to primary constructor');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final cls = enclosingClass();
    if (cls == null) return;
    if (!anywhereInClass &&
        (selectionOffset < cls.offset ||
            selectionOffset >= cls.body.beginToken.offset)) {
      return;
    }
    // notConvertible: a primary constructor exists, or the rules below
    // reject the class.
    final namePart = cls.namePart;
    final plan = namePart is NameWithTypeParameters ? _plan(cls) : null;
    if (namePart is! NameWithTypeParameters || plan == null) {
      reason = Reason.notConvertible;
      return;
    }
    final (:constructor, :params, :moved) = plan;

    final content = unitResult.content;
    await draft.addDartFileEdit(file, (b) {
      b.addSimpleReplacement(
        SourceRange(namePart.offset, namePart.length),
        primaryHeader(
          namePart.typeName.lexeme,
          params,
          typeParameters: namePart.typeParameters?.toSource() ?? '',
          isConst: constructor.constKeyword != null,
        ),
      );
      for (final member in [...moved, constructor]) {
        // A moved field takes the comment at the end of its line with it.
        final end = member is FieldDeclaration
            ? afterLine(member, member.endToken)
            : member.end;
        b.addDeletion(SourceRange(member.offset, end - member.offset));
      }
      if (constructor.documentationComment case final doc?) {
        final text = content.substring(doc.offset, doc.end);
        if (cls.documentationComment case final classDoc?) {
          b.addSimpleInsertion(classDoc.end, '\n///\n$text');
        } else {
          b.addSimpleInsertion(cls.offset, '$text\n');
        }
      }
      b.format(SourceRange(cls.offset, cls.length));
    });
  }

  /// The constructor to remove, the header parameters, and the fields that
  /// move into the header. `null` when the class is not convertible.
  ({
    ConstructorDeclaration constructor,
    List<HeaderParam> params,
    List<FieldDeclaration> moved,
  })?
  _plan(ClassDeclaration cls) {
    final generative = [
      for (final m in cls.body.members)
        if (m is ConstructorDeclaration && m.factoryKeyword == null) m,
    ];
    if (generative.length != 1) return null;
    final constructor = generative.single;
    if (constructor.name != null ||
        constructor.metadata.isNotEmpty ||
        constructor.initializers.isNotEmpty ||
        constructor.externalKeyword != null ||
        constructor.body is! EmptyFunctionBody) {
      return null;
    }

    final fields = {
      for (final m in cls.body.members)
        if (m is FieldDeclaration && !m.isStatic)
          for (final v in m.fields.variables) v.name.lexeme: m,
    };
    final params = <HeaderParam>[];
    final moved = <FieldDeclaration>{};
    for (final p in constructor.parameters.parameters) {
      if (p.functionTypedSuffix != null) return null;
      final defaultValue = p.declaredFragment?.element.defaultValueCode;
      switch (p) {
        case FieldFormalParameter(:final name):
          final declaration = fields[name.lexeme];
          if (declaration == null) return null;
          final list = declaration.fields;
          if (list.isLate || list.variables.any((v) => v.initializer != null)) {
            return null;
          }
          moved.add(declaration);
          params.add(
            HeaderParam(
              name.lexeme,
              type:
                  list.type?.toSource() ??
                  p.declaredFragment!.element.type.getDisplayString(),
              isFinal: list.isFinal,
              isNamed: p.isNamed,
              isOptionalPositional: p.isOptionalPositional,
              isRequired: p.isRequiredNamed,
              defaultValue: defaultValue,
              metadata: [
                _metadata(declaration),
                _metadata(p),
              ].where((m) => m.isNotEmpty).join('\n'),
              // The comment after the declaration follows its last variable.
              comment: name.lexeme == list.variables.last.name.lexeme
                  ? _trailingComment(declaration)
                  : '',
            ),
          );
        case SuperFormalParameter(:final name):
          params.add(
            HeaderParam(
              name.lexeme,
              isNamed: p.isNamed,
              isOptionalPositional: p.isOptionalPositional,
              isRequired: p.isRequiredNamed,
              defaultValue: defaultValue,
              metadata: _metadata(p),
            ),
          );
        default:
          return null;
      }
    }
    // A declaration with two variables moves only if both move.
    final names = {for (final p in params) p.name};
    for (final d in moved) {
      if (!d.fields.variables.every((v) => names.contains(v.name.lexeme))) {
        return null;
      }
    }
    return (constructor: constructor, params: params, moved: moved.toList());
  }

  /// The comment that ends the line of [field], as written, or `''`.
  String _trailingComment(FieldDeclaration field) => unitResult.content
      .substring(field.end, afterLine(field, field.endToken))
      .trim();

  /// The doc comment and annotations of [node], as written.
  String _metadata(AnnotatedNode node) => unitResult.content
      .substring(node.offset, node.firstTokenAfterCommentAndMetadata.offset)
      .trim();
}
