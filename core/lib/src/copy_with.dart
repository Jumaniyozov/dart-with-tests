import 'model.dart';
import 'outcome.dart';

/// `copyWith` that calls the builder. A nullable parameter uses the `_unset`
/// sentinel, so `copyWith(note: null)` clears the field.
Outcome generateCopyWith(ClassModel model) {
  if (model.fields.isEmpty) return NotOffered(Reason.noFields);
  final builder = model.builder;
  if (builder == null) return NotOffered(Reason.noBuilder);
  if (builder.params.isEmpty) return NotOffered(Reason.noFields);

  final params = <String>[];
  final args = <String>[];
  for (final p in builder.params) {
    final name = publicName(p.name);
    final field = name == p.name ? 'this.${p.name}' : p.name;
    final String value;
    if (p.type.isNullable) {
      params.add('Object? $name = _unset');
      final cast = p.type is PassthroughType ? '' : ' as ${p.type.code}';
      value = 'identical($name, _unset) ? $field : $name$cast';
    } else {
      params.add('${p.type.base}? $name');
      value = '$name ?? $field';
    }
    args.add(p.isNamed ? '$name: $value' : value);
  }
  return Generated([
    if (builder.params.any((p) => p.type.isNullable))
      Member('_unset', 'static const _unset = Object();'),
    Member(
      'copyWith',
      '${model.type} copyWith({${params.join(', ')},}) => '
          '${builder.call}(${args.join(', ')},);',
    ),
  ]);
}
