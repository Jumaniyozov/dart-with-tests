import 'dart:io';

import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

void main() {
  test('every reason has a row in the README', () {
    final readme = File('../README.md').readAsStringSync();
    for (final reason in Reason.values) {
      expect(readme, contains('| `${reason.name}` |'), reason: reason.name);
    }
  });

  test('the core owns six reasons and the adapter four', () {
    final byOwner = {
      for (final owner in Owner.values)
        owner: Reason.values.where((r) => r.owner == owner).length,
    };
    expect(byOwner, {Owner.core: 6, Owner.adapter: 4});
  });

  test('each reason has the message that the Generate… menu shows', () {
    expect(
      {for (final r in Reason.values) r.name: r.message},
      {
        'noFields': 'the class has no field that this action can use',
        'noBuilder': 'no public constructor covers every field',
        'mutableClass': 'a field is not final',
        'typeParameterField': 'a field has a type parameter type',
        'nestedCollection': 'a collection holds a collection',
        'nonStringMapKey': 'a map key is not String',
        'customToString': 'toString is hand-written',
        'notConvertible': 'the constructor cannot move into the class header',
        'publicNameTaken':
            'the class already has a member with the public name',
        'notAClass': 'the cursor is in an enum, a mixin or an extension type',
      },
    );
  });
}
