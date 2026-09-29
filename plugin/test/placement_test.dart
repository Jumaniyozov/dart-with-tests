import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_generate/src/placement.dart';
import 'package:test/test.dart';

/// [afterLine] for the first member of the first class in [source].
int afterFirstMember(String source) {
  final unit = parseString(content: source).unit;
  final cls = unit.declarations.first as ClassDeclaration;
  final member = cls.body.members.first;
  return afterLine(member, member.endToken);
}

void main() {
  test('a line comment after a field ends its line', () {
    const source =
        'class A {\n  final int a = 0; // note\n  final int b = 0;\n}\n';
    expect(afterFirstMember(source), source.indexOf('// note') + 7);
  });

  test('a doc comment after a field documents the next field', () {
    const source =
        'class A {\n  final int a = 0; /// Doc of b.\n  final int b = 0;\n}\n';
    expect(afterFirstMember(source), source.indexOf(';') + 1);
  });

  test('a comment on the next line is not part of the line', () {
    const source =
        'class A {\n  final int a = 0;\n  // b\n  final int b = 0;\n}\n';
    expect(afterFirstMember(source), source.indexOf(';') + 1);
  });

  test('a same-line block doc comment documents the next field', () {
    const source =
        'class A {\n  final int a = 0; /** Doc of b. */\n  final int b = 0;\n}\n';
    expect(afterFirstMember(source), source.indexOf(';') + 1);
  });
}
