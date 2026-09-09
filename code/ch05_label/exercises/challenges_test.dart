import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — initials', () {
    test('takes the first letter of each word', () {
      expect(initials('Ada Lovelace'), 'AL');
      expect(initials('grace brewster murray hopper'), 'GBMH');
    });

    test('copes with one word and with double spaces', () {
      expect(initials('Prince'), 'P');
      expect(initials('Ada  Lovelace'), 'AL');
    });
  });

  group('challenge 2 — padding to a width', () {
    test('pads plain text', () {
      expect(padTo('Hi', 5), 'Hi   ');
    });

    test('counts an emoji as one character wide', () {
      expect(padTo('👋', 3), '👋  ');
    });

    test('leaves text that is already wide enough', () {
      expect(padTo('Hello', 3), 'Hello');
    });
  });

  group('challenge 3 — reversing', () {
    test('reverses plain text', () {
      expect(reverse('abc'), 'cba');
      expect(reverse(''), '');
    });

    test('keeps an emoji whole', () {
      expect(reverse('ab👋'), '👋ba');
    });
  });
}
