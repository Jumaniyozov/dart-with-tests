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
/// [Tracker] checks nothing, because a `Store` and a clock are already-valid
/// values by the time they reach it. ADR 0005 predicted that putting a function
/// in a header parameter would change none of that, and it does not.
///
/// **[today] is a function since study 38, and the parentheses are the lesson.**
/// It used to be a `Day`, read once by whoever built the tracker — correct for a
/// command that lives for milliseconds and wrong for a server that runs for
/// days, which would file Friday's expenses under the Tuesday it started on.
/// Study 28 said a signature is a promise about time; `Day today` promised that
/// the day never changes, and it does. Every place that reads it now says, in
/// one character, that it is asking rather than remembering.
class Tracker(final Store store, final Day Function() today) {
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
    final verdict = limit == null
        ? null
        : Budget.of(limit, Period.of(expense.day), await store.all).on(expense);
    if (verdict.refuses(expense)) return verdict;
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

  /// Every budget in force, over the period the day it is now falls in.
  ///
  /// No parameter, because nothing asks for another period yet. Adding one is
  /// an optional argument and no caller moves — the same reasoning ADR 0002
  /// records for a check that arrives after a type has shipped.
  Future<List<Budget>> budgets() async =>
      budgetsFor(await store.limits, Period.of(today()), await store.all);
}
// #endregion tracker
