import 'package:ch17_receipts/receipts.dart';
import 'package:test/test.dart';

void main() {
  // #region sharing
  group('behaviour shared between unrelated types', () {
    test('both get everything Signed provides', () {
      expect(Receipt(-2500, 6, 'grocer').isDebit, isTrue);
      expect(Payslip(180000, 'acme').isDebit, isFalse);
      expect(Receipt(-2500, 6, 'grocer').magnitude, 2500);
    });

    test('and only the receipt takes Dated as well', () {
      expect(Receipt(-2500, 6, 'grocer').dayName, 'Sat');
      expect(Receipt(-2500, 6, 'grocer').isWeekend, isTrue);
      expect(Receipt(-2500, 3, 'grocer').isWeekend, isFalse);
    });

    test('and the class promises the day the mixin relies on', () {
      expect(() => Receipt(-2500, 9, 'grocer'), throwsA(isA<AssertionError>()));
      expect(() => Receipt(-2500, 0, 'grocer'), throwsA(isA<AssertionError>()));
      expect(Receipt(-2500, 7, 'grocer').dayName, 'Sun');
    });

    test('a mixin is a type, so both count as Signed', () {
      expect(Receipt(-2500, 6, 'grocer'), isA<Signed>());
      expect(Payslip(180000, 'acme'), isA<Signed>());
      expect(Payslip(180000, 'acme'), isNot(isA<Dated>()));
    });
  });
  // #endregion sharing

  // #region clash
  group('when two mixins declare the same member', () {
    test('the rightmost one wins', () {
      expect(TitledFirst().label, 'numbered');
      expect(NumberedFirst().label, 'titled');
    });
  });
  // #endregion clash

  // #region both
  group('a mixin class is usable both ways', () {
    test('mixed into something else', () {
      expect(Till().toNearest(1234, 100), 1200);
      expect(Till().toNearest(1250, 100), 1300);
    });

    test('and built directly, which a plain mixin cannot be', () {
      expect(Rounding().toNearest(1234, 100), 1200);
      expect(Till(), isA<Rounding>());
    });
  });
  // #endregion both

  // #region chain
  group('order changes the answer, not just the winner', () {
    test('each mixin wraps the one applied before it', () {
      expect(DiscountThenTax(1000).total(), 1080);
      expect(TaxThenDiscount(1000).total(), 1100);
    });

    test('so the same two rules on the same bill differ by 20p', () {
      expect(TaxThenDiscount(1000).total() - DiscountThenTax(1000).total(), 20);
    });
  });
  // #endregion chain
}
