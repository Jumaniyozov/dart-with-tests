import 'package:ch27_expenses/expenses.dart';
import 'package:test/test.dart';

import 'challenges.dart';

final day = Day(2026, 9, 9);

Expense expenseOf(String note) =>
    Expense(Money.fromPence(100), Category('food'), day, note);

void main() {
  group('challenge 1 — a second implementation', () {
    test('keeps everything while there is room', () {
      final store = CappedStore(2)..record(expenseOf('apple'));
      expect(store.all.single.note, 'apple');
    });

    test('and drops the oldest once there is not', () {
      final store = CappedStore(2)
        ..record(expenseOf('apple'))
        ..record(expenseOf('soup'))
        ..record(expenseOf('bus'));
      expect([for (final e in store.all) e.note], ['soup', 'bus']);
    });

    test('and the program works against it unchanged', () {
      final store = CappedStore(1);
      run(['add', '1.00', 'food', 'apple'], store, day);
      run(['add', '2.50', 'food', 'soup'], store, day);
      expect(run(['list'], store, day).out, contains('food: £2.50'));
    });
  });

  group('challenge 2 — a store in front of a store', () {
    test('passes records through and counts them', () {
      final inner = InMemoryStore();
      final counting = CountingStore(inner)
        ..record(expenseOf('apple'))
        ..record(expenseOf('soup'));
      expect(counting.records, 2);
      expect(inner.all, hasLength(2));
      expect(counting.all, hasLength(2));
    });

    test('and reading does not count as recording', () {
      final counting = CountingStore(InMemoryStore());
      expect(counting.records, 0);
      expect(counting.all, isEmpty);
      expect(counting.records, 0);
    });

    test('so run can be watched without being changed', () {
      final counting = CountingStore(InMemoryStore());
      run(['add', '1.00', 'food', 'apple'], counting, day);
      run(['add', 'abc', 'food', 'soup'], counting, day);
      expect(counting.records, 1, reason: 'the second run recorded nothing');
    });
  });

  group('challenge 3 — a seam that is just a parameter', () {
    test('the same day is today', () {
      expect(describeDay(Day(2026, 9, 9), day), 'today');
    });

    test('an earlier day is in the past', () {
      expect(describeDay(Day(2026, 9, 8), day), 'in the past');
      expect(describeDay(Day(2026, 8, 30), day), 'in the past');
      expect(describeDay(Day(2025, 12, 31), day), 'in the past');
    });

    test('a later day is in the future', () {
      expect(describeDay(Day(2026, 9, 10), day), 'in the future');
      expect(describeDay(Day(2026, 10, 1), day), 'in the future');
      expect(describeDay(Day(2027, 1, 1), day), 'in the future');
    });
  });
}
