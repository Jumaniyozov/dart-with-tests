import 'budget.dart';
import 'day.dart';
import 'expense.dart';
import 'period.dart';
import 'store.dart';

// #region alone
/// Something that runs a body with nothing else writing underneath it.
///
/// **A generic function type, because the body is not [Tracker.record]'s to
/// keep.** `Future<Verdict?> Function(...)` would have been enough for the one
/// caller there is, and would have been a guess about the next one — the same
/// mistake as an optional parameter nobody passes, spelled in a return type.
/// Study 39's first challenge asked the reader to write `atomically<T>` over a
/// `Database`; this is that shape with the database taken out of it.
///
/// And taking it out is the whole reason this is a function rather than a
/// member on [Store]. Study 28 settled what an interface may promise: the
/// weakest implementation's promise is the interface's promise, which is why
/// every member of `Store` answers a `Future` for `FileStore`'s sake. A
/// `Store.alone` would have had to promise the opposite direction — more than
/// `FileStore` can keep — and the two implementations that could keep it would
/// have been carrying a member the one that could not was lying about.
///
/// So it is handed in, exactly the way study 38 handed in the clock. The thing
/// that can really make a unit of work is the database, `bin/` is where this
/// program decides which database it has, and `bin/` is therefore where it is
/// decided whether anything is guaranteed at all.
typedef Alone = Future<T> Function<T>(Future<T> Function() body);

/// Run [body], and promise nothing about what else runs while it does.
///
/// **The honest default, and the name is the documentation.** A [Tracker] built
/// with this one is a tracker whose read-decide-write can be interleaved by
/// anything that gets a turn in the middle of it — which, measured, is nothing
/// at all when the store never suspends, and everything when it does. That
/// difference is a property of the store rather than of this program, and a
/// program should not rely on a property it does not state.
///
/// It is what the tests use, because a test with one store and one caller has
/// no second writer to exclude, and it is what nothing under `bin/` uses.
Future<T> unguarded<T>(Future<T> Function() body) => body();
// #endregion alone

// #region tracker
/// Everything this program can be asked to do, in the vocabulary of the thing
/// it does it to.
///
/// **The parameters are study 27's seams, and nothing else.** That study threaded
/// a [Store] and a [Day] through every private function in `command.dart` so the
/// tests would need no mocks and no clock. Four studies later a second edge
/// arrives, needs the same use cases, and cannot reach them — and the two values
/// it has to be handed are exactly those two. A seam cut for testability turned
/// out to be the boundary of a layer, which is the only way this book has ever
/// found one.
///
/// **What it does not have is the interesting half.** No `Outcome`, because an
/// exit code and a line of English are one caller's idea of an answer. No
/// `int.parse`, because reading what somebody typed belongs to whoever they
/// typed it at. No `dart:io` and no `shelf`. The names in these signatures are
/// the ones `CONTEXT.md` already had, which is the test of whether a layer is
/// really the application's or just the first caller's spread out.
///
/// The header constructor form, by ADR 0002's rule rather than by preference: a
/// [Tracker] checks nothing, because a `Store` and a clock are already-valid
/// values by the time they reach it. ADR 0005 predicted that putting a function
/// in a header parameter would change none of that, and it does not.
///
/// **[alone] is a transaction since study 40, and it is required on purpose.**
/// Book III declared at study 37 that two callers could both pass the budget
/// check, and study 39 closed that by accident: `SqliteStore` reaches C through
/// `dart:ffi`, so nothing in [record] suspends and nothing can get in. Measured
/// — 0 breaches in 40 trials at two, three and four callers. An accident is not
/// a rule, and the second writer that is still real is in another **process**,
/// where no argument about this program's event loop reaches.
///
/// So the boundary is a parameter with no default. A default of [unguarded]
/// would have let every call site keep the guarantee it happened to have, which
/// is exactly the state study 39 shipped in.
///
/// **[today] is a function since study 38, and the parentheses are the lesson.**
/// It used to be a `Day`, read once by whoever built the tracker — correct for a
/// command that lives for milliseconds and wrong for a server that runs for
/// days, which would file Friday's expenses under the Tuesday it started on.
/// Study 28 said a signature is a promise about time; `Day today` promised that
/// the day never changes, and it does. Every place that reads it now says, in
/// one character, that it is asking rather than remembering.
class Tracker(
  final Store store,
  final Day Function() today,
  final Alone alone,
) {
  /// Keep an expense, unless a budget refuses it.
  ///
  /// Answers what the budget on that category said — `null` when nobody set
  /// one, which is [limitOn]'s own way of saying it. A [Breach] the expense
  /// does not acknowledge is a **refusal**: nothing is kept, and the caller is
  /// told by how much, in money rather than in a sentence.
  ///
  /// The acknowledgement is read off the [Expense] rather than taken as a
  /// second argument, because study 32 already put it there. An acknowledged
  /// overspend is a different kind of expense, not a different way of calling
  /// this.
  Future<Verdict?> record(Expense expense) => alone(() async {
    final limit = limitOn(expense.category, await store.limits);
    final month = Period.of(expense.day);
    final verdict = limit == null
        ? null
        : Budget.of(
            limit,
            month,
            // The month the expense falls in, asked for rather than sieved out
            // of everything. This call read the whole history until study 39,
            // and it is the read a budget check does on **every write**.
            await store.expenses(period: month),
          ).on(expense);
    if (verdict.refuses(expense)) return verdict;
    await store.record(expense);
    return verdict;
  });

  /// Set the limit on a category, replacing any limit already on it.
  Future<void> setLimit(Limit limit) => store.setLimit(limit);

  /// Every limit currently in force.
  Future<List<Limit>> get limits => store.limits;

  /// What has been recorded, all of it or one period of it, all of that or
  /// only the first [count].
  ///
  /// **It used to do the narrowing and now it passes it on**, which is the
  /// whole of 39.5. The sieve that lived here could only run after the store
  /// had already found every expense there was; [Store.expenses] takes the
  /// question instead, and what a store can do with it is the store's business.
  ///
  /// What is left is a one-line delegation, and that is the right amount of
  /// layer for this member. [record] and [budgets] below are where a [Tracker]
  /// does something a store cannot.
  Future<List<Expense>> expenses({Period? period, int? count}) =>
      store.expenses(period: period, count: count);

  /// Every budget in force, over the period the day it is now falls in.
  ///
  /// No parameter, because nothing asks for another period yet. Adding one is
  /// an optional argument and no caller moves — the same reasoning ADR 0002
  /// records for a check that arrives after a type has shipped.
  Future<List<Budget>> budgets() async {
    final month = Period.of(today());
    return budgetsFor(
      await store.limits,
      month,
      await store.expenses(period: month),
    );
  }
}
// #endregion tracker
