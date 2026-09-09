import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — a reading that is capped', () {
    test('holds anything above the cap down to it', () {
      expect(Loose(80).value(), 100);
    });

    test('and leaves anything under it alone', () {
      expect(Loose(30).value(), 60);
    });
  });

  group('challenge 2 — a reading that is doubled', () {
    test('doubles what reaches it', () {
      expect(Strict(30).value(), 60);
      expect(Strict(10).value(), 20);
    });
  });

  group('challenge 3 — the order the two are applied in', () {
    test('doubling before capping stops at the cap', () {
      expect(Loose(60).value(), 100);
    });

    test('capping before doubling does not', () {
      expect(Strict(60).value(), 120);
    });

    test('and they only agree when neither does anything', () {
      expect(Loose(20).value(), Strict(20).value());
      expect(Loose(20).value(), 40);
    });
  });
}
