import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — dashes', () {
    test('replaces inner spaces with dashes', () {
      expect(slugTag('Hello World'), '#hello-world');
    });

    test('still trims, lowercases and handles blanks', () {
      expect(slugTag('  Hello World  '), '#hello-world');
      expect(slugTag('   '), '#untitled');
    });
  });

  group('challenge 2 — a maximum length', () {
    test('cuts a long body to twelve characters', () {
      expect(shortTag('extraordinarily long'), '#extraordina');
    });

    test('leaves a short body alone', () {
      expect(shortTag('dart'), '#dart');
    });
  });

  group('challenge 3 — visible characters', () {
    test('ignores spaces', () {
      expect(visibleLength('a b c'), 3);
    });

    test('counts nothing in a blank string', () {
      expect(visibleLength('   '), 0);
    });
  });
}
