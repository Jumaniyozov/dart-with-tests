import 'package:ch19_pence/pence.dart';
import 'package:ch19_pence/v1.dart' as v1;
import 'package:test/test.dart';

void main() {
  // #region override
  group('naming the extension in front of the receiver', () {
    test('picks that one, and is legal even when there is no clash', () {
      expect(PenceFormatting(1234).asMoney, '£12.34');
      expect(PenceFormatting(0).isDebit, isFalse);
    });
  });
  // #endregion override

  // #region totals
  group('an extension on a type with a type argument', () {
    test('adds up amounts without leaving the type', () {
      expect([Pence(700), Pence(250), Pence(-100)].total.asMoney, '£8.50');
      expect(<Pence>[].total.value, 0);
    });
  });
  // #endregion totals

  // #region shadowing
  group('an instance member and an extension member with one name', () {
    test('from outside, the instance member wins', () {
      expect(Shop('Ada').name, 'Ada');
    });

    test('from inside the extension, the extension member wins', () {
      expect(Shop('Ada').sign, 'Welcome to the extension');
    });
  });
  // #endregion shadowing

  // #region loose
  group('an amount that is only an int by convention', () {
    const daysOverdue = 7;

    test('formats a day count as money, and nothing objects', () {
      expect(v1.receiptFor(1234), 'You paid £12.34');
      expect(v1.receiptFor(daysOverdue), 'You paid £0.07');
    });
  });
  // #endregion loose

  // #region named
  group('a named constructor can check what the first line cannot', () {
    test('it builds an amount out of its parts', () {
      expect(Pence.fromParts(12, 34).value, 1234);
      expect(Pence.fromParts(0, 5).asMoney, '£0.05');
    });

    test('and refuses parts that are not parts', () {
      expect(() => Pence.fromParts(12, 100), throwsA(isA<AssertionError>()));
      expect(() => Pence.fromParts(-1, 50), throwsA(isA<AssertionError>()));
    });

    test('but the unchecked constructor is still right there', () {
      expect(Pence(-150).asMoney, '-£1.50');
    });
  });
  // #endregion named

  // #region gone
  group('at run time the name is gone', () {
    test('every int is already every extension type over int', () {
      final Object amount = 700;
      expect(amount is Pence, isTrue);
      expect(amount is Pounds, isTrue);
    });

    test('so a run-time question cannot tell two of them apart', () {
      final List<Object?> mixed = [Pence(700), Pounds(7)];
      expect(mixed.whereType<Pence>().length, 2);
      expect(mixed.whereType<Pounds>().length, 2);
    });

    test('so a cast walks straight through the name', () {
      final Object seven = 7;
      expect((seven as Pence).value, 7);
    });

    test('and the value is the int it was made from', () {
      expect(Pence(700).runtimeType, int);
      expect(Pence(700).toString(), '700');
    });
  });
  // #endregion gone

  // #region pattern
  group('a pattern matching on the type sees straight through it', () {
    test('an amount matches, and so does a plain int', () {
      expect(describe(Pence(700)), 'pence 700');
      expect(describe(700), 'pence 700');
      expect(describe('seven'), 'not an amount');
    });

    test('and so does a different extension type over the same int', () {
      expect(describe(Pounds(7)), 'pence 7');
    });
  });
  // #endregion pattern

  // #region open
  group('implements reopens the underlying type', () {
    test('every int member comes back', () {
      expect(OpenPence(1234).isEven, isTrue);
      expect(OpenPence(1234).compareTo(OpenPence(99)), 1);
    });

    test('and so does assignment in both directions', () {
      const int plain = OpenPence(5);
      expect(plain, 5);
    });

    test('and arithmetic still answers, at the price 19.4 names', () {
      expect(OpenPence(1200) + 100, 1300);
    });
  });
  // #endregion open

  // #region closed
  group('the type the compiler will not let go of', () {
    test('pounds convert to pence, and only that way', () {
      expect(receiptFor(Pounds(12).inPence), 'You paid £12.00');
      expect(receiptFor(Pence(1234)), 'You paid £12.34');
    });

    test('and an amount can be built up without leaving the type', () {
      expect(Pence(700).plus(Pence(250)).asMoney, '£9.50');
      expect(Pounds(3).inPence.times(4).asMoney, '£12.00');
    });
  });
  // #endregion closed
}
