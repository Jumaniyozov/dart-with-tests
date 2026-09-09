import 'package:ch11_pipeline/pipeline.dart';
import 'package:ch11_pipeline/v1.dart' as v1;
import 'package:test/test.dart';

void main() {
  // #region order
  group('running a pipeline', () {
    test('applies the steps in the order they are given', () {
      expect(runPipeline(1000, [addFee(100), discount(10)]), 990);
      expect(runPipeline(1000, [discount(10), addFee(100)]), 1000);
    });

    test('a named function can be handed over by name', () {
      expect(runPipeline(254, [roundToTenPence]), 250);
      expect(runPipeline(255, [roundToTenPence, addFee(5)]), 265);
    });
  });
  // #endregion order

  // #region params
  group('saying what a function takes', () {
    test('an optional positional argument has a default', () {
      expect(repeat(100, addFee(10)), 110);
      expect(repeat(100, addFee(10), 3), 130);
    });

    test('named arguments say which number is which', () {
      expect(line('jam', pence: 250), 'jam         250p');
      expect(line('jam', pence: 250, width: 6), 'jam   250p');
      expect(
        line('jam', pence: 250, note: 'half price'),
        'jam         250p (half price)',
      );
    });
  });
  // #endregion params

  // #region closure
  group('what a closure keeps', () {
    test('a counter remembers a variable that has gone out of scope', () {
      final next = counter();
      expect(next(), 1);
      expect(next(), 2);
      expect(next(), 3);
    });

    test('two counters keep two separate variables', () {
      final a = counter();
      final b = counter();
      expect(a(), 1);
      expect(a(), 2);
      expect(b(), 1);
    });

    test('each step built in a loop remembers its own fee', () {
      final steps = feeSteps([10, 20, 30]);
      expect(steps[0](100), 110);
      expect(steps[1](100), 120);
      expect(steps[2](100), 130);
    });
  });
  // #endregion closure

  // #region loops
  group('a loop gives each pass its own variable', () {
    test('a C-style for does too, which is not true everywhere', () {
      final built = <int Function()>[];
      for (var i = 0; i < 3; i++) {
        built.add(() => i);
      }
      expect([built[0](), built[1](), built[2]()], [0, 1, 2]);
    });

    test('a variable declared outside the loop is one variable', () {
      final built = <int Function()>[];
      var i = 0;
      while (i < 3) {
        built.add(() => i);
        i++;
      }
      expect([built[0](), built[1](), built[2]()], [3, 3, 3]);
    });

    test('which is why the shared-counter version reads past the end', () {
      final steps = v1.feeSteps([10, 20]);
      expect(steps, hasLength(2));
      expect(() => steps.first(100), throwsA(isA<RangeError>()));
    });
  });
  // #endregion loops
}
