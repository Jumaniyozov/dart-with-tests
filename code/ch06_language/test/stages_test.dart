// Proves the intermediate stages printed in the study really run — including
// stage 1, whose whole problem is that it runs happily when it should not.
import 'package:ch06_language/v1.dart' as v1;
import 'package:ch06_language/v2.dart' as v2;
import 'package:test/test.dart';

void main() {
  test('stage 1 accepts a language that does not exist', () {
    expect(v1.hello('Elodie', language: 'Klingon'), 'Hello, Elodie');
  });

  test('stage 1 cannot tell a typo from a choice', () {
    expect(v1.hello('Elodie', language: 'spanish'), 'Hello, Elodie');
  });

  test('stage 2 knows three languages', () {
    expect(v2.hello('Elodie', language: .spanish), 'Hola, Elodie');
    expect(v2.Language.values.length, 3);
  });
}
