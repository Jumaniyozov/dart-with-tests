import 'model.dart';
import 'outcome.dart';

/// A public getter for a private field: `int get count => _count;`.
///
/// The plugin checks the cursor and a name clash before it calls this.
Generated generateGetter(FieldModel field) {
  final name = publicName(field.name);
  return Generated([
    Member(name, '${field.type.code} get $name => ${field.name};'),
  ]);
}
