import 'package:ch03_variables/tags.dart';
import 'package:test/test.dart';

void main() {
  test('turns a name into a tag', () {
    expect(tag('Dart'), '#dart');
  });
}
