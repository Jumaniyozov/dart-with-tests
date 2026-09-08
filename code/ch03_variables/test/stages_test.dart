// Proves the intermediate stages printed in the study really run.
import 'package:ch03_variables/v1.dart' as v1;
import 'package:ch03_variables/v2.dart' as v2;
import 'package:test/test.dart';

void main() {
  test('stage 1 prefixes the raw name', () {
    expect(v1.tag('dart'), '#dart');
  });

  test('stage 2 cleans the name first', () {
    expect(v2.tag('  Dart  '), '#dart');
    expect(v2.hashPrefix, '#');
  });
}
