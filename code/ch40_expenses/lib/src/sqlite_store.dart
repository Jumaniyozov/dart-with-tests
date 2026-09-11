import 'package:sqlite3/sqlite3.dart';

import 'budget.dart';
import 'category.dart';
import 'day.dart';
import 'expense.dart';
import 'money.dart';
import 'period.dart';
import 'store.dart';

// #region schema
/// The two tables, and every rule about them SQLite is able to keep.
///
/// **`STRICT` is the first line of the argument.** Without it a column type is
/// a suggestion: `INSERT INTO expenses (pence) VALUES ('lots')` succeeds on an
/// ordinary `INTEGER` column and comes back out as a Dart `String`. Measured,
/// because a read that can hand back the wrong type is study 19's argument
/// undone at the last possible moment. `STRICT` arrived in SQLite 3.37 and the
/// prebuilt library this package binds is 3.53.4.
///
/// **`acknowledged INTEGER`, because SQLite has no boolean.** `0` and `1`, and
/// the `CHECK` writes that down rather than leaving it to be remembered. That
/// one mismatch is what stops [expenseFromJson] reading a row.
///
/// The `CHECK`s restate what [Money], [Category] and [Limit] already refuse,
/// and this is the one place in this book where writing a rule twice is right.
/// A type defends a rule against *this* program. A schema defends it against
/// the next one — the `sqlite3` shell, a backup script, whatever opens this
/// file in five years. Different attackers, so two guards rather than one
/// owner.
const schema = '''
CREATE TABLE IF NOT EXISTS expenses (
  id INTEGER NOT NULL PRIMARY KEY,
  day TEXT NOT NULL,
  pence INTEGER NOT NULL CHECK (pence >= 0),
  category TEXT NOT NULL CHECK (length(trim(category)) > 0),
  note TEXT NOT NULL,
  acknowledged INTEGER NOT NULL CHECK (acknowledged IN (0, 1))
) STRICT;

CREATE TABLE IF NOT EXISTS limits (
  category TEXT NOT NULL PRIMARY KEY,
  pence INTEGER NOT NULL CHECK (pence > 0)
) STRICT;
''';
// #endregion schema

// #region sqlitestore
/// A [Store] that keeps expenses in a SQLite database.
///
/// **It takes an open [Database] and never opens one.** Study 27's seam, and
/// here it buys something specific: every test runs against
/// `sqlite3.openInMemory()`, so the suite exercises the real `CHECK`s, the real
/// upsert and the real `LIMIT` with no file to clean up. `bin/` decides where
/// the database lives, which is the division [FileStore] has and `expensesApi`
/// has.
///
/// It leaves `file_store.dart`'s doc comment true as well: this file has not
/// heard of `dart:io` either. `package:sqlite3` reaches the C library through
/// `dart:ffi`, and a path is a `String`.
///
/// A factory over a `_` header, for the reason every other factory here has
/// one: the header has no body, and something must run before any other member
/// works. What runs is not a check — it is [schema], which says *make sure*
/// rather than *make*.
class SqliteStore._(final Database db) implements Store {
  /// Read and write expenses in [db], creating the tables if they are not
  /// there.
  factory SqliteStore(Database db) {
    db.execute(schema);
    return SqliteStore._(db);
  }

  /// The two ends of every day this program could write, as text.
  ///
  /// `day` is `YYYY-MM-DD` in a `TEXT` column, so SQLite orders it the way a
  /// person reads it and these bracket every real day without being one. No
  /// period is therefore the *same statement* as a period, which is why there
  /// is one string of SQL below and not two glued together out of an `if`.
  static const _dawn = '0000-00-00';
  static const _dusk = '9999-99-99';

  /// SQLite's own way of saying *no bound*, and it is not `null`.
  ///
  /// `LIMIT -1` returns everything; `LIMIT NULL` is a `datatype mismatch`.
  /// Asserted, because *null means no bound* is true in Dart and false one
  /// layer down, and that is the sort of thing you find out by running it.
  static const _unbounded = -1;

  /// What has been recorded, narrowed by whatever the caller asked for.
  ///
  /// Study 37's edge read every expense there was and threw most of them away.
  /// Both narrowings are in the statement here, so the database finds what was
  /// asked for and nothing else — and `test/server_test.dart#bound` is study
  /// 37's counting double, now measuring a difference.
  @override
  Future<List<Expense>> expenses({Period? period, int? count}) async {
    final rows = db.select(
      'SELECT day, pence, category, note, acknowledged FROM expenses '
      'WHERE day >= ? AND day <= ? ORDER BY id LIMIT ?',
      [
        period?.first.asText ?? _dawn,
        period?.last.asText ?? _dusk,
        count ?? _unbounded,
      ],
    );
    return List.unmodifiable([for (final row in rows) ?_expenseFrom(row)]);
  }

  /// One limit per category, which is a primary key and nothing else.
  ///
  /// `InMemoryStore` gets this from a `Map`; [FileStore] earns it by reading
  /// the log forwards and letting each line overwrite the one before; here it
  /// is a column declaration. `ORDER BY rowid` answers in the order the limits
  /// were first set, which is the order the other two answer in.
  @override
  Future<List<Limit>> get limits async {
    final rows = db.select('SELECT category, pence FROM limits ORDER BY rowid');
    return List.unmodifiable([for (final row in rows) ?_limitFrom(row)]);
  }

