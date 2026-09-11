// #region barrel
/// The expense tracker's public face.
library;

/// Twelve exports now, and the count went **down**, which is what a major
/// version is for. `src/holding_store.dart` is gone: study 38's cache existed
/// because reading a file meant reading all of it, and a database reads what
/// you ask for.
///
/// `src/sqlite_store.dart` did not take its place here, and that is study 34's
/// rule applied for the second time. `SqliteStore` is built from a `Database`,
/// which belongs to `package:sqlite3` — export it and everyone who depends on
/// this package inherits a dependency they did not choose, exactly as
/// `src/server.dart` would have handed them `package:shelf`. Both are reached
/// by naming the file, which is legal inside one package and is what `bin/`
/// does.
export 'src/budget.dart';
export 'src/category.dart';
export 'src/command.dart';
export 'src/day.dart';
export 'src/expense.dart';
export 'src/file_store.dart';
export 'src/money.dart';
export 'src/period.dart';
export 'src/reading.dart';
export 'src/report.dart';
export 'src/store.dart';
export 'src/tracker.dart';

// #endregion barrel
