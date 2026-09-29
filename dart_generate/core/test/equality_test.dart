import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('one field hashes with hashCode', () {
    final model = modelOf('Money', [FieldModel('pence', intType)]);
    final code = codeOf(generateEquality(model));
    expect(code, contains('other is Money && other.pence == pence'));
    expect(code, contains('int get hashCode => pence.hashCode;'));
  });

  test('the type check keeps type arguments', () {
    final model = modelOf('Range<T>', [
      FieldModel('low', TypeParameterModel('T')),
    ]);
    expect(codeOf(generateEquality(model)), contains('other is Range<T> &&'));
  });

  test('a collection uses DeepCollectionEquality and adds the import', () {
    final model = modelOf('Tagged', [
      FieldModel('id', stringType),
      FieldModel('tags', ListType('List<String>', stringType)),
    ]);
    final outcome = generateEquality(model) as Generated;
    expect(outcome.imports, ['package:collection/collection.dart']);
    final code = codeOf(outcome);
    expect(
      code,
      contains('const DeepCollectionEquality().equals(other.tags, tags)'),
    );
    expect(
      code,
      contains('Object.hash(id, const DeepCollectionEquality().hash(tags),)'),
    );
  });

  test('a field named other is read through this', () {
    // `other` is also the parameter of ==, so a bare `other` is the parameter.
    final scalar = modelOf('Link', [FieldModel('other', intType)]);
    expect(
      codeOf(generateEquality(scalar)),
      contains('other is Link && other.other == this.other;'),
    );
    final collection = modelOf('Links', [
      FieldModel('other', ListType('List<String>', stringType)),
    ]);
    expect(
      codeOf(generateEquality(collection)),
      contains(
        'const DeepCollectionEquality().equals(other.other, this.other)',
      ),
    );
  });

  test('more than 20 fields use Object.hashAll', () {
    final model = modelOf('Wide', [
      for (var i = 0; i < 21; i++) FieldModel('f$i', intType),
    ]);
    expect(codeOf(generateEquality(model)), contains('Object.hashAll(['));
  });

  test('mutableClass', () {
    final counter = modelOf('Counter', [
      FieldModel('count', intType, isFinal: false),
    ]);
    expect(reasonOf(generateEquality(counter)), Reason.mutableClass);
  });

  test('noFields', () {
    expect(
      reasonOf(generateEquality(ClassModel('Empty', [], null))),
      Reason.noFields,
    );
  });
}
