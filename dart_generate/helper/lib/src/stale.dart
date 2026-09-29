import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:dart_generate/assists.dart';
import 'package:generate_core/generate_core.dart';

/// The generated members that no longer cover every field (ADR 0008), or
/// `{skipped: true}` when the file has a syntax error.
Map<String, Object?> stale(ResolvedUnitResult unit) {
  if (unit.diagnostics.any(
    (d) => d.diagnosticCode.type == DiagnosticType.SYNTACTIC_ERROR,
  )) {
    return {'skipped': true};
  }
  return {
    'items': [
      for (final cls in unit.unit.declarations.whereType<ClassDeclaration>())
        ..._staleIn(cls, unit),
    ],
  };
}

List<Map<String, Object?>> _staleIn(
  ClassDeclaration cls,
  ResolvedUnitResult unit,
) {
  final element = cls.declaredFragment?.element;
  if (element == null) return const [];
  final model = readClass(element, unit.typeSystem);
  final all = [for (final f in usedFields(model, null)) f.name];
  final built = [
    for (final p in model.builder?.params ?? const <ParamModel>[]) p.name,
  ];
  final items = <Map<String, Object?>>[];

  void check(
    String name,
    String id,
    Outcome outcome,
    List<String> expected,
    String Function(String fields) message,
  ) {
    final member = findMember(cls, name);
    if (member == null || outcome is! Generated) return;
    final used = usedBy(cls, element, name);
    final missing = [
      for (final f in expected)
        if (!used.contains(f)) f,
    ];
    if (missing.isEmpty) return;
    final token = switch (member) {
      MethodDeclaration(name: final t) => t,
      ConstructorDeclaration(name: final t?) => t,
      _ => member.beginToken,
    };
    items.add({
      'offset': token.offset,
      'length': token.length,
      'id': id,
      'severity': id == 'toString' || id == 'equality' ? 'hint' : 'warning',
      'message': message(_join(missing)),
      'missing': missing,
    });
  }

  // customToString: a hand-written toString keeps its text and gets no mark.
  if (findMember(cls, 'toString') case final MethodDeclaration m
      when GenerateToString.isGenerated(m, model.name)) {
    check(
      'toString',
      'toString',
      generateToString(model),
      all,
      (f) => 'toString() does not show $f.',
    );
  }
  check(
    '==',
    'equality',
    generateEquality(model),
    all,
    (f) => '==() and hashCode do not use $f.',
  );
  final copyWith = generateCopyWith(model);
  check(
    'copyWith',
    'copyWith',
    copyWith,
    built,
    (f) => 'copyWith() does not cover $f.',
  );
  final json = generateJson(model);
  check('toJson', 'json', json, built, (f) => 'toJson() does not cover $f.');
  check(
    'fromJson',
    'json',
    json,
    built,
    (f) => 'fromJson() does not cover $f.',
  );
  return items;
}

/// The fields that the member named [name] references. For `==`, a field
/// counts only when hashCode uses it too.
Set<String> usedBy(ClassDeclaration cls, ClassElement element, String name) {
  Set<String> of(String name) {
    final member = findMember(cls, name);
    if (member == null) return const {};
    final visitor = _References(cls, element);
    member.accept(visitor);
    return visitor.names;
  }

  return name == '==' ? of('==').intersection(of('hashCode')) : of(name);
}

/// "a", "a and b", "a, b and c".
String _join(List<String> names) => names.length == 1
    ? names.single
    : '${names.take(names.length - 1).join(', ')} and ${names.last}';

/// Collects the fields of a class that a member references: a read of the
/// field or its getter, an argument to a `this.` or `super.` parameter, and a
/// field initializer in a constructor.
final class _References extends RecursiveAstVisitor<void> {
  _References(this._cls, this._element)
    : _owners = {_element, for (final t in _element.allSupertypes) t.element};

  final ClassDeclaration _cls;
  final ClassElement _element;

  /// The class and its supertypes. A field of another class does not count.
  final Set<InterfaceElement> _owners;
  final names = <String>{};

  /// The getters of the class whose bodies this visitor read.
  final _followed = <MethodDeclaration>{};

  void _add(FieldElement? field) {
    if (field == null || field.isStatic) return;
    if (!_owners.contains(field.enclosingElement)) return;
    if (field.name case final name?) names.add(name);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element case PropertyAccessorElement(
      variable: final FieldElement field,
    )) {
      _add(field);
      _follow(field);
    }
    super.visitSimpleIdentifier(node);
  }

  /// Reads the body of a getter that the class declares, once. So
  /// `int get pence => _pence;` makes a read of `pence` a read of `_pence`.
  void _follow(FieldElement field) {
    if (field.enclosingElement != _element) return;
    if (findMember(_cls, field.name ?? '') case final MethodDeclaration getter
        when getter.isGetter && _followed.add(getter)) {
      getter.body.accept(this);
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (final argument in node.arguments) {
      FormalParameterElement? p = argument.correspondingParameter;
      while (p is SuperFormalParameterElement) {
        p = p.superConstructorParameter;
      }
      if (p is FieldFormalParameterElement) _add(p.field);
    }
    super.visitArgumentList(node);
  }

  /// A field initializer in a constructor sets that field.
  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (node.fieldName.element case final FieldElement field) _add(field);
    super.visitConstructorFieldInitializer(node);
  }
}
