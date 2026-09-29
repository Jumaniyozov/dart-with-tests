import 'dart:convert';

import 'package:fixtures/bag.dart';
import 'package:fixtures/expense.dart';
import 'package:fixtures/money.dart';
import 'package:test/test.dart';

/// A JSON round trip through text, as a file or a server does it.
Object? _wire(Object? value) => jsonDecode(jsonEncode(value));

Expense _expense() => Expense(
  Money.fromPence(250),
  Kind.food,
  DateTime.utc(2026, 9, 28),
  1.5,
  'tea',
  null,
  ['a', 'b'],
  [Money.fromPence(1)],
);

/// A valid Expense JSON map with [key] set to [value].
Map<String, Object?> _expenseJsonWith(String key, Object? value) =>
    (_wire(_expense()) as Map<String, Object?>)..[key] = value;

void main() {
  group('Expense', () {
    test('survives a JSON round trip with equal value and hash', () {
      final expense = _expense();
      final back = Expense.fromJson(_wire(expense));
      expect(back, expense);
      expect(back.hashCode, expense.hashCode);
    });

    test('copyWith clears a nullable field and keeps the others', () {
      final expense = _expense();
      expect(expense.copyWith(note: null).note, isNull);
      expect(expense.copyWith(kind: Kind.rent).note, 'tea');
    });

    test('a file without the defaulted key reads the default', () {
      final json = _expenseJsonWith('note', null)..remove('acknowledged');
      expect(Expense.fromJson(json).acknowledged, isFalse);
    });

    test('JSON 1 reads as the double 1.0', () {
      final rate = Expense.fromJson(_expenseJsonWith('rate', 1)).rate;
      expect(rate, 1.0);
      expect(rate, isA<double>());
    });

    for (final (key, value) in [
      ('kind', 'nope'),
      ('day', 'not a date'),
      ('tags', [1]),
      ('note', 5),
      ('acknowledged', 'yes'),
    ]) {
      test('a bad "$key" throws a FormatException that names it', () {
        expect(
          () => Expense.fromJson(_expenseJsonWith(key, value)),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('"$key"'),
            ),
          ),
        );
      });
    }

    test('a JSON value that is not a map throws a FormatException', () {
      expect(() => Expense.fromJson([]), throwsFormatException);
    });
  });

  group('Bag', () {
    Bag bag({String? label}) => Bag(
      [1.5],
      {'a'},
      [DateTime.utc(2026)],
      [null, 'x'],
      {'k': 1},
      {'p': Money.fromPence(2)},
      3,
      // An Object? field compares with ==, so a map here would compare by
      // identity. A string keeps the round trip equal.
      'any',
      label: label,
    );

    test('an explicit null survives a non-null default', () {
      expect(Bag.fromJson(_wire(bag())).label, isNull);
    });

    test('a missing key reads the default', () {
      final json = _wire(bag()) as Map<String, Object?>..remove('label');
      expect(Bag.fromJson(json).label, 'none');
    });

    test('collections survive a round trip', () {
      final value = bag(label: 'x');
      expect(Bag.fromJson(_wire(value)), value);
    });
  });

  test('copyWith and fromJson go through the validating factory', () {
    expect(() => Money.fromPence(1).copyWith(pence: -1), throwsArgumentError);
    expect(() => Money.fromJson({'pence': -1}), throwsArgumentError);
  });
}
