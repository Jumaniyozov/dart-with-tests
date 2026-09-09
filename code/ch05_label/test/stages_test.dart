// Proves the intermediate stages printed in the study really run — including
// the two that are wrong. Every claim the prose makes about them is asserted
// here, so the prose cannot quietly stop being true.
import 'package:ch05_label/label.dart' as final_;
import 'package:ch05_label/v1.dart' as v1;
import 'package:ch05_label/v2.dart' as v2;
import 'package:test/test.dart';

const emoji = 'Hi 👋 there';
const flag = 'Go 🇬🇧 now';

void main() {
  test('stage 1 cuts an emoji in half', () {
    final cut = v1.truncate(emoji, 4);
    expect(cut, isNot('Hi 👋…'));
    expect(cut.codeUnitAt(3), 55357, reason: 'half of a surrogate pair, alone');
  });

  test('stage 2 keeps the emoji whole', () {
    expect(v2.truncate(emoji, 4), 'Hi 👋…');
  });

  test('stage 2 still cuts a flag in half', () {
    expect(v2.truncate(flag, 4), isNot('Go 🇬🇧…'));
    expect(v2.truncate(flag, 4).runes.length, 5);
  });

  test('the finished version keeps both whole', () {
    expect(final_.truncate(emoji, 4), 'Hi 👋…');
    expect(final_.truncate(flag, 4), 'Go 🇬🇧…');
  });
}
