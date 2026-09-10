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
  final String note, {

  /// Whether somebody was told this would break a budget and said record it
  /// anyway.
  ///
  /// Study 32 added it, and it defaults to `false` so that every `Expense`
  /// built before this study still compiles. An acknowledged overspend is a
  /// **different thing** from an ordinary expense — the program refuses the
  /// unacknowledged kind and never refuses to write down what somebody
  /// actually spent — and a different thing needs somewhere to be different.
  final bool acknowledged = false,
}) {
  String get asText =>
      '${day.asText}  ${amount.asText}  $category  $note'
      '${acknowledged ? '  (over budget)' : ''}';
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
  /// The fifth key is written only when it is true.
  ///
  /// A null-aware element would not help here — the value is a `bool` and not
  /// a `bool?` — so this is a collection-`if`, which is the same idea one
  /// study earlier. Leaving the key out when it is false means every line this
  /// program writes for an ordinary expense is byte-identical to the line
  /// study 29 wrote, which is a promise worth keeping to anybody's existing
  /// file.
  Map<String, Object?> toJson() => {
    'day': day.asText,
    'pence': amount.pence,
    'category': category.name,
    'note': note,
    if (acknowledged) 'acknowledged': true,
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
    _assembled(
      day,
      pence,
      category,
      note,
      // Read off the matched map rather than bound by the pattern, because a
      // map pattern has no way to say *this key is optional*: putting
      // `'acknowledged': final bool ack` above would refuse every line study
      // 29 and 30 ever wrote. An absent key and a `false` mean the same thing
      // here, which is exactly when this is safe.
      acknowledged: (json as Map<String, Object?>)['acknowledged'] == true,
    ),
  _ => null,
};

/// The four fields, once they are known to be the right *types*, checked for
/// being the right *values*.
///
/// `1250` is an `int` and so is `-1250`, and only one of them is money. The
/// pattern above answers what JSON knows; this answers what the domain knows.
Expense? _assembled(
  String day,
  int pence,
  String category,
  String note, {
  required bool acknowledged,
}) {
  final on = Day.parse(day);
  if (on == null || pence < 0 || category.trim().isEmpty) return null;
  return Expense(
    Money.fromPence(pence),
    Category(category),
    on,
    note,
    acknowledged: acknowledged,
  );
}
// #endregion json
