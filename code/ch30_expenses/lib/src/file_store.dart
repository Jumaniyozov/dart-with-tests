import 'dart:convert';
import 'dart:io';

import 'expense.dart';
import 'store.dart';

// #region filestore
/// A [Store] that keeps expenses in a file, one JSON object to a line.
///
/// The only type under `lib/` that has heard of `dart:io`. Everything else in
/// the package still works on `Store`, so the program does not know whether it
/// is talking to a disk or to a list — which is the whole point of study 27.
///
/// **One object per line, and not one array holding all of them.** An array is
/// the more usual shape for a JSON file and it cannot be added to: you would
/// read every expense, put one on the end, and write every expense back, on
/// every single `add`. A line can be appended, which is what study 28's
/// `FileMode.append` bought and this study is not giving back.
class FileStore(final File file) implements Store {
  @override
  Future<void> record(Expense expense) async {
    await file.parent.create(recursive: true);
    final line = jsonEncode(expense.toJson());
    await file.writeAsString('$line\n', mode: FileMode.append);
  }

  @override
  Future<List<Expense>> get all async {
    if (!await file.exists()) return const [];
    final text = await file.readAsString();
    return [
      for (final line in const LineSplitter().convert(text))
        ?_expenseFrom(line),
    ];
  }

  /// One line back into an expense, or `null` for a line this program cannot
  /// read.
  ///
  /// The `catch` is the first one in `lib/` since study 26 took them all out,
  /// and it earns its place. `jsonDecode` throws a `FormatException` for text
  /// that is not JSON, `FormatException` is an `Exception` and not an `Error`,
  /// and a person who opened this file in an editor is the world being awkward
  /// rather than a bug in this program. There is also no way to ask first:
  /// deciding whether text is JSON *is* parsing it.
  static Expense? _expenseFrom(String line) {
    try {
      return expenseFromJson(jsonDecode(line));
    } on FormatException {
      return null;
    }
  }
}
// #endregion filestore
