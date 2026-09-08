import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — goodbye', () {
    test('says goodbye by name', () {
      expect(goodbye('Islom'), 'Goodbye, Islom');
    });

    test('says goodbye to the world when the name is empty', () {
      expect(goodbye(''), 'Goodbye, world');
    });
  });

  group('challenge 2 — German', () {
    test('greets in German', () {
      expect(hello('Islom', language: 'German'), 'Hallo, Islom');
    });

    test('still greets in the other languages', () {
      expect(hello('Islom'), 'Hello, Islom');
      expect(hello('Elodie', language: 'Spanish'), 'Hola, Elodie');
      expect(hello('Elodie', language: 'French'), 'Bonjour, Elodie');
    });
  });

  group('challenge 3 — whitespace', () {
    test('ignores whitespace around the name', () {
      expect(helloTrimmed('  Islom  '), 'Hello, Islom');
    });

    test('greets the world when the name is only whitespace', () {
      expect(helloTrimmed('   '), 'Hello, world');
    });
  });
}
