import 'dart:io';

import 'package:ch38_expenses/expenses.dart';
import 'package:test/test.dart';

void main() {
  // #region setup
  /// The same two values `command_test.dart` has had since study 27, and the
  /// same `setUp`. They are the arguments a [Tracker] is built from, which is
  /// 36.2's whole point arriving in the least ceremonious possible way.
  final today = Day(2026, 9, 9);
  late Store store;
  late Tracker tracker;
  setUp(() {
    store = InMemoryStore();
    tracker = Tracker(store, () => today);
  });
  // #endregion setup

  // #region cases
  group('the use cases, with no terminal anywhere', () {
    test('record keeps an expense and says nothing stopped it', () async {
      final verdict = await tracker.record(
        Expense(Money.fromPence(1250), Category('food'), today, 'coffee'),
      );

      expect(verdict, isNull, reason: 'no limit on food, so no budget to ask');
      expect((await store.all).single.note, 'coffee');
    });

    test('record files it under the day the clock answers', () async {
      await tracker.record(
        Expense(Money.fromPence(100), Category('food'), tracker.today(), 'tea'),
      );

      expect((await store.all).single.day, today);
    });

    test('expenses answers everything, newest last', () async {
      await tracker.record(
        Expense(Money.fromPence(100), Category('food'), today, 'tea'),
      );
      await tracker.record(
        Expense(Money.fromPence(200), Category('food'), today, 'cake'),
      );

      expect(
        [for (final expense in await tracker.expenses()) expense.note],
        ['tea', 'cake'],
      );
    });

    test('expenses narrows to a period when it is given one', () async {
      await tracker.record(
        Expense(
          Money.fromPence(100),
          Category('food'),
          Day(2026, 8, 31),
          'aug',
        ),
      );
      await tracker.record(
        Expense(Money.fromPence(200), Category('food'), today, 'sep'),
      );

      final september = await tracker.expenses(Period.of(today));

      expect([for (final expense in september) expense.note], ['sep']);
    });

    test('setLimit stores it, and limits reads it back', () async {
      await tracker.setLimit(Limit(Category('food'), Money.fromPence(2000)));

      expect((await tracker.limits).single.amount, Money.fromPence(2000));
    });

    test('budgets answers one per limit, for this month', () async {
      await tracker.setLimit(Limit(Category('food'), Money.fromPence(2000)));
      await tracker.record(
        Expense(Money.fromPence(500), Category('food'), today, 'tea'),
      );

      final budgets = await tracker.budgets();

      expect(budgets.single.spent, Money.fromPence(500));
    });
  });
  // #endregion cases

  // #region verdicts
  group('what record answers when a budget has an opinion', () {
    setUp(
      () => tracker.setLimit(Limit(Category('food'), Money.fromPence(2000))),
    );

    test('Within, and how much is left', () async {
      final verdict = await tracker.record(
        Expense(Money.fromPence(500), Category('food'), today, 'tea'),
      );

      expect(verdict, isA<Within>());
      expect((verdict! as Within).remaining, Money.fromPence(1500));
      expect(await store.all, hasLength(1));
    });

    test('Breach, and nothing was kept', () async {
      final verdict = await tracker.record(
        Expense(Money.fromPence(2500), Category('food'), today, 'feast'),
      );

      expect((verdict! as Breach).over, Money.fromPence(500));
      expect(
        await store.all,
        isEmpty,
        reason: 'a breach nobody acknowledged is a refusal, not a warning',
      );
    });

    test('Breach, and it was kept, when the expense says so itself', () async {
      final verdict = await tracker.record(
        Expense(
          Money.fromPence(2500),
          Category('food'),
          today,
          'feast',
          acknowledged: true,
        ),
      );

      expect((verdict! as Breach).over, Money.fromPence(500));
      expect(await store.all, hasLength(1));
    });

    test('and the verdict is about this month only', () async {
      await tracker.record(
        Expense(
          Money.fromPence(1900),
          Category('food'),
          Day(2026, 8, 20),
          'august',
        ),
      );

      final verdict = await tracker.record(
        Expense(Money.fromPence(1900), Category('food'), today, 'september'),
      );

      expect(verdict, isA<Within>());
    });
  });
  // #endregion verdicts

  // #region moved
  group('what the extraction actually moved', () {
    /// `command.dart` with its comments taken out, because a doc comment
    /// naming a type is prose and this claim is about code.
    List<String> code() => [
      for (final line in File('lib/src/command.dart').readAsLinesSync())
        if (!line.trimLeft().startsWith('//')) line,
    ];

    test('every private use case took a Store and a Day, and none does now', () {
      final naming = [
        for (final line in code())
          if (RegExp(r'\b(Store|Day)\b').hasMatch(line)) line.trim(),
      ];

      expect(
        naming,
        [
          'Future<Outcome> run(List<String> args, Store store, Day today) async {',
        ],
        reason:
            'the two seams study 27 threaded through every one of them are '
            'the two arguments Tracker is built from, and the edge is the only '
            'place left that holds either',
      );
    });

    test('and the edge no longer reaches into the store itself', () {
      /// The four members `command.dart` called on a `Store` in study 35.
      final reaching = RegExp(r'\bstore\.(record|all|limits|setLimit)\b');

      expect(
        code().where(reaching.hasMatch),
        isEmpty,
        reason: 'a layer that the caller can go around is decoration',
      );
    });
  });
  // #endregion moved

  // #region clock
  group('the day is asked for now, not remembered from then', () {
    test(
      'a tracker that outlives a Tuesday files Friday under Friday',
      () async {
        var day = Day(2026, 9, 8);
        final store = InMemoryStore();
        final tracker = Tracker(store, () => day);

        await tracker.record(
          Expense(
            Money.fromPence(450),
            Category('food'),
            tracker.today(),
            'tue',
          ),
        );
        day = Day(2026, 9, 11);
        await tracker.record(
          Expense(
            Money.fromPence(460),
            Category('food'),
            tracker.today(),
            'fri',
          ),
        );

        expect(
          [for (final expense in await store.all) expense.day],
          [Day(2026, 9, 8), Day(2026, 9, 11)],
          reason:
              'study 37 built the tracker with a Day, so both of these would '
              'have been filed under the day the process started',
        );
      },
    );

    test('and the budgets follow the clock into a new month', () async {
      var day = Day(2026, 9, 30);
      final store = InMemoryStore();
      final tracker = Tracker(store, () => day);
      await tracker.setLimit(Limit(Category('food'), Money.fromPence(2000)));
      await tracker.record(
        Expense(Money.fromPence(450), Category('food'), day, 'september'),
      );

      expect((await tracker.budgets()).single.spent, Money.fromPence(450));

      day = Day(2026, 10, 1);

      expect(
        (await tracker.budgets()).single.spent,
        Money.zero,
        reason:
            'October is a new budget, and a server running over midnight on '
            'the 30th would otherwise report September for ever',
      );
    });

    test('and the command line still reads its clock once, in bin/', () {
      final code = File('lib/src/command.dart')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'));

      expect(
        code.where((line) => line.contains('Tracker(store,')).single.trim(),
        'final tracker = Tracker(store, () => today);',
        reason:
            'a command reads the clock once because it is finished before the '
            'day could turn, and the edge that has a Day hands over a function '
            'that keeps answering it',
      );
    });
  });
  // #endregion clock

  // #region unread
  group('the second read study 36 named as friction', () {
    test('is gone, and nothing at the edge asks for a limit again', () {
      final code = File('lib/src/command.dart')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'));

      expect(
        code.where(RegExp(r'tracker\.limits|limitOn\(').hasMatch),
        isEmpty,
        reason:
            'Breach carries the Limit it broke, so the one fact the refusal '
            'message needed arrives with the decision instead of after it',
      );
    });
  });
  // #endregion unread
}
