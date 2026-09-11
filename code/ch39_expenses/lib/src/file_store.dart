import 'dart:convert';
import 'dart:io';

import 'budget.dart';
import 'category.dart';
import 'expense.dart';
import 'period.dart';
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

  /// **A bound it can half keep, which is the interesting answer.**
  ///
  /// [_lines] has already read the whole file into memory by the time this loop
  /// starts, so the `break` saves the JSON decoding of everything past [count]
  /// and saves nothing at all of the reading. That is the middle of the three
  /// answers this book now has to the same question: `InMemoryStore` saves
  /// nothing, this saves the decoding, and `SqliteStore` never looks at the
  /// rows it was not asked for.
  ///
  /// A loop rather than a collection-`for`, because there are three reasons to
  /// skip a line and one to stop reading them, and a `break` is the one of the
  /// four a comprehension has no way to say.
  @override
  Future<List<Expense>> expenses({Period? period, int? count}) async {
    final wanted = <Expense>[];
    for (final line in await _lines) {
      final expense = _expenseFrom(line);
      if (expense == null) continue;
      if (period != null && !period.contains(expense.day)) continue;
      wanted.add(expense);
      if (wanted.length == count) break;
    }
    return List.unmodifiable(wanted);
  }

  /// Appended like an expense, because the file is still a log and a log is
  /// still the only shape you can add one line to.
  @override
  Future<void> setLimit(Limit limit) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${jsonEncode(limit.toJson())}\n',
      mode: FileMode.append,
    );
  }

  /// One limit per category, latest wins.
  ///
  /// This is what the map in `InMemoryStore` gets for free and a log does not.
  /// Setting a limit twice writes two lines, and reading has to decide which
  /// counts — so it reads forwards and lets each line overwrite the one before,
  /// which is the same rule the map applies at write time.
  @override
  Future<List<Limit>> get limits async {
    final byCategory = <Category, Limit>{};
    for (final line in await _lines) {
      final limit = _limitFrom(line);
      if (limit != null) byCategory[limit.category] = limit;
    }
    return List.unmodifiable(byCategory.values);
  }

  Future<List<String>> get _lines async {
    if (!await file.exists()) return const [];
    return const LineSplitter().convert(await file.readAsString());
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
  static Expense? _expenseFrom(String line) => expenseFromJson(_decoded(line));

  static Limit? _limitFrom(String line) => limitFromJson(_decoded(line));

  /// One line's worth of JSON, or `null` for a line that is not JSON at all.
  ///
  /// The `catch` study 29 argued for, now that there are two callers and it
  /// would otherwise be written twice.
  static Object? _decoded(String line) {
    try {
      return jsonDecode(line);
    } on FormatException {
      return null;
    }
  }
}
// #endregion filestore
