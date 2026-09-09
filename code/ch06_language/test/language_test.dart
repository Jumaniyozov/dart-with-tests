import 'package:ch06_language/language.dart';
import 'package:test/test.dart';

void main() {
  group('hello', () {
    test('greets in English by default', () {
      expect(hello('Islom'), 'Hello, Islom');
    });

    test('greets in each language it knows', () {
      expect(hello('Elodie', language: .spanish), 'Hola, Elodie');
      expect(hello('Elodie', language: .french), 'Bonjour, Elodie');
      expect(hello('Elodie', language: .german), 'Hallo, Elodie');
    });

    test('greets the world when the name is blank', () {
      expect(hello('   ', language: .german), 'Hallo, world');
    });
  });

  // #region values
  group('Language', () {
    test('knows how many languages there are', () {
      expect(Language.values.length, 4);
    });

    test('carries its own name as written in the source', () {
      expect(Language.german.name, 'german');
    });

    test('numbers its members from zero, in declaration order', () {
      expect(Language.english.index, 0);
      expect(Language.german.index, 3);
    });
  });
  // #endregion values
}
