import 'package:ch38_expenses/expenses.dart';
import 'package:test/test.dart';

/// The reason for a reading, whatever kind it was.
String reasonOf(Reading reading) => switch (reading) {
  Understood(:final money) => money.asText,
  Unreadable(:final reason) => reason,
  Refused(:final reason) => reason,
};

void main() {
  group('text that is an amount', () {
    test('comes back understood, with the money in it', () {
      expect(readMoney('12.50'), isA<Understood>());
      expect(reasonOf(readMoney('12.50')), '£12.50');
      expect(reasonOf(readMoney('12')), '£12.00');
      expect(reasonOf(readMoney('0.05')), '£0.05');
    });
  });

  group('text that is not an amount', () {
    test('comes back unreadable, and says which part was wrong', () {
      expect(readMoney('12.5'), isA<Unreadable>());
      expect(reasonOf(readMoney('12.5')), 'pence are two digits, and "5" is 1');
      expect(reasonOf(readMoney('1.2.3')), 'an amount has one dot, not 2');
      expect(reasonOf(readMoney('abc')), '"abc" is not digits');
      expect(reasonOf(readMoney('')), 'an amount cannot be empty');
    });

    test('and still refuses everything int.tryParse would have allowed', () {
      // Study 24 shipped a parser that answered 499 for this.
      for (final text in ['0x10', '5.-1', '5. 1', ' 12.50']) {
        expect(readMoney(text), isA<Unreadable>(), reason: text);
      }
    });
  });

  group('text that is an amount this program will not hold', () {
    test('is refused, and that is not the same as unreadable', () {
      expect(readMoney('-5.00'), isA<Refused>());
      expect(reasonOf(readMoney('-5.00')), 'money is never negative');
    });

    test('so the three cases really are three', () {
      expect(readMoney('12.50'), isA<Understood>());
      expect(readMoney('nope'), isA<Unreadable>());
      expect(readMoney('-1'), isA<Refused>());
    });
  });
}
