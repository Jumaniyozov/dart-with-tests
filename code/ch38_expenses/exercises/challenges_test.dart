import 'dart:io';

import 'package:ch38_expenses/expenses.dart';
import 'package:test/test.dart';

import 'challenges.dart';

final today = Day(2026, 9, 11);

Expense spent(int pence) =>
    Expense(Money.fromPence(pence), Category('food'), today, 'tea');

/// A [Store] that counts what being asked cost, so a cache can be measured
/// rather than described.
class Counting implements Store {
  int expenseReads = 0;
  int limitReads = 0;
  final List<Expense> expenses = [];
  final List<Limit> limitsSet = [];

  @override
  Future<List<Expense>> get all async {
    expenseReads++;
    return List.unmodifiable(expenses);
  }

  @override
  Future<List<Limit>> get limits async {
    limitReads++;
    return List.unmodifiable(limitsSet);
  }

  @override
  Future<void> record(Expense expense) async => expenses.add(expense);

  @override
  Future<void> setLimit(Limit limit) async => limitsSet.add(limit);
}

void main() {
  group('challenge 1 — has it moved since you last looked', () {
    test('the first look has nothing to compare against, so it has', () {
      expect(changed(() => 7)(), isTrue);
    });

    test('and looking again at the same number has not', () {
      final moved = changed(() => 7);

      expect(moved(), isTrue);
      expect(moved(), isFalse);
      expect(moved(), isFalse);
    });

    test('a number that goes up has moved', () {
      var version = 0;
      final moved = changed(() => version);

      expect(moved(), isTrue);
      version = 10;
      expect(moved(), isTrue);
      expect(moved(), isFalse);
    });

    test('and so has one that goes down', () {
      var version = 10;
      final moved = changed(() => version);
      moved();

      version = 4;

      expect(
        moved(),
        isTrue,
        reason: 'a file that got shorter is a file somebody rewrote',
      );
    });
  });

  group('challenge 2 — a cache that holds the other half', () {
    test(
      'the limits are read once, however often they are asked for',
      () async {
        final counting = Counting()
          ..limitsSet.add(Limit(Category('food'), Money.fromPence(2000)));
        final held = limitsHeld(counting);

        expect(await held.limits, hasLength(1));
        expect(await held.limits, hasLength(1));
        expect(await held.limits, hasLength(1));

        expect(counting.limitReads, 1);
      },
    );

    test('and the expenses are read every single time', () async {
      final counting = Counting()..expenses.add(spent(450));
      final held = limitsHeld(counting);

      await held.all;
      await held.all;
      await held.all;

      expect(counting.expenseReads, 3);
    });

    test('an expense written through is found by the next read', () async {
      final counting = Counting();
      final held = limitsHeld(counting);

      await held.record(spent(450));

      expect(await held.all, hasLength(1));
      expect(counting.expenses, hasLength(1));
    });

    test('and a limit written through is the bet this makes', () async {
      final counting = Counting();
      final held = limitsHeld(counting);
      expect(await held.limits, isEmpty);

      await held.setLimit(Limit(Category('food'), Money.fromPence(2000)));

      expect(counting.limitsSet, hasLength(1), reason: 'it really was written');
      expect(
        await held.limits,
        isEmpty,
        reason:
            'and this cache never looks again, which is exactly the thing to '
            'be able to say out loud about a cache you wrote on purpose',
      );
    });
  });

  group('challenge 3 — how long is the file', () {
    late Directory directory;
    late File file;
    setUp(() {
      directory = Directory.systemTemp.createTempSync('challenge38');
      file = File('${directory.path}/expenses.txt');
    });
    tearDown(() => directory.deleteSync(recursive: true));

    test('a file that is not there is nothing, and does not throw', () {
      expect(lengthOf(file)(), 0);
    });

    test('an empty file is also nothing', () {
      file.writeAsStringSync('');

      expect(lengthOf(file)(), 0);
    });

    test('and a file with something in it is how many bytes that is', () {
      file.writeAsStringSync('hello\n');

      expect(lengthOf(file)(), 6);
    });

    test('it is asked every time, not answered once', () {
      final length = lengthOf(file);
      expect(length(), 0);

      file.writeAsStringSync('hello\n');

      expect(
        length(),
        6,
        reason:
            'a function that answered at the moment it was built would be '
            'bin/holding.dart, which is the program that gets this wrong',
      );
    });
  });
}
