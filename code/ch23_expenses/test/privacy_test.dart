// What the boundary holds, and where it stops.
//
// Every claim 23.1 and 23.4 make about privacy is asserted here. Two of these
// tests pass by demonstrating that something got through, which is the point.

import 'package:ch23_expenses/src/crowded.dart';
import 'package:ch23_expenses/src/pence.dart';
import 'package:test/test.dart';

void main() {
  group('a class, from outside its library', () {
    test(
      'the check cannot be walked past, because the door is the factory',
      () {
        expect(() => Amount.fromPence(-1), throwsArgumentError);
      },
    );
  });

  group('a class, from inside its own library', () {
    test('an unrelated class in the same file reaches the constructor', () {
      // `Backdoor` is not a friend of `Amount`, and does not need to be. It is
      // in the same file, which is the whole qualification.
      expect(Backdoor.unchecked(-5).pence, -5);
    });
  });

  group('an extension type, with the same private constructor', () {
    test('the factory refuses, exactly as the class does', () {
      expect(() => Pence.fromValue(-1), throwsArgumentError);
    });

    test('and a cast walks straight past it anyway', () {
      // No analyzer warning, no run-time error. The cast is checked against
      // `int`, and -1 is an `int`.
      final walked = -1 as Pence;
      expect(walked.value, -1);
    });
  });
}
