import 'dart:io';

import 'package:test/test.dart';

/// The public surface, asserted rather than assumed.
///
/// Study 23 made `lib/src/` a privacy mechanism. This study makes it a
/// contract, and a contract nobody checks is a contract that drifts — so the
/// barrel is read back here as text and compared against a list somebody had to
/// write on purpose.
void main() {
  // #region surface
  /// Every library `package:ch35_expenses/expenses.dart` offers.
  ///
  /// Adding a line here is a **feature**. Removing one is a **breaking change**
  /// and costs a major version. That is the whole of what a version number
  /// promises, and this list is where the promise is made.
  const offered = {
    'src/budget.dart',
    'src/category.dart',
    'src/command.dart',
    'src/day.dart',
    'src/expense.dart',
    'src/file_store.dart',
    'src/money.dart',
    'src/period.dart',
    'src/reading.dart',
    'src/report.dart',
    'src/store.dart',
  };

  /// Under `lib/src/` on purpose, and reachable through the barrel by nobody.
  ///
  /// Study 34 left this test saying a new file under `lib/src/` "should be a
  /// decision", and this is the first study with one to make. `server.dart`
  /// hands back a `Handler`, which is a type belonging to `package:shelf`.
  /// Export it and every caller of this package inherits a dependency they did
  /// not choose — which is study 34's argument, arriving with something at
  /// stake rather than as a warning.
  const withheld = {'src/server.dart'};

  final barrel = File('lib/expenses.dart').readAsStringSync();
  final exported = {
    for (final line in barrel.split('\n'))
      if (RegExp(r"^export '(.+)';").firstMatch(line) case final match?)
        match.group(1)!,
  };

  group('the barrel is the contract', () {
    test('and it offers exactly what it says it offers', () {
      expect(
        exported,
        offered,
        reason: 'a difference here is a version number nobody bumped',
      );
    });

    test(
      'and every file under lib/src is either offered or deliberately not',
      () {
        final onDisk = {
          for (final file in Directory('lib/src').listSync())
            'src/${file.uri.pathSegments.last}',
        };
        expect(
          onDisk.difference(offered.union(withheld)),
          isEmpty,
          reason:
              'a new file under lib/src reaches nobody until the barrel says '
              'so — which is the point, but it should be a decision',
        );
      },
    );

    test('and nothing it offers has heard of shelf', () {
      final borrowed = {
        for (final path in offered)
          if (File('lib/$path').readAsStringSync().contains('package:shelf'))
            path,
      };
      expect(
        borrowed,
        isEmpty,
        reason:
            "a dependency's type in your public API makes that dependency's "
            'promises part of yours',
      );
    });
  });
  // #endregion surface

  // #region version
  group('the version is a promise, so it is written down twice', () {
    test('and the two agree', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final declared = RegExp(
        r'^version: (.+)$',
        multiLine: true,
      ).firstMatch(pubspec)?.group(1);
      final changelog = File('CHANGELOG.md').readAsStringSync();
      final released = RegExp(
        r'^## (.+)$',
        multiLine: true,
      ).firstMatch(changelog)?.group(1);

      expect(declared, isNotNull, reason: 'pub refuses a package without one');
      expect(
        released,
        declared,
        reason:
            'the top of the changelog is what the version number means; '
            'if they disagree, one of them is lying to a caller',
      );
    });
  });
  // #endregion version
}
