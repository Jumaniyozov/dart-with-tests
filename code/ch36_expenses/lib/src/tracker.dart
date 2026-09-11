import 'budget.dart';
import 'day.dart';
import 'expense.dart';
import 'period.dart';
import 'store.dart';

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
/// [Tracker] checks nothing, because a `Store` and a `Day` are already-valid
/// values by the time they reach it.
class Tracker(final Store store, final Day today) {
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
  Future<Verdict?> record(Expense expense) async {
    final limit = limitOn(expense.category, await store.limits);
    if (limit == null) {
      await store.record(expense);
      return null;
    }
    final verdict = Budget.of(
      limit,
      Period.of(expense.day),
      await store.all,
    ).on(expense);
    if (verdict is Breach && !expense.acknowledged) return verdict;
    await store.record(expense);
    return verdict;
  }

  /// Set the limit on a category, replacing any limit already on it.
  Future<void> setLimit(Limit limit) => store.setLimit(limit);

  /// Every limit currently in force.
  Future<List<Limit>> get limits => store.limits;

  /// What has been recorded, all of it or one period of it.
  Future<List<Expense>> expenses([Period? period]) async => [
    for (final expense in await store.all)
      if (period == null || period.contains(expense.day)) expense,
  ];

  /// Every budget in force, over the period given or the one [today] is in.
  Future<List<Budget>> budgets([Period? period]) async => budgetsFor(
    await store.limits,
    period ?? Period.of(today),
    await store.all,
  );
}
// #endregion tracker
