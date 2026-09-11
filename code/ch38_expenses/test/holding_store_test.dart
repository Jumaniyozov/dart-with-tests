import 'dart:async';
import 'dart:io';

import 'package:ch38_expenses/expenses.dart';
import 'package:test/test.dart';

// #region double
/// A [Store] that answers from a list it lets anyone change, and counts what
/// being asked cost.
///
/// Study 37 wrote a counting double to prove that work **did not** move when
/// the answer got smaller. This one is here to prove that it **does** move, and
/// then that it stops. Same idea, opposite direction, and the reason it is a
/// double rather than a `FileStore` is that a read is a number here and a
/// syscall there.
///
/// [expenses] is public and mutable on purpose. Somebody else changing the
/// answer underneath is the whole subject, and a list is the cheapest stranger
/// there is.
class CountedStore(final List<Expense> expenses) implements Store {
  int reads = 0;
  int limitReads = 0;
  final List<Limit> limitsSet = [];

  @override
  Future<List<Expense>> get all async {
    reads++;
    return List.unmodifiable(expenses);
  }

  @override
  Future<void> record(Expense expense) async => expenses.add(expense);

  @override
  Future<List<Limit>> get limits async {
    limitReads++;
    return List.unmodifiable(limitsSet);
  }

  @override
  Future<void> setLimit(Limit limit) async => limitsSet.add(limit);
}

Expense spent(int pence) =>
    Expense(Money.fromPence(pence), Category('food'), Day(2026, 9, 11), 'tea');
// #endregion double

/// A [Store] whose `all` does not finish until it is let go.
///
/// The only way to ask what happens when the answer changes **during** a read,
/// which is the one ordering a test cannot reach by being quick.
class _Slow(final Future<void> gate, final List<Expense> expenses)
    implements Store {
  int reads = 0;

  @override
  Future<List<Expense>> get all async {
    reads++;
    await gate;
    return List.unmodifiable(expenses);
  }

  @override
  Future<void> record(Expense expense) async => expenses.add(expense);

  @override
  Future<List<Limit>> get limits async => const [];

  @override
  Future<void> setLimit(Limit limit) async {}
}

