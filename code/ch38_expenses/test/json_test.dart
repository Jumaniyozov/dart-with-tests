import 'dart:convert';

import 'package:ch38_expenses/expenses.dart';
import 'package:test/test.dart';

// #region fixtures
/// A class that has not been told how to write itself down.
class Unencodable {
  final int pence = 1250;
}

final day = Day(2026, 9, 9);
final coffee = Expense(Money.fromPence(1250), Category('food'), day, 'coffee');
// #endregion fixtures

void main() {
  // #region roundtrip
  group('an expense, written down and read back', () {
    test('is four keys of the plainest types JSON has', () {
      expect(coffee.toJson(), {
        'day': '2026-09-09',
        'pence': 1250,
        'category': 'food',
        'note': 'coffee',
      });
    });

    test('and comes back the same expense', () {
      final back = expenseFromJson(jsonDecode(jsonEncode(coffee.toJson())))!;
      expect(back.amount, coffee.amount);
      expect(back.category, coffee.category);
      expect(back.day, coffee.day);
      expect(back.note, coffee.note);
    });

    test('but not the same object, because an expense is an entity', () {
      final back = expenseFromJson(jsonDecode(jsonEncode(coffee.toJson())))!;
      expect(back == coffee, isFalse, reason: "study 25's rule, unchanged");
    });
  });
  // #endregion roundtrip

  // #region checked
  group('the map pattern is the cast that checks', () {
    test('a wrong type is answered, not thrown', () {
      final json = jsonDecode(
        '{"day":"2026-09-09","pence":"1250",'
        '"category":"food","note":"x"}',
      );
      expect(expenseFromJson(json), isNull);
    });

    test('and the cast it replaces would have thrown an Error', () {
      final json = jsonDecode('{"pence":"1250"}') as Map<String, dynamic>;
      expect(
        () => json['pence'] as int,
        throwsA(isA<TypeError>()),
        reason: 'a TypeError is an Error, and study 26 says not to catch one',
      );
    });

    test('a missing key is answered too', () {
      expect(expenseFromJson({'pence': 1250}), isNull);
    });

    test('and a key nobody here knows about is ignored', () {
      final json = {
        'day': '2026-09-09',
        'pence': 1250,
        'category': 'food',
        'note': 'coffee',
        'paidBy': 'a later version of this program',
      };
      expect(expenseFromJson(json)?.note, 'coffee');
    });

    test('what JSON accepts and the domain does not', () {
      // Every one of these is valid JSON with the right types in it.
      expect(expenseFromJson({...coffee.toJson(), 'pence': -1}), isNull);
      expect(expenseFromJson({...coffee.toJson(), 'category': '   '}), isNull);
      expect(
        expenseFromJson({...coffee.toJson(), 'day': '2026-02-31'}),
        isNull,
      );
      expect(
        expenseFromJson({...coffee.toJson(), 'day': '9 Sept 2026'}),
        isNull,
      );
    });
  });
  // #endregion checked

  // #region parsing
  group('a day out of a file', () {
    test('reads the shape it writes', () {
      expect(Day.parse('2026-09-09'), day);
      expect(Day.parse(day.asText), day);
      expect(Day.parse('2024-02-29'), Day(2024, 2, 29));
    });

    test('and refuses everything else, without throwing', () {
      for (final text in [
        '',
        '2026-9-9',
        '2026/09/09',
        '2026-13-01',
        '2026-02-31',
        '1900-02-29',
        '2026-09-09T00:00:00.000',
      ]) {
        expect(Day.parse(text), isNull, reason: 'Day.parse("$text")');
      }
    });

    test('including the one int.tryParse would have let through', () {
      expect(
        Day.parse('-123-01-01'),
        isNull,
        reason: 'ten characters with dashes in both the right places',
      );
      expect(
        int.tryParse('-123'),
        -123,
        reason: 'which is why the check exists',
      );
    });
  });
  // #endregion parsing

  // #region encode
  group('jsonEncode asks your object how to write itself down', () {
    test('and refuses, loudly, when it cannot', () {
      expect(
        () => jsonEncode(Unencodable()),
        throwsA(isA<JsonUnsupportedObjectError>()),
      );
    });

    test(
      'which is an Error, so forgetting toJson is a bug and not an input',
      () {
        expect(JsonUnsupportedObjectError(Unencodable()), isA<Error>());
      },
    );
  });
  // #endregion encode
}
