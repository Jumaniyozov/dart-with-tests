import 'dart:convert';

import 'package:ch29_expenses/expenses.dart';
import 'package:test/test.dart';

import 'challenges.dart';

final day = Day(2026, 9, 9);

String lineFor(int pence, String category, String note) => jsonEncode(
  Expense(Money.fromPence(pence), Category(category), day, note).toJson(),
);

void main() {
  group('challenge 1 — a budget through JSON', () {
    final food = Budget(Category('food'), Money.fromPence(20000));

    test('writes exactly two keys', () {
      expect(budgetToJson(food), {'category': 'food', 'pence': 20000});
    });

    test('and reads its own writing back', () {
      final back = budgetFromJson(jsonDecode(jsonEncode(budgetToJson(food))))!;
      expect(back.category, Category('food'));
      expect(back.limit, Money.fromPence(20000));
    });

    test('answers null for a wrong type instead of throwing', () {
      expect(budgetFromJson({'category': 'food', 'pence': '20000'}), isNull);
      expect(budgetFromJson({'category': 7, 'pence': 20000}), isNull);
      expect(budgetFromJson({'pence': 20000}), isNull);
      expect(budgetFromJson('not a map at all'), isNull);
    });

    test('and for the ones only the domain objects to', () {
      expect(budgetFromJson({'category': 'food', 'pence': 0}), isNull);
      expect(budgetFromJson({'category': 'food', 'pence': -1}), isNull);
      expect(budgetFromJson({'category': '  ', 'pence': 20000}), isNull);
    });
  });

  group('challenge 2 — a file of them', () {
    test('nothing at all is no expenses', () {
      expect(expensesFrom(''), isEmpty);
      expect(expensesFrom('\n\n'), isEmpty);
    });

    test('reads every line it can', () {
      final text = [
        lineFor(1250, 'food', 'coffee'),
        lineFor(300, 'transport', 'bus'),
      ].join('\n');
      expect([for (final e in expensesFrom(text)) e.note], ['coffee', 'bus']);
    });

    test('and keeps going past one it cannot', () {
      final text = [
        lineFor(1250, 'food', 'coffee'),
        'this is not json',
        '{"day":"2026-09-09","pence":"300","category":"transport","note":"bus"}',
        lineFor(5, 'food', 'sweet'),
      ].join('\n');
      expect([for (final e in expensesFrom(text)) e.note], ['coffee', 'sweet']);
    });
  });

  group('challenge 3 — and says which ones it could not', () {
    test('nothing skipped when everything reads', () {
      final report = readReport(lineFor(1250, 'food', 'coffee'));
      expect(report.read, hasLength(1));
      expect(report.skipped, isEmpty);
    });

    test('counts the lines it dropped, from one', () {
      final text = [
        'rubbish',
        lineFor(1250, 'food', 'coffee'),
        '{"pence":300}',
        lineFor(300, 'transport', 'bus'),
        '{"day":"2026-02-31","pence":100,"category":"food","note":"x"}',
      ].join('\n');

      final report = readReport(text);
      expect([for (final e in report.read) e.note], ['coffee', 'bus']);
      expect(report.skipped, [1, 3, 5]);
    });
  });
}
