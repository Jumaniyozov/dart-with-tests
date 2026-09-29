import 'model.dart';
import 'outcome.dart';
import 'to_string.dart';

const _collection = 'package:collection/collection.dart';

/// `operator ==` and `hashCode`. Offered only when every field is `final`.
Outcome generateEquality(ClassModel model, {Set<String>? only}) {
  if (model.fields.any((f) => !f.isFinal)) {
    return NotOffered(Reason.mutableClass);
  }
  final fields = usedFields(model, only);
  if (fields.isEmpty) return NotOffered(Reason.noFields);

  final checks = [
    for (final f in fields)
      _isCollection(f.type)
          ? 'const DeepCollectionEquality().equals(other.${f.name}, ${_own(f)})'
          : 'other.${f.name} == ${_own(f)}',
  ];
  final hashes = [
    for (final f in fields)
      _isCollection(f.type)
          ? 'const DeepCollectionEquality().hash(${f.name})'
          : f.name,
  ];
  final hash = switch (hashes.length) {
    1 when !_isCollection(fields.single.type) => '${hashes.single}.hashCode',
    1 => hashes.single,
    <= 20 => 'Object.hash(${hashes.join(', ')},)',
    _ => 'Object.hashAll([${hashes.join(', ')},])',
  };
  return Generated(
    [
      Member(
        '==',
        '@override\nbool operator ==(Object other) => '
            'other is ${model.type} && ${checks.join(' && ')};',
      ),
      Member('hashCode', '@override\nint get hashCode => $hash;'),
    ],
    imports: [if (fields.any((f) => _isCollection(f.type))) _collection],
  );
}

/// The field [f] as `==` reads it. `other` is also the parameter of `==`, so
/// a field with that name needs `this.`.
String _own(FieldModel f) => f.name == 'other' ? 'this.other' : f.name;

bool _isCollection(TypeModel type) =>
    type is ListType || type is SetType || type is MapType;
