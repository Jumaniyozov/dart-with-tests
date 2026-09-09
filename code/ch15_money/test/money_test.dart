import 'package:ch15_money/money.dart';
import 'package:ch15_money/older.dart' as older;
import 'package:ch15_money/v1.dart' as v1;
import 'package:test/test.dart';

void main() {
  // #region methods
  group('a type that knows what it holds', () {
    test('reads an amount out in pounds and pence', () {
      expect(Money(1234).format(), '£12.34');
      expect(Money(7).format(), '£0.07');
      expect(Money(0).format(), '£0.00');
      expect(Money(-5).format(), '-£0.05');
    });

    test('does arithmetic that gives back its own type', () {
      expect(Money(250).plus(Money(180)), Money(430));
      expect(Money(250).times(3), Money(750));
      expect(Money(250).plus(Money(-300)).isDebit, isTrue);
    });
  });
  // #endregion methods

  // #region equality
  group('equality is written, not given', () {
    test('a class with no == is equal only to itself', () {
      expect(v1.Money(250) == v1.Money(250), isFalse);
      expect(v1.Money(250).toString(), "Instance of 'Money'");
    });

    test('the same two numbers in a record are equal for nothing', () {
      expect((250,) == (250,), isTrue);
    });

    test('written out, two amounts of the same money are equal', () {
      expect(Money(250) == Money(250), isTrue);
      expect(Money(250) == Money(180), isFalse);
      expect(Money(250).toString(), 'Money(£2.50)');
    });

    test('equal, and not the same object', () {
      expect(identical(Money(250), Money(250)), isFalse);
    });

    test('but two const amounts are one object', () {
      const a = Money(250);
      const b = Money(250);
      expect(identical(a, b), isTrue);
    });

    test('and a hashCode to match makes it a usable key', () {
      expect({Money(250): 'coffee'}[Money(250)], 'coffee');
      expect({v1.Money(250): 'coffee'}[v1.Money(250)], isNull);
    });
  });
  // #endregion equality

  // #region invariant
  group('a promise a record could not make', () {
    test('splits an amount into two parts that mean what they say', () {
      final split = Split.fromPence(1234);
      expect(split.pounds, 12);
      expect(split.pence, 34);
      expect(split.amount, Money(1234));
    });

    test('the pre-3.13 spelling of the same class behaves identically', () {
      expect(older.Split.fromPence(1234).amount, Split.fromPence(1234).amount);
      expect(older.Split(3, 50).amount, Split(3, 50).amount);
      expect(() => older.Split(3, 150), throwsA(isA<AssertionError>()));
    });

    test('and refuses to be built any other way', () {
      expect(() => Split(3, 150), throwsA(isA<AssertionError>()));
      expect(() => Split(3, -1), throwsA(isA<AssertionError>()));
      expect(Split(3, 0).amount, Money(300));
      expect(Split(3, 99).amount, Money(399));
    });
  });
  // #endregion invariant
}
