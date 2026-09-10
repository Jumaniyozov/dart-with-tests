// Study 27 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are about seams. The first two implement the [Store] interface the
// study introduced, and the third makes a seam without an interface at all.

import 'package:ch27_expenses/expenses.dart';

/// 1. A second store, with a different mind about what to keep.
///
///    [CappedStore] holds at most [limit] expenses. Record one more and the
///    oldest is dropped, so `all` is the most recent [limit], oldest first.
///
///    A `limit` below one is a bug in the calling program, not a person
///    mistyping, so the constructor throws an [ArgumentError] — study 26's
///    rule, applied to a number no user ever types.
///
///    Nothing in `run` changes, and nothing in `run` finds out. That is what
///    the interface bought.
class CappedStore implements Store {
  CappedStore(this.limit);

  final int limit;

  @override
  void record(Expense expense) => throw UnimplementedError('challenge 1');

  @override
  List<Expense> get all => throw UnimplementedError('challenge 1');
}

/// 2. A store that sits in front of another one.
///
///    [CountingStore] wraps any [Store] and passes everything through,
///    counting the calls to `record` on the way past. Because [Store] is an
///    interface and not a class, this can go between the program and its
///    store without either of them knowing.
///
///    `records` starts at zero. `all` is whatever the wrapped store says, and
///    reading it does not change the count.
class CountingStore implements Store {
  CountingStore(this.inner);

  final Store inner;

  int records = 0;

  @override
  void record(Expense expense) => throw UnimplementedError('challenge 2');

  @override
  List<Expense> get all => throw UnimplementedError('challenge 2');
}

/// 3. A seam that needs no interface.
///
///    [describeDay] says where a day sits relative to another: `'today'` when
///    they are the same day, `'in the past'` when [day] is earlier than
///    [today], and `'in the future'` when it is later.
///
///    It takes `today` rather than reading a clock, which is the whole reason
///    every branch of it can be tested. Comparing the day of the month alone
///    is the trap: December 2025 is not in the future of January 2026.
String describeDay(Day day, Day today) =>
    throw UnimplementedError('challenge 3');