  @override
  Future<void> record(Expense expense) async => db.execute(
    'INSERT INTO expenses (day, pence, category, note, acknowledged) '
    'VALUES (?, ?, ?, ?, ?)',
    [
      expense.day.asText,
      expense.amount.pence,
      expense.category.name,
      expense.note,
      // `1` and not `true`. `sqlite3` would store a `true` as a `1` for you and
      // the column would still be an integer, so the conversion happens either
      // way — this is the version where you can see it happen.
      expense.acknowledged ? 1 : 0,
    ],
  );

  /// Set the limit on a category, **replacing** any limit already on it.
  ///
  /// A plain `INSERT` is what anyone writes first and it is wrong the second
  /// time somebody changes a budget: `category` is the primary key, so SQLite
  /// answers `UNIQUE constraint failed: limits.category`. `ON CONFLICT … DO
  /// UPDATE` is one statement meaning *set it*, which is what [Store.setLimit]
  /// has promised since study 32. `excluded` is SQLite's name for the row that
  /// was refused.
  @override
  Future<void> setLimit(Limit limit) async => db.execute(
    'INSERT INTO limits (category, pence) VALUES (?, ?) '
    'ON CONFLICT (category) DO UPDATE SET pence = excluded.pence',
    [limit.category.name, limit.amount.pence],
  );

  /// One row back into an expense, or `null` for a row this program cannot
  /// read.
  ///
  /// **Not [expenseFromJson], and the reason is that it would have compiled.**
  /// A `Row` implements `Map<String, Object?>`, so handing one over type-checks,
  /// matches that function's map pattern, and answers a real [Expense] — with
  /// `acknowledged` **always false**, because the column holds `1` where JSON
  /// holds `true`. No analyzer sees it, and every amount on every line is right.
  ///
  /// `expense.dart` has said since study 29 that `toJson` is an extension
  /// rather than a member because *a store that kept expenses in a database
  /// would want none of it*, and study 36's page turned that into a promise
  /// about this study. This is where both stop being predictions: it survives
  /// the move intact, by not being used here.
  ///
  /// The guards below and the `CHECK`s in [schema] defend different things. The
  /// `CHECK`s stop a bad row going in; these stop a bad row coming out of a
  /// table this program did not create, which is the only kind
  /// `CREATE TABLE IF NOT EXISTS` leaves alone.
  static Expense? _expenseFrom(Row row) {
    if (row case {
      'day': final String day,
      'pence': final int pence,
      'category': final String category,
      'note': final String note,
      'acknowledged': final int acknowledged,
    }) {
      final on = Day.parse(day);
      if (on == null || pence < 0 || category.trim().isEmpty) return null;
      return Expense(
        Money.fromPence(pence),
        Category(category),
        on,
        note,
        acknowledged: acknowledged == 1,
      );
    }
    return null;
  }

  /// One row back into a limit, or `null` for a row this program cannot read.
  ///
  /// No `kind`. [limitFromJson] needs one because a log holds both shapes on
  /// the same lines and something has to tell them apart. Two tables are two
  /// shapes already, so that key was the file's problem rather than the
  /// domain's.
  static Limit? _limitFrom(Row row) => switch (row) {
    {'category': final String category, 'pence': final int pence}
        when pence > 0 && category.trim().isNotEmpty =>
      Limit(Category(category), Money.fromPence(pence)),
    _ => null,
  };
}
// #endregion sqlitestore

// #region alone
/// Run [body] with [db]'s write lock, taken **before** it reads.
///
/// This is the `Alone` a real database can keep, and it is study 39's first
/// challenge with the `T` made a `Future<T>`: `atomically` over a `Database`,
/// which is where a transaction actually lives. A free function rather than a
/// member on [SqliteStore] for the same reason — two stores over one
/// `Database` share one transaction, and a member would have said otherwise.
///
/// **The verb is the whole of it.** `BEGIN` starts a *deferred* transaction:
/// it takes no lock, the first `SELECT` takes a shared one, and the `INSERT`
/// then has to upgrade that to a write lock. Measured with two connections:
/// both read the same total, one upgrade succeeds, the other is answered
/// `database is locked`, and then the **`COMMIT`** of the one that did get in
/// fails too, because the loser is still holding its read. Everybody was told
/// yes and nothing was recorded. `BEGIN IMMEDIATE` asks for the write lock at
/// the top, so the second writer is refused before it can read a number it
/// would then be allowed to trust.
///
/// **No busy timeout, and that is a decision rather than an omission.**
/// `PRAGMA busy_timeout` makes a second writer wait instead of failing, and
/// SQLite waits inside the C call — which `dart:ffi` runs on this isolate's
/// only thread. Measured in `test/alone_test.dart`: a timer that is already
/// due does not run while SQLite is waiting, so a server that waits for a lock
/// is a server answering nobody. At SQLite's default of zero a collision is
/// immediate and loud, which is the failure this program would rather have.
///
/// The `finally` with no `catch` is `moveInto`'s shape and study 20's clause
/// doing the one job it is uniquely for. The `autocommit` check is not
/// defensive: a `ROLLBACK` after a successful `COMMIT` throws *cannot rollback
/// - no transaction is active*, which would arrive at the caller in place of
/// whatever really went wrong.
Future<T> aloneIn<T>(Database db, Future<T> Function() body) async {
  db.execute('BEGIN IMMEDIATE');
  try {
    final answer = await body();
    db.execute('COMMIT');
    return answer;
  } finally {
    if (!db.autocommit) db.execute('ROLLBACK');
  }
}
// #endregion alone
