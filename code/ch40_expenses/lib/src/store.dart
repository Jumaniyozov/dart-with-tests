import 'budget.dart';
import 'category.dart';
import 'expense.dart';
import 'period.dart';

// #region store
/// What holds expenses.
///
/// Deliberately not a *ledger*: a ledger is double-entry, with every amount
/// appearing twice, and this is not that.
///
/// **Every member returns a `Future` since study 28**, and that is a change
/// to what the interface promises rather than to how it is implemented. A
/// signature is a claim about time: `void record(Expense)` says the expense is
/// kept by the moment the call returns. A file cannot say that without stopping
/// the program to prove it, so the promise had to be the weaker, truer one.
///
/// `InMemoryStore` pays nothing for this — it is done before it returns and
/// says so by returning an already-completed future. It is [FileStore] that
/// needed the room. [SqliteStore] pays nothing either, and for a reason worth
/// noticing: it talks to a C library over `dart:ffi`, which is a function call
/// rather than an event loop, so every one of its answers is ready before it
/// returns. The weaker promise cost the store that could not keep the stronger
/// one, and the two that could kept it anyway.
///
/// **Four members since study 32, and the two new ones cost something.**
/// Study 27 said it in as many words: implement a class's interface and you are
/// coupled to every member it grows later. `Store` is an `interface class` on
/// purpose, so growing it is allowed — and every double in the book stopped
/// compiling the moment these two lines appeared. That is the bill study 27
/// described, itemised in 32.4.
///
/// `totals` is not among them. It used to hang off this type and does not any
/// more: it was derived from the expenses rather than from the store, and study
/// 31 finished moving it into `Report`.
abstract interface class Store {
  /// Keep an expense. The future completes when it is kept.
  Future<void> record(Expense expense);

  /// What has been recorded, in the order it arrived.
  ///
  /// **This was `all` until study 39, and losing that name is the study.**
  /// `all` is the only question a store cannot be clever about: however the
  /// expenses are kept, answering it means handing over every one of them. The
  /// HTTP edge had a `?limit=` that could only throw most of them away *after*
  /// the store had already found them, and study 37 measured that with a
  /// counting double — a thousandth of the document for the same work.
  ///
  /// A bound is not something a store can keep unless it is asked for, so both
  /// narrowings arrive here together. [period] and [count] are each `null` for
  /// *no bound of that kind*, so `expenses()` is the old `all` and no caller
  /// that wanted everything has to say so.
  ///
  /// **[count] is the first [Expense] in, not the last.** It bounds the answer
  /// rather than choosing which end of it, because the list route's job is to
  /// stop sending a megabyte and not to decide what is interesting.
  Future<List<Expense>> expenses({Period? period, int? count});

  /// Set the limit on a category, replacing any limit already on it.
  Future<void> setLimit(Limit limit);

  /// Every limit currently in force, one per category.
  Future<List<Limit>> get limits;
}
// #endregion store

// #region memory
/// A [Store] that keeps everything in a list and forgets it when the program
/// stops. [SqliteStore] is the one that does not.
///
/// This is the **fake** the tests use. A fake implements the behaviour, so a
/// test that uses it asks what the program did rather than which methods it
/// happened to call.
///
/// `async` on a method that never waits for anything is not a lie and not a
/// cost. It wraps the answer in a future that is already complete, which is
/// what the interface asks for and all it asks for.
class InMemoryStore implements Store {
  final List<Expense> _recorded = [];

  @override
  Future<void> record(Expense expense) async => _recorded.add(expense);

  /// Both bounds applied in Dart, because a list has nowhere else to apply
  /// them. That is the honest version of this implementation and it is also the
  /// measurement study 39 makes: the work of narrowing has to happen somewhere,
  /// and what a database buys is somewhere better than here.
  ///
  /// `List.unmodifiable` copies once and hands back a list that throws if
  /// anyone calls `add` on it. Returning `_recorded` itself would hand callers
  /// the store's own list and let them change it behind its back.
  @override
  Future<List<Expense>> expenses({Period? period, int? count}) async {
    final wanted = [
      for (final expense in _recorded)
        if (period == null || period.contains(expense.day)) expense,
    ];
    return List.unmodifiable(
      count == null ? wanted : wanted.take(count).toList(),
    );
  }

  /// A map and not a list, because setting a limit twice is setting it, not
  /// setting two of them. The file has to work harder for the same guarantee,
  /// and a table gets it back from a primary key.
  final Map<Category, Limit> _limits = {};

  @override
  Future<void> setLimit(Limit limit) async => _limits[limit.category] = limit;

  @override
  Future<List<Limit>> get limits async => List.unmodifiable(_limits.values);
}
// #endregion memory
