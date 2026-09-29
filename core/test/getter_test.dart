import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('a public getter returns the private field', () {
    expect(
      codeOf(generateGetter(FieldModel('_count', intType))),
      'int get count => _count;',
    );
  });

  test('a nullable type keeps its question mark', () {
    expect(
      codeOf(generateGetter(FieldModel('_note', noteType))),
      'String? get note => _note;',
    );
  });
}
