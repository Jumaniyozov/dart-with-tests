import 'package:ch06_language/language.dart';
import 'package:test/test.dart';

void main() {
  test('greets in Spanish when asked', () {
    expect(hello('Elodie', language: .spanish), 'Hola, Elodie');
  });
}
