import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — a size initial', () {
    test('gives one capital letter per size', () {
      expect(initial(Size.small), 'S');
      expect(initial(Size.medium), 'M');
      expect(initial(Size.large), 'L');
    });
  });

  group('challenge 2 — cooking times', () {
    test('knows how long each doneness takes', () {
      expect(minutesFor(Doneness.rare), 2);
      expect(minutesFor(Doneness.medium), 4);
      expect(minutesFor(Doneness.wellDone), 7);
    });
  });

  group('challenge 3 — listing the sizes', () {
    test('lists every size in declaration order', () {
      expect(allSizes(), 'small, medium, large');
    });

    test('uses the names the enum already carries', () {
      expect(allSizes().contains(Size.medium.name), isTrue);
    });
  });
}
