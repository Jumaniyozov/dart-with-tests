import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final pence = FieldModel('pence', intType);

  test('a public validating factory wins over the private primary', () {
    final builder = chooseBuilder(
      [pence],
      [
        ConstructorModel('Money._', [
          ParamModel('pence', intType),
        ], isPublic: false),
        ConstructorModel('Money.fromPence', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder?.call, 'Money.fromPence');
  });

  test('the unnamed constructor goes before named ones', () {
    final builder = chooseBuilder(
      [pence],
      [
        ConstructorModel('Money.of', [ParamModel('pence', intType)]),
        ConstructorModel('Money', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder?.call, 'Money');
  });

  test('a factory with raw parameters is skipped for a named one', () {
    final category = FieldModel('category', stringType);
    final builder = chooseBuilder(
      [category, pence],
      [
        ConstructorModel('Limit', [
          ParamModel('raw', stringType, fitsField: false),
          ParamModel('pence', intType),
        ]),
        ConstructorModel('Limit.of', [
          ParamModel('category', stringType),
          ParamModel('pence', intType),
        ]),
      ],
    );
    expect(builder?.call, 'Limit.of');
  });

  test('a generative constructor of an abstract class is skipped', () {
    final builder = chooseBuilder(
      [pence],
      [
        ConstructorModel('Entry', [
          ParamModel('pence', intType),
        ], isCallable: false),
      ],
    );
    expect(builder, isNull);
  });

  test('state outside the constructor means no builder', () {
    final recorded = FieldModel(
      '_recorded',
      ListType('List<int>', intType),
      hasInitializer: true,
    );
    final builder = chooseBuilder(
      [pence, recorded],
      [
        ConstructorModel('Store', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder, isNull);
  });

  test('a late field with an initializer is not needed', () {
    final label = FieldModel(
      'label',
      stringType,
      isLate: true,
      hasInitializer: true,
    );
    final builder = chooseBuilder(
      [pence, label],
      [
        ConstructorModel('Tagged', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder?.call, 'Tagged');
  });

  test('a late field without an initializer is needed', () {
    final label = FieldModel('label', stringType, isLate: true);
    final builder = chooseBuilder(
      [pence, label],
      [
        ConstructorModel('Tagged', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder, isNull);
  });

  test('publicName drops one leading underscore', () {
    expect(publicName('_count'), 'count');
    expect(publicName('count'), 'count');
  });

  test('name drops type arguments', () {
    expect(ClassModel('Range<T>', [], null).name, 'Range');
  });

  test('a required parameter has no default value', () {
    expect(
      () => ParamModel('x', intType, defaultValue: '0'),
      throwsA(isA<AssertionError>()),
    );
  });
}
