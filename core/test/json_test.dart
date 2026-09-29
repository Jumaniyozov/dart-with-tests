import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final money = OtherType('Money');
  final kind = EnumType('Kind');

  test('keys are public names', () {
    final code = codeOf(
      generateJson(modelOf('Box', [FieldModel('_count', intType)])),
    );
    expect(code, contains("'count': _count"));
    expect(code, contains("'count': final int count"));
  });

  test('required keys go in the map pattern', () {
    final code = codeOf(
      generateJson(
        modelOf('Expense', [
          FieldModel('pence', intType),
          FieldModel('rate', DoubleType('double')),
          FieldModel('kind', kind),
          FieldModel('day', DateTimeType('DateTime')),
          FieldModel('amount', money),
        ]),
      ),
    );
    expect(code, contains("'pence': final int pence"));
    expect(code, contains("'rate': final num rate"));
    expect(code, contains('rate.toDouble()'));
    expect(code, contains("'kind': final String kind"));
    expect(code, contains('Kind.values.asNameMap()[kind] ?? (throw'));
    expect(code, contains('DateTime.tryParse(day) ?? (throw'));
    expect(code, contains("'amount': final Object amount"));
    expect(code, contains('Money.fromJson(amount)'));
    expect(code, contains("'kind': kind.name"));
    expect(code, contains("'day': day.toIso8601String()"));
    expect(code, contains("'amount': amount.toJson()"));
    expect(code, isNot(contains('final Map<String, Object?> map')));
  });

  test('nullable keys are read after the match', () {
    final code = codeOf(
      generateJson(
        modelOf('Expense', [
          FieldModel('pence', intType),
          FieldModel('note', noteType),
          FieldModel('tip', OtherType('Money?', isNullable: true)),
          FieldModel('raw', PassthroughType('Object?', isNullable: true)),
        ]),
      ),
    );
    expect(code, contains('final Map<String, Object?> map && {'));
    expect(
      code,
      contains(
        "switch (map['note']) { null => null, final String v => v, _ => throw",
      ),
    );
    expect(
      code,
      contains(
        "switch (map['tip']) { null => null, "
        'final Object v => Money.fromJson(v), }',
      ),
    );
    expect(code, contains("map['raw'],"));
    expect(code, contains("'tip': tip?.toJson()"));
  });

  test('a default keeps an explicit null', () {
    final model = ClassModel(
      'Bag',
      [
        FieldModel('label', noteType),
        FieldModel('seen', PrimitiveType('bool')),
      ],
      ConstructorModel('Bag', [
        ParamModel(
          'label',
          noteType,
          isNamed: true,
          isRequired: false,
          defaultValue: "'none'",
        ),
        ParamModel(
          'seen',
          PrimitiveType('bool'),
          isNamed: true,
          isRequired: false,
          defaultValue: 'false',
        ),
      ]),
    );
    final code = codeOf(generateJson(model));
    expect(code, contains("label: map.containsKey('label') ? switch"));
    expect(code, contains(": 'none'"));
    expect(
      code,
      contains(
        "seen: switch (map['seen']) { null => false, final bool v => v,",
      ),
    );
  });

  test('collections convert each element', () {
    final code = codeOf(
      generateJson(
        modelOf('Bag', [
          FieldModel('parts', ListType('List<Money>', money)),
          FieldModel('kinds', SetType('Set<Kind>', kind)),
          FieldModel(
            'prices',
            MapType('Map<String, Money>', stringType, money),
          ),
          FieldModel('tags', ListType('List<String?>', noteType)),
          FieldModel('names', SetType('Set<String>', stringType)),
        ]),
      ),
    );
    expect(code, contains("'parts': [for (final e in parts) e.toJson()]"));
    expect(code, contains('[for (final e in parts) Money.fromJson(e)]'));
    expect(
      code,
      contains('{for (final e in kinds) (e is String ? Kind.values'),
    );
    expect(code, contains('key: Money.fromJson(value)'));
    expect(code, contains("'tags': tags,"));
    expect(code, contains('e is String? ? e : throw'));
    expect(code, contains("'names': names.toList()"));
  });

  test('errors name the key and the class', () {
    final code = codeOf(
      generateJson(modelOf('Expense', [FieldModel('kind', kind)])),
    );
    expect(
      code,
      contains('''FormatException('Invalid "kind" in Expense JSON', json)'''),
    );
    expect(code, contains("FormatException('Invalid Expense JSON', json)"));
  });

  test('a key named map or json gets its own local', () {
    final code = codeOf(
      generateJson(modelOf('Odd', [FieldModel('map', intType)])),
    );
    expect(code, contains("'map': final int mapValue"));
  });

  group('not offered', () {
    test('noFields and noBuilder', () {
      expect(
        reasonOf(generateJson(ClassModel('Empty', [], null))),
        Reason.noFields,
      );
      final store = ClassModel('Store', [FieldModel('a', intType)], null);
      expect(reasonOf(generateJson(store)), Reason.noBuilder);
    });

    test('typeParameterField', () {
      final box = modelOf('Box<T>', [
        FieldModel('value', TypeParameterModel('T', isNullable: true)),
      ]);
      expect(reasonOf(generateJson(box)), Reason.typeParameterField);
    });

    test('nestedCollection', () {
      final grid = modelOf('Grid', [
        FieldModel(
          'rows',
          ListType('List<List<int>>', ListType('List<int>', intType)),
        ),
      ]);
      expect(reasonOf(generateJson(grid)), Reason.nestedCollection);
    });

    test('nonStringMapKey', () {
      final byDay = modelOf('ByDay', [
        FieldModel('totals', MapType('Map<int, int>', intType, intType)),
      ]);
      expect(reasonOf(generateJson(byDay)), Reason.nonStringMapKey);
    });
  });
}
