import 'package:ch02_greeting/greeting.dart';
import 'package:test/test.dart';

void main() {
  group('hello', () {
    test('greets a person in English by default', () {
      expect(hello('Islom'), 'Hello, Islom');
    });

    test('greets the world when the name is empty', () {
      expect(hello(''), 'Hello, world');
    });

    test('greets in Spanish', () {
      expect(hello('Elodie', language: 'Spanish'), 'Hola, Elodie');
    });

    test('greets in French', () {
      expect(hello('Elodie', language: 'French'), 'Bonjour, Elodie');
    });

    test('falls back to English for an unknown language', () {
      expect(hello('Elodie', language: 'Klingon'), 'Hello, Elodie');
    });
  });
}
