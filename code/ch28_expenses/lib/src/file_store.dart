import 'dart:io';

import 'category.dart';
import 'day.dart';
import 'expense.dart';
import 'money.dart';
import 'store.dart';

// #region filestore
/// A [Store] that keeps expenses in a text file, one to a line.
///
/// The only type under `lib/` that has heard of `dart:io`. Everything else in
/// the package still works on `Store`, so the program does not know whether it
/// is talking to a disk or to a list — which is the whole point of study 27.
class FileStore(final File file) implements Store {
  /// Add one line to the end of the file, making the file — and the directory
  /// it lives in — if this is the first expense ever recorded.
  ///
  /// `FileMode.append` is not a detail. **`writeAsString` truncates by
  /// default**: write "one" and then "two" and the file holds "two". Measured,
  /// and it would silently lose every expense but the last.
  @override
  Future<void> record(Expense expense) async {
    await file.parent.create(recursive: true);
    await file.writeAsString('${_lineFor(expense)}\n', mode: FileMode.append);
  }

  @override
  Future<List<Expense>> get all async {
    // A file that was never written is not an error. Nobody has recorded
    // anything yet, which is an ordinary state of the world and answered with
    // an empty list rather than an exception.
    if (!await file.exists()) return const [];
    final text = await file.readAsString();
    // `?` before an element drops it when it is null — the null-aware element,
    // which `use_null_aware_elements` insists on over an `if (… case …?)`.
    return [for (final line in text.split('\n')) ?_expenseFrom(line)];
  }

  static String _lineFor(Expense expense) => [
    expense.day.asText,
    expense.amount.pence,
    expense.category,
    expense.note,
  ].join(',');

  /// One line back into an expense, or `null` for a line this program did not
  /// write.
  ///
  /// The list pattern is study 14's, and it counts. **Exactly four fields, or
  /// no expense** — so the last line of every file, which is empty because
  /// every line ends in a newline, falls through to `null` and is skipped.
  ///
  /// It also means the format cannot carry two characters, and the two fail
  /// differently. A comma in a note makes five fields, nothing matches, and the
  /// expense disappears. A **newline** in a note splits it across two lines,
  /// and the first four fields still line up — so it reads back as an ordinary
  /// expense with half its note missing and nothing anywhere saying so.
  ///
  /// Both are real defects and both are left in on purpose. 28.5 says what they
  /// cost and study 29 is the repair.
  static Expense? _expenseFrom(String line) => switch (line.split(',')) {
    [final day, final pence, final category, final note] => Expense(
      Money.fromPence(int.parse(pence)),
      Category(category),
      Day(
        int.parse(day.substring(0, 4)),
        int.parse(day.substring(5, 7)),
        int.parse(day.substring(8, 10)),
      ),
      note,
    ),
    _ => null,
  };
}
// #endregion filestore
