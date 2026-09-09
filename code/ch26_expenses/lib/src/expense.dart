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
