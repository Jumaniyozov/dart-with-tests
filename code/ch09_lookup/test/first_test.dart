import 'package:ch09_lookup/lookup.dart';
import 'package:test/test.dart';

void main() {
  test('a name in the directory has an extension', () {
    expect(extensionFor('ada'), 101);
  });

  test('a name that is not in the directory has nothing', () {
    expect(extensionFor('mallory'), isNull);
  });
}
