// Study 28 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are about a program that has to survive being closed. The first
// two are `dart:io`; the third is the format, and it is the one study 29
// makes unnecessary.

import 'dart:io';

import 'package:ch28_expenses/expenses.dart';

/// 1. A store that starts from what somebody else wrote.
///
///    [SeededStore] reads [source] once, when it is asked for `all` the first
///    time, and keeps everything in memory after that. Recording adds to
///    memory and never touches the file, so the file is a starting point
///    rather than a home.
///
///    A [source] that does not exist is not an error — it means nothing was
///    seeded, exactly as [FileStore] treats it.
///
///    The file holds the same lines [FileStore] writes:
///    `2026-09-09,1250,food,coffee`.
///
///    Read it once. A test records after the first `all` and asks again, and
///    a store that re-reads on every call would lose what it was told.
class SeededStore(final File source) implements Store {
  @override
  Future<void> record(Expense expense) => throw UnimplementedError('1');

  @override
  Future<List<Expense>> get all => throw UnimplementedError('1');
}

/// 2. Say whether the tracker has anything to say.
///
///    [summarise] answers `nothing recorded yet` when the store is empty, and
///    otherwise `N expenses, £X.XX in total` — `1 expense` when there is one,
///    with no `s`.
///
///    `£X.XX` is [Money.asText], and the total is the sum of every amount.
///
///    It takes a [Store] and not a [FileStore], so the tests hand it an
///    `InMemoryStore` and never touch a disk. That is study 27's seam still
///    doing its job one study later.
Future<String> summarise(Store store) => throw UnimplementedError('2');

/// 3. A line that can carry a comma.
///
///    [escapeField] and [unescapeField] are a matched pair. `escapeField` replaces every
///    comma in a field with `\,` and every backslash with `\\`; `unescapeField`
///    undoes exactly that.
///
///    Order matters and it is the whole challenge: escape the backslash
///    first, or `a,b` becomes `a\,b` and then `a\\,b`, and unescaping gives
///    you back a backslash you never had.
///
///    `escapeField('bus, then train')` is `'bus\\, then train'`.
///    `unescapeField(escapeField(text))` is `text`, for every text.
///
///    This is what study 28's format needs and does not have. Study 29 does
///    not write this function — it takes a format that already solved it.
String escapeField(String field) => throw UnimplementedError('3');

String unescapeField(String field) => throw UnimplementedError('3');
