import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('a nullable field uses the sentinel and a cast', () {
    final model = modelOf('Expense', [
      FieldModel('pence', intType),
      FieldModel('note', noteType),
    ]);
    final outcome = generateCopyWith(model) as Generated;
    expect(outcome.members.map((m) => m.name), ['_unset', 'copyWith']);
    final code = codeOf(outcome);
    expect(code, contains('int? pence'));
    expect(code, contains('Object? note = _unset'));
    expect(code, contains('pence ?? this.pence'));
    expect(
      code,
      contains('identical(note, _unset) ? this.note : note as String?'),
    );
  });

  test('a type parameter with a nullable bound uses the sentinel', () {
    final model = modelOf('Box<T>', [
      FieldModel('value', TypeParameterModel('T', isNullable: true)),
    ]);
    final code = codeOf(generateCopyWith(model));
    expect(code, contains('Box<T> copyWith({Object? value = _unset,})'));
    expect(code, contains('value as T'));
  });

  test('Object? needs no cast', () {
    final model = modelOf('Raw', [
      FieldModel('raw', PassthroughType('Object?', isNullable: true)),
    ]);
    expect(
      codeOf(generateCopyWith(model)),
      contains('identical(raw, _unset) ? this.raw : raw,'),
    );
  });

  test('a private parameter gets a public name', () {
    final model = modelOf('Box', [FieldModel('_count', intType)]);
    final code = codeOf(generateCopyWith(model));
    expect(code, contains('int? count'));
    expect(code, contains('count ?? _count'));
  });

  test('named parameters stay named, and the builder is called', () {
    final model = ClassModel(
      'Money',
      [FieldModel('pence', intType)],
      ConstructorModel('Money.fromPence', [
        ParamModel('pence', intType, isNamed: true),
      ]),
    );
    expect(
      codeOf(generateCopyWith(model)),
      contains('Money.fromPence(pence: pence ?? this.pence,)'),
    );
  });

  test('noFields and noBuilder', () {
    expect(
      reasonOf(generateCopyWith(ClassModel('Empty', [], null))),
      Reason.noFields,
    );
    final store = ClassModel('Store', [FieldModel('a', intType)], null);
    expect(reasonOf(generateCopyWith(store)), Reason.noBuilder);
  });
}
