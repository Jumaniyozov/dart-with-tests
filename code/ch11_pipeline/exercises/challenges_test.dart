import 'package:ch11_pipeline/pipeline.dart';
import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — a step with a ceiling', () {
    test('holds an amount down to the ceiling', () {
      expect(capAt(500)(600), 500);
    });

    test('leaves anything under the ceiling alone', () {
      expect(capAt(500)(400), 400);
      expect(capAt(500)(500), 500);
    });
  });

  group('challenge 2 — many steps as one', () {
    test('does the same as running them in order', () {
      final steps = [addFee(50), discount(10)];
      expect(combine(steps)(1000), runPipeline(1000, steps));
      expect(combine(steps)(1000), 945);
    });

    test('combining nothing changes nothing', () {
      expect(combine([])(1000), 1000);
    });
  });

  group('challenge 3 — a function that remembers', () {
    test('adds each amount to what it has already been given', () {
      final total = runningTotal();
      expect(total(100), 100);
      expect(total(50), 150);
      expect(total(0), 150);
    });

    test('two of them count separately', () {
      final a = runningTotal();
      final b = runningTotal();
      expect(a(100), 100);
      expect(b(7), 7);
    });
  });
}
