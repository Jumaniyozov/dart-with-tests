import 'category.dart';
import 'expense.dart';
import 'money.dart';
import 'period.dart';

// #region limit
/// A limit somebody set on one category.
///
/// The stored half of a budget, and the only half a person types. It says
/// nothing about any particular month — a limit set once is meant to apply
/// every month, which is how people talk about budgets and why this is not a
/// [Budget] on its own.
class const Limit._(final Category category, final Money amount) {
  /// The only door in, and it refuses the one amount [Money] is happy to hold.
  ///
  /// Nothing is wrong with £0.00 as *money*, so `Money` lets it through. It is
  /// wrong as a *limit*: a budget of nothing is not a rule somebody set, it is
  /// the absence of one. 32.1's rule of thumb says where that check goes — a
  /// limit is the smallest thing that can see its own amount — and putting it
  /// here rather than at each edge is what keeps a `Limit` this program can
  /// build from being one it cannot read back.
  ///
  /// It throws for the reason [Money.fromPence] does: both are handed a value
  /// by *code*, and code getting this wrong is a bug rather than a typo. The
  /// two edges that take the amount from outside ask first, so no caller has
  /// to catch anything — `budget` at the terminal answers an exit code, and
  /// [limitFromJson] answers `null`.
  factory Limit(Category category, Money amount) {
    if (amount == Money.zero) {
      throw ArgumentError.value(
        amount.pence,
        'amount',
        'a budget of nothing is not a budget',
      );
    }
    return Limit._(category, amount);
  }

  /// Two keys and a `kind`, which is new.
  ///
  /// Study 29's file held one shape and needed no way to say which. It holds
  /// two now, so the new one announces itself and the old one stays exactly as
  /// it was — every file study 29 or 30 wrote still reads.
  Map<String, Object?> toJson() => {
    'kind': 'limit',
    'category': category.name,
    'pence': amount.pence,
  };

  @override
  bool operator ==(Object other) =>
      other is Limit && other.category == category && other.amount == amount;

  @override
  int get hashCode => Object.hash(category, amount);

  @override
  String toString() => '$category: ${amount.asText}';
}

/// One decoded JSON value back into a limit, or `null` when it is not one.
///
/// `'kind': 'limit'` in a map pattern is a **constant** pattern where the
/// others are variable patterns: it does not bind anything, it just has to
/// match. That one line is what keeps an expense from being read as a limit.
///
/// The `when` clause asks what [Limit] would refuse, before [Limit] is built —
/// the same shape as `readMoney` asking about the sign before calling
/// [Money.fromPence]. A file somebody edited by hand is not a bug in this
/// program, so it answers `null` rather than throwing.
Limit? limitFromJson(Object? json) => switch (json) {
  {'kind': 'limit', 'category': final String category, 'pence': final int pence}
      when pence > 0 && category.trim().isNotEmpty =>
    Limit(Category(category), Money.fromPence(pence)),
  _ => null,
};
// #endregion limit

// #region verdict
/// What a budget says about an expense it has not been given yet.
///
/// `sealed`, so a `switch` over it is checked for completeness — study 16's
/// rule, and study 26's: a breach is an **expected** outcome of using this
/// program correctly, so it comes back as a value the caller must look at.
sealed class const Verdict();

/// It fits, and this is what would be left afterwards.
final class const Within(final Money remaining) extends Verdict {}

/// It does not fit, and this is by how much.
final class const Breach(final Money over) extends Verdict {}
// #endregion verdict