void main() {
  // #region reads
  group('what a read costs, before and after holding on', () {
    test('every ask is a read, which is what study 28 shipped', () async {
      final counted = CountedStore([spent(450), spent(460)]);

      await counted.all;
      await counted.all;
      await counted.all;

      expect(counted.reads, 3);
    });

    test('and held, three asks are one read', () async {
      final counted = CountedStore([spent(450), spent(460)]);
      final held = HoldingStore(counted, () => 0);

      expect(await held.all, hasLength(2));
      expect(await held.all, hasLength(2));
      expect(await held.all, hasLength(2));

      expect(counted.reads, 1, reason: 'read once, and hold on');
    });

    test('and one GET /budgets is two asks, not one', () async {
      final counted = CountedStore([spent(450)]);

      await Tracker(counted, () => Day(2026, 9, 11)).budgets();

      expect(
        [counted.limitReads, counted.reads],
        [1, 1],
        reason:
            'a budget is a limit and the expenses that count against it, so '
            'the cheapest request this program has still opens the file twice',
      );
    });
  });
  // #endregion reads

  // #region bet
  group('what holding on is a bet about', () {
    test('a version that never moves never looks again', () async {
      final counted = CountedStore([spent(450)]);
      final held = HoldingStore(counted, () => 0);
      expect(await held.all, hasLength(1));

      // Somebody else writes. Not this program, not this isolate — the list is
      // standing in for a file that another process appended to.
      counted.expenses.add(spent(460));

      expect(
        await held.all,
        hasLength(1),
        reason:
            'the held copy is not stale by accident; it was promised that '
            'nothing could change it, and something did',
      );
      expect(counted.reads, 1);
    });

    test('and a version that moves is a reason to look again', () async {
      var version = 0;
      final counted = CountedStore([spent(450)]);
      final held = HoldingStore(counted, () => version);
      expect(await held.all, hasLength(1));

      counted.expenses.add(spent(460));
      version = 1;

      expect(await held.all, hasLength(2));
      expect(counted.reads, 2, reason: 'one more read, and only one');
    });

    test('a write goes through, and the next read finds it', () async {
      var version = 0;
      final counted = CountedStore([]);
      final held = HoldingStore(counted, () => version);
      expect(await held.all, isEmpty);

      await held.record(spent(450));
      version = 1;

      expect(await held.all, hasLength(1));
    });
  });
  // #endregion bet

  group('a write that lands while a read is in flight', () {
    test('is never held as though it had been seen', () async {
      var version = 0;
      final gate = Completer<void>();
      final slow = _Slow(gate.future, [spent(450)]);
      final held = HoldingStore(slow, () => version);

      final reading = held.all;
      // The read has started and has not finished. Somebody appends.
      slow.expenses.add(spent(460));
      version = 1;
      gate.complete();
      await reading;

      expect(
        await held.all,
        hasLength(2),
        reason:
            'the version is taken before the read, not after, so a write that '
            'lands in the middle of one is stamped as unseen and the next ask '
            'goes back for it — an extra read, and never a stale answer',
      );
      expect(slow.reads, 2);
    });
  });

  // #region twinned
  group('the two servers, and exactly what is different about them', () {
    /// One file's lines, without its comments or its blanks.
    List<String> code(String path) => [
      for (final line in File(path).readAsLinesSync())
        if (line.trim().isNotEmpty && !line.trimLeft().startsWith('//')) line,
    ];

    test('one line each way, and it is where the length is read', () {
      final serve = code('bin/serve.dart').toSet();
      final holding = code('bin/holding.dart').toSet();

      expect(serve.difference(holding), {
        '    HoldingStore(FileStore(file), () => _lengthOf(file)),',
      });
      expect(holding.difference(serve), {
        '  final length = _lengthOf(file);',
        '    HoldingStore(FileStore(file), () => length),',
      });
    });
  });
  // #endregion twinned

  // #region length
  group('the number bin/serve.dart asks for, and what it misses', () {
    late Directory directory;
    late File file;
    setUp(() {
      directory = Directory.systemTemp.createTempSync('holding');
      file = File('${directory.path}/expenses.txt');
    });
    tearDown(() => directory.deleteSync(recursive: true));

    test('a file that is not there yet is a real answer, and moves', () async {
      final held = HoldingStore(
        FileStore(file),
        () => file.existsSync() ? file.lengthSync() : 0,
      );

      expect(await held.all, isEmpty, reason: 'which is what FileStore says');
      await held.record(spent(450));

      expect(
        await held.all,
        hasLength(1),
        reason:
            'nothing is not an error, it is version 0 — and the first line '
            'written moves it, so the held empty list is thrown away',
      );
    });

    test('and every line this program writes makes it longer', () async {
      final store = FileStore(file);
      final lengths = <int>[];

      await store.record(spent(450));
      lengths.add(file.lengthSync());
      await store.setLimit(Limit(Category('food'), Money.fromPence(2000)));
      lengths.add(file.lengthSync());
      await store.record(spent(460));
      lengths.add(file.lengthSync());

      expect(
        lengths,
        [lengths[0], greaterThan(lengths[0]), greaterThan(lengths[1])],
        reason:
            'this store only ever appends, which is what makes a byte count an '
            'exact answer to "has it changed?" rather than a guess',
      );
    });

    test('but a rewrite that keeps the length is invisible to it', () {
      file.writeAsStringSync(
        '{"kind":"limit","category":"food","pence":2000}\n',
      );
      final before = file.lengthSync();

      file.writeAsStringSync(
        '{"kind":"limit","category":"food","pence":9000}\n',
      );

      expect(
        file.lengthSync(),
        before,
        reason:
            'a person editing the file by hand is the case a byte count cannot '
            'see, and study 39 is where the cache stops being needed at all',
      );
    });
  });
  // #endregion length
}
