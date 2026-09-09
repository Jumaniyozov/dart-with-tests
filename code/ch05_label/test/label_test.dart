import 'package:ch05_label/label.dart';
import 'package:test/test.dart';

/// `café` written as `e` followed by a combining acute accent, not as the
/// single code point. Both look identical on screen.
const decomposed = 'café';

void main() {
  group('truncate', () {
    test('leaves a label that already fits', () {
      expect(truncate('Hello', 5), 'Hello');
      expect(truncate('Hi', 5), 'Hi');
    });

    test('cuts a long label and marks the cut', () {
      expect(truncate('Hello world', 5), 'Hello…');
    });

    test('never leaves half an emoji', () {
      expect(truncate('Hi 👋 there', 4), 'Hi 👋…');
    });

    test('never leaves half a flag', () {
      expect(truncate('Go 🇬🇧 now', 4), 'Go 🇬🇧…');
    });

    test('never separates a letter from its accent', () {
      // The result keeps the form the input used. `truncate` cuts; it does
      // not normalise, so a decomposed accent stays decomposed.
      expect(truncate('$decomposed latte', 4), '$decomposed…');
    });
  });

  // #region widths
  group('widths', () {
    test('all three agree on plain ascii', () {
      expect(widths('cafe'), '4 4 4');
    });

    test('an emoji is two units, one code point, one character', () {
      expect(widths('👋'), '2 1 1');
    });

    test('a flag is four units, two code points, one character', () {
      expect(widths('🇬🇧'), '4 2 1');
    });

    test('a combining accent adds a code point but not a character', () {
      expect(widths(decomposed), '5 5 4');
    });
  });
  // #endregion widths
}