// #region budget
/// A limit, and the expenses that count against it.
///
/// **This is the first rule in the program that no single object can check.**
/// `Money` checks itself: it knows its own sign. `Category` normalises itself.
/// `Day` knows how many days February has. Every invariant so far has fitted
/// inside one object because everything it needed was inside that object.
///
/// A limit of £200 on food for September is not like that. An [Expense] cannot
/// tell you whether it breaks it — a £30 lunch is fine in an empty month and
/// not fine in a full one. A [Limit] cannot either; it has never met an
/// expense. The rule needs the limit *and* every expense in that category in
/// that month, all at once, and the smallest thing that can see all of that is
/// this.
///
/// That cluster has a name — a **consistency boundary** — and the name is worth
/// exactly one sentence. What matters is the mechanical consequence: the rule
/// lives here because here is where the facts are, and gathering those facts is
/// what [Budget.of] is for.
class const Budget._(
  final Limit limit,
  final Period period,
  final List<Expense> counted,
) {
  /// Gather what the rule needs and nothing else.
  ///
  /// Everything else in the store — other categories, other months — has no
  /// bearing on this limit, and leaving it out is the difference between a
  /// boundary and a pile.
  factory Budget.of(Limit limit, Period period, Iterable<Expense> all) =>
      Budget._(limit, period, [
        for (final expense in all)
          if (expense.category == limit.category &&
              period.contains(expense.day))
            expense,
      ]);

  /// The category this budget is about, which is its limit's.
  Category get category => limit.category;

  /// Everything counted against the limit, added up.
  Money get spent =>
      counted.fold(Money.zero, (sum, expense) => sum + expense.amount);

  /// What is left, or `null` when the limit has already been passed.
  ///
  /// The `null` is [Money.operator -] doing its job. There is no amount of
  /// money that means "£12.50 overspent", so the type does not pretend there
  /// is one.
  Money? get remaining => limit.amount - spent;

  /// Whether the limit has already been passed.
  bool get isBroken => remaining == null;

  /// What this budget says about one more expense.
  Verdict on(Expense expense) {
    final after = spent + expense.amount;
    final left = limit.amount - after;
    if (left != null) return Within(left);
    // `left` being null is exactly the statement that `after` is the larger of
    // the two, so this subtraction is the one that goes.
    return Breach((after - limit.amount)!);
  }

  /// How a budget reads in a report.
  String get asText => switch (remaining) {
    final Money left =>
      '$category: ${spent.asText} of '
          '${limit.amount.asText}, ${left.asText} left',
    null =>
      '$category: ${spent.asText} of ${limit.amount.asText}, '
          '${(spent - limit.amount)!.asText} over',
  };
}

/// The limit set on one category, or `null` when nobody set one.
///
/// A loop rather than `firstWhere`, which throws when it finds nothing, and
/// rather than `firstOrNull`, which lives in `package:collection` and is not a
/// dependency this study is willing to take for a loop this short. Study 33 is
/// where taking one gets argued properly.
Limit? limitOn(Category category, Iterable<Limit> limits) {
  for (final limit in limits) {
    if (limit.category == category) return limit;
  }
  return null;
}

/// Every budget that applies to a period, in the order the limits were set.
List<Budget> budgetsFor(
  Iterable<Limit> limits,
  Period period,
  Iterable<Expense> expenses,
) => [for (final limit in limits) Budget.of(limit, period, expenses)];
// #endregion budget

// #region refuses
/// Whether a verdict stands in the way of an expense actually being recorded.
///
/// A [Breach] does, unless the expense itself says somebody was told and said
/// record it anyway. Everything else — a [Within], or the `null` that means
/// nobody set a limit — does not.
///
/// **Written down because study 36 asked it twice.** `Tracker.record` asks it
/// to decide whether to write; the command line asks it to decide what to tell
/// the person. Two copies of one condition is the shape study 32 found inside
/// `Limit`, where the `budget` command and `limitFromJson` each enforced a rule
/// the type between them did not have. The answer is the same both times: when
/// the same condition is written in two places, neither of them is the owner.
///
/// It takes the [Expense] rather than a `bool` because that is where study 32
/// put the acknowledgement, and a parameter called `acknowledged` next to an
/// expense that already has one is two places again.
bool refuses(Verdict? verdict, Expense expense) =>
    verdict is Breach && !expense.acknowledged;
// #endregion refuses
