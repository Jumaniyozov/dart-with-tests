import 'model.dart';
import 'outcome.dart';

/// `toJson()` and `factory X.fromJson(Object? json)` over the builder
/// parameters. Keys are the public parameter names.
Outcome generateJson(ClassModel model) {
  if (model.fields.isEmpty) return NotOffered(Reason.noFields);
  final builder = model.builder;
  if (builder == null) return NotOffered(Reason.noBuilder);
  if (builder.params.isEmpty) return NotOffered(Reason.noFields);
  for (final p in builder.params) {
    if (_unsupported(p.type) case final reason?) return NotOffered(reason);
  }
  return Generated([
    Member('toJson', _toJson(builder)),
    Member('fromJson', _Reader(model.name, builder).fromJson()),
  ]);
}

Reason? _unsupported(TypeModel type) => switch (type) {
  TypeParameterModel() => Reason.typeParameterField,
  ListType(:final element) || SetType(:final element) => _inner(element),
  MapType(:final key) when key.code != 'String' => Reason.nonStringMapKey,
  MapType(:final value) => _inner(value),
  _ => null,
};

Reason? _inner(TypeModel type) => switch (type) {
  TypeParameterModel() => Reason.typeParameterField,
  ListType() || SetType() || MapType() => Reason.nestedCollection,
  _ => null,
};

String _toJson(ConstructorModel builder) {
  final entries = [
    for (final p in builder.params)
      '${_quote(publicName(p.name))}: ${_write(p.name, p.type)}',
  ];
  return 'Map<String, Object?> toJson() => {${entries.join(', ')},};';
}

/// The JSON value of [v], an expression of [type].
String _write(String v, TypeModel type) {
  final q = type.isNullable ? '?' : '';
  return switch (type) {
    EnumType() => '$v$q.name',
    DateTimeType() => '$v$q.toIso8601String()',
    OtherType() => '$v$q.toJson()',
    ListType(:final element) || SetType(:final element) when !_asIs(element) =>
      type.isNullable
          ? '$v?.map((e) => ${_write('e', element)}).toList()'
          : '[for (final e in $v) ${_write('e', element)}]',
    SetType() => '$v$q.toList()',
    MapType(:final value) when !_asIs(value) =>
      type.isNullable
          ? '$v?.map((key, value) => MapEntry(key, ${_write('value', value)}))'
          : '{for (final MapEntry(:key, :value) in $v.entries) '
                'key: ${_write('value', value)}}',
    _ => v,
  };
}

/// Whether JSON carries values of [type] unchanged.
bool _asIs(TypeModel type) =>
    type is PrimitiveType || type is DoubleType || type is PassthroughType;

String _quote(String text) => "'${_escape(text)}'";

/// [text] with each `$` escaped, for use inside a string literal.
String _escape(String text) => text.replaceAll(r'$', r'\$');

/// Builds the fromJson text for one class.
final class _Reader(final String className, final ConstructorModel builder) {
  String fromJson() {
    final entries = <String>[];
    final args = <String>[];
    var needsMap = false;
    for (final p in builder.params) {
      final key = publicName(p.name);
      final String value;
      if (p.type.isNullable || p.defaultValue != null) {
        needsMap = true;
        value = _optional(key, p.type, p.defaultValue);
      } else {
        final local = _local(key);
        entries.add('${_quote(key)}: final ${_pattern(p.type)} $local');
        value = _convert(local, p.type, key);
      }
      args.add(p.isNamed ? '$key: $value' : value);
    }
    final head = [
      if (needsMap) 'final Map<String, Object?> map',
      if (entries.isNotEmpty) '{${entries.join(', ')},}',
    ].join(' && ');
    return 'factory $className.fromJson(Object? json) => switch (json) {'
        '$head => ${builder.call}(${args.join(', ')},),'
        "_ => throw FormatException('Invalid $className JSON', json),"
        '};';
  }

  /// A key that can be missing or `null`: read after the match.
  String _optional(String key, TypeModel type, String? defaultValue) {
    final read = 'map[${_quote(key)}]';
    final String value;
    if (type is PassthroughType) {
      value = read;
    } else {
      final pattern = _pattern(type);
      final fallback = pattern == 'Object' ? '' : ', _ => throw ${_error(key)}';
      final onNull = type.isNullable ? 'null' : defaultValue!;
      value =
          'switch ($read) { null => $onNull, '
          'final $pattern v => ${_convert('v', type, key)}$fallback, }';
    }
    if (!type.isNullable || defaultValue == null) return value;
    return 'map.containsKey(${_quote(key)}) ? $value : $defaultValue';
  }

  /// The type to match for a present, non-null value of [type].
  String _pattern(TypeModel type) => switch (type) {
    PrimitiveType() => type.base,
    DoubleType() => 'num',
    PassthroughType() || OtherType() => 'Object',
    DateTimeType() || EnumType() => 'String',
    ListType() || SetType() => 'List<Object?>',
    MapType() => 'Map<String, Object?>',
    TypeParameterModel() => throw StateError('JSON is not offered for $type'),
  };

  /// Converts [v], already matched with [_pattern], to [type].
  String _convert(String v, TypeModel type, String key) => switch (type) {
    DoubleType() => '$v.toDouble()',
    DateTimeType() => 'DateTime.tryParse($v) ?? (throw ${_error(key)})',
    EnumType() =>
      '${type.base}.values.asNameMap()[$v] ?? (throw ${_error(key)})',
    OtherType() => '${type.base}.fromJson($v)',
    ListType(:final element) =>
      '[for (final e in $v) ${_element('e', element, key)}]',
    SetType(:final element) =>
      '{for (final e in $v) ${_element('e', element, key)}}',
    MapType(:final value) =>
      '{for (final MapEntry(:key, :value) in $v.entries) '
          'key: ${_element('value', value, key)}}',
    _ => v,
  };

  /// Converts [v], an `Object?` element of a collection, to [type].
  String _element(String v, TypeModel type, String key) {
    final error = _error(key);
    final String present = switch (type) {
      PrimitiveType() => '$v is ${type.code} ? $v : throw $error',
      DoubleType() when type.isNullable =>
        '$v is num? ? $v?.toDouble() : throw $error',
      DoubleType() => '$v is num ? $v.toDouble() : throw $error',
      PassthroughType() when type.isNullable => v,
      PassthroughType() => '$v ?? (throw $error)',
      DateTimeType() =>
        '($v is String ? DateTime.tryParse($v) : null) ?? (throw $error)',
      EnumType() =>
        '($v is String ? ${type.base}.values.asNameMap()[$v] : null) '
            '?? (throw $error)',
      OtherType() => '${type.base}.fromJson($v)',
      _ => throw StateError('JSON is not offered for $type'),
    };
    final nullCheck =
        type is DateTimeType || type is EnumType || type is OtherType;
    return type.isNullable && nullCheck
        ? '$v == null ? null : $present'
        : present;
  }

  String _error(String key) =>
      "FormatException('Invalid \"${_escape(key)}\" "
      "in $className JSON', json)";

  /// The local that binds a required key. `json` and `map` are taken.
  String _local(String key) =>
      key == 'json' || key == 'map' ? '${key}Value' : key;
}
