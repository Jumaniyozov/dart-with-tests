import 'category.dart';
import 'day.dart';
import 'money.dart';

// #region expense
/// Money out: what it cost, what it was for, when, and a note.
///
/// Notice what this class does **not** have: an `operator ==`. That is the
/// decision this study exists to explain. Two coffees at £3.20 on the same day
/// are two expenses, not one recorded twice, so an `Expense` is equal only to
/// itself.
///
/// Everything in it is `final`, and an expense is a record of something that
/// already happened. Correcting a mistake means recording a correction, not
/// rewriting the past.
class const Expense(
  final Money amount,
  final Category category,
  final Day day,
  final String note,
) {
  String get asText => '${day.asText}  ${amount.asText}  $category  $note';
}
// #endregion expense

// #region json
/// Turning an [Expense] into JSON and back.
///
/// An extension and not members, for study 27's reason: this is how the tracker
/// happens to be stored, and a store that kept expenses in a database would want
/// none of it. `Expense` is the thing; this is one thing done to it.
extension ExpenseJson on Expense {
  /// The shape `jsonEncode` will accept.
  ///
  /// Flat, and four keys of the plainest types JSON has. `Money`, `Category` and
  /// `Day` all know how to write themselves down as a number or a string
  /// already, so nothing here invents a representation.
  Map<String, Object?> toJson() => {
    'day': day.asText,
    'pence': amount.pence,
    'category': category.name,
    'note': note,
  };
}

/// One decoded JSON value back into an expense, or `null` when it is not one.
///
/// **This is the line where the analyzer stops helping.** `jsonDecode` hands
/// back `dynamic`, so every field is whatever the file said it was, and a plain
/// `json['pence'] as int` on a file somebody edited throws a `TypeError` —
/// which is an `Error`, which study 26 says must not be caught.
///
/// A **map pattern** is the cast that checks. `{'pence': final int pence}`
/// matches only if the key is there *and* the value really is an `int`, so a
/// wrong type falls through to `null` instead of throwing. Extra keys are
/// ignored, which is what lets a later version of this program add a field
/// without this one refusing to read the file.
Expense? expenseFromJson(Object? json) => switch (json) {
  {
    'day': final String day,
    'pence': final int pence,
    'category': final String category,
    'note': final String note,
  } =>
    _assembled(day, pence, category, note),
  _ => null,
};

/// The four fields, once they are known to be the right *types*, checked for
/// being the right *values*.
///
/// `1250` is an `int` and so is `-1250`, and only one of them is money. The
/// pattern above answers what JSON knows; this answers what the domain knows.
Expense? _assembled(String day, int pence, String category, String note) {
  final on = Day.parse(day);
  if (on == null || pence < 0 || category.trim().isEmpty) return null;
  return Expense(Money.fromPence(pence), Category(category), on, note);
}
// #endregion json

// #region totals
/// What was spent on each category.
///
/// **An extension on the expenses, not on the store.** Study 27 put this on
/// `Store` to keep it off the interface, and said in as many words that the
/// position was temporary. This is the move it was waiting for: the totals are
/// derived from a list of expenses and have never needed to know where that
/// list came from, so a caller holding *some* of a store's expenses — one
/// month of them, say — can ask exactly the same question.
///
/// Notice what came off with it. Hanging off `Store`, this had to be
/// `Future<Map<Category, Money>>`, because reaching the expenses meant
/// awaiting. Study 28 called `async` contagious and it is, but the contagion
/// travels along calls, and this no longer makes one. Given the expenses,
/// adding them up was never asynchronous work.
extension Totals on Iterable<Expense> {
  /// This is the map that makes [Category]'s `==` and `hashCode` load-bearing.
  /// Get either of them wrong and one category quietly becomes two rows.
  Map<Category, Money> get totals {
    final sums = <Category, int>{};
    for (final expense in this) {
      sums[expense.category] =
          (sums[expense.category] ?? 0) + expense.amount.pence;
    }
    return {
      for (final entry in sums.entries) entry.key: Money.fromPence(entry.value),
    };
  }
}
// #endregion totals
