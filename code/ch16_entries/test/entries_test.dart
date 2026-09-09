import 'package:ch16_entries/entries.dart';
import 'package:test/test.dart';

void main() {
  const statement = [
    Payment(-2500, 'landlord'),
    Refund(1200, 'shop'),
    Interest(340, 120),
  ];

  // #region family
  group('one field and one getter, written once', () {
    test('every entry has the pence its parent declared', () {
      expect(Payment(-2500, 'landlord').pence, -2500);
      expect(Interest(340, 120).pence, 340);
    });

    test('and the getter that comes with it, written in only one place', () {
      expect(Payment(-2500, 'landlord').isDebit, isTrue);
      expect(Refund(1200, 'shop').isDebit, isFalse);
      expect(Interest(340, 120).isDebit, isFalse);
    });

    test('a list of them is a list of Entry', () {
      expect(balanceOf(statement), -960);
      expect(debitsIn(statement), hasLength(1));
      expect(debitsIn(statement).single, isA<Payment>());
    });
  });
  // #endregion family

  // #region switching
  group('a switch over the family', () {
    test('reads the fields of whichever one it matched', () {
      expect(describe(Payment(-2500, 'landlord')), 'paid landlord');
      expect(describe(Refund(1200, 'shop')), 'refund from shop');
      expect(describe(Interest(340, 120)), 'interest over 120 days');
    });

    test('guards narrow inside a case without losing exhaustiveness', () {
      expect(handlingFee(Payment(-2500, 'landlord')), 25);
      expect(handlingFee(Payment(-2500, 'self')), 0);
      expect(handlingFee(Refund(1200, 'shop')), 0);
      expect(handlingFee(Interest(340, 120)), 100);
      expect(handlingFee(Interest(340, 30)), 50);
    });
  });
  // #endregion switching

  // #region inherited
  group('what a subclass does and does not inherit', () {
    test('equality is still not given, exactly as in study 15', () {
      expect(Payment(-2500, 'x') == Payment(-2500, 'x'), isFalse);
    });

    test('but two const entries are one object', () {
      const a = Payment(-2500, 'landlord');
      const b = Payment(-2500, 'landlord');
      expect(identical(a, b), isTrue);
    });

    test('and a subclass is its parent, so it goes where Entry goes', () {
      expect(Payment(-2500, 'x'), isA<Entry>());
      expect(Refund(1, 'y'), isA<Entry>());
      expect(Payment(-2500, 'x'), isNot(isA<Refund>()));
    });
  });
  // #endregion inherited

  // #region band
  group('an enum that carries its own data', () {
    test('each value holds the fields its constructor was given', () {
      expect(Band.incoming.heading, 'Money in');
      expect(Band.outgoing.order, 2);
    });

    test('and answers methods of its own', () {
      expect(Band.incoming.isFirst, isTrue);
      expect(Band.outgoing.isFirst, isFalse);
      expect(Band.outgoing.toString(), 'Money out');
    });

    test('a static member on the enum sorts an entry into a band', () {
      expect(Band.of(Payment(-2500, 'x')), Band.outgoing);
      expect(Band.of(Refund(1200, 'y')), Band.incoming);
    });

    test('everything study 6 promised still works', () {
      expect(Band.values, [Band.incoming, Band.outgoing]);
      expect(Band.outgoing.name, 'outgoing');
      expect(Band.outgoing.index, 1);
    });
  });
  // #endregion band
}
