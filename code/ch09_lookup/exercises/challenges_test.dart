import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — greeting a possible name', () {
    test('greets a real name', () {
      expect(greet('ada'), 'Hello, ada');
    });

    test('greets a stranger when there is no name', () {
      expect(greet(null), 'Hello, stranger');
      expect(greet(''), 'Hello, stranger');
      expect(greet('   '), 'Hello, stranger');
    });
  });

  group('challenge 2 — adding up what parses', () {
    test('adds the numbers and ignores the rest', () {
      expect(sumTyped(['10', 'x', '5']), 15);
      expect(sumTyped(['1', '2', '3']), 6);
    });

    test('nothing to add is zero', () {
      expect(sumTyped([]), 0);
      expect(sumTyped(['x', 'y']), 0);
    });
  });

  group('challenge 3 — a first character that may not exist', () {
    test('gives the first character', () {
      expect(initialOf('ada'), 'a');
    });

    test('gives nothing when there is no first character', () {
      expect(initialOf(null), isNull);
      expect(initialOf(''), isNull);
    });
  });
}
