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
  /// Every library `package:ch40_expenses/expenses.dart` offers.
  ///
  /// Adding a line here is a **feature**. Removing one is a **breaking change**
  /// and costs a major version. That is the whole of what a version number
  /// promises, and this list is where the promise is made.
  const offered = {
    'src/alone.dart',
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
    'src/tracker.dart',
  };

  /// Under `lib/src/` on purpose, and reachable through the barrel by nobody.
  ///
  /// Study 34 left this test saying a new file under `lib/src/` "should be a
  /// decision", and study 35 was the first study with one to make.
  /// `server.dart` hands back a `Handler`, which belongs to `package:shelf`.
  /// Export it and every caller of this package inherits a dependency they did
  /// not choose.
  ///
  /// **Study 39 made the same decision three more times, and that is what a
  /// rule is for.** `sqlite_store.dart` is built from a `Database` and
  /// `migration.dart` takes one, both of which belong to `package:sqlite3`; the
  /// argument is word for word `server.dart`'s. `rolling_back.dart` is a
  /// demonstration rather than a capability, which is study 26's ruling about
  /// `asserting.dart`. All four are reached by naming the file, which is legal
  /// inside one package and is what `bin/` does.
  const withheld = {
    'src/migration.dart',
    'src/rolling_back.dart',
    'src/server.dart',
    'src/sqlite_store.dart',
  };

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

    /// **This named `shelf` until study 39 and now names nothing.**
    ///
    /// A contract test protects exactly the surface it was written about, and
    /// this one was written about one dependency. Study 39 took a second, and a
    /// test that had to be edited to notice it is a test that would not have
    /// noticed it. So the list comes from `pubspec.yaml`: take a dependency and
    /// this check covers it on the next run, with nobody remembering to say so.
    ///
    /// It reads import lines rather than signatures, which is stricter than the
    /// rule it stands for — a library may legitimately *use* a dependency it
    /// does not *expose*. That is what the exemption below is, and the reason
    /// is required in the same way a `SLICE`'s is.
    test('and nothing it offers names a dependency of this package', () {
      /// `command.dart` imports `package:args`, and `fileFrom` answers a
      /// `String`. No `ArgResults` crosses the barrel, so `package:args` is
      /// something this library uses rather than something it makes its callers
      /// use — which is study 34's distinction, written down here as a line
      /// somebody had to add on purpose.
      const usedAndNotExposed = {'args'};

      final pubspec = File('pubspec.yaml').readAsStringSync();
      final block = pubspec
          .split('dev_dependencies:')
          .first
          .split(RegExp(r'^dependencies:$', multiLine: true));
      final taken = {
        for (final match in RegExp(
          r'^  ([a-z_0-9]+):',
          multiLine: true,
        ).allMatches(block.last))
          match.group(1)!,
      };
      expect(
        taken,
        isNotEmpty,
        reason: 'an empty list here is this check switching itself off',
      );

      final borrowed = {
        for (final path in offered)
          for (final name in taken.difference(usedAndNotExposed))
            if (File('lib/$path').readAsStringSync().contains('package:$name/'))
              '$path names package:$name',
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

  // #region runnable
  /// Every program `dart run ch40_expenses:<name>` will start.
  ///
  /// **The barrel is not the whole surface, and study 34's test only knew about
  /// the barrel.** A script under `bin/` is public in exactly the sense study 34
  /// cared about: another package can run it by name, so removing one is a
  /// breaking change and costs a major version. Study 36 removed
  /// `bin/by_hand.dart`, which is why this list exists — the deletion was right
  /// and nothing would have noticed it.
  group('bin is a contract too', () {
    test('and it offers exactly the programs it says it does', () {
      /// Four, and the new one is a demonstration rather than a capability —
      /// `bin/holding.dart` in the sense study 38 gave it, and
      /// `lib/src/rolling_back.dart` in the sense study 39 did. `writers.dart`
      /// exists because the thing study 40 is about cannot be shown by a test
      /// that passes: a reader has to see the same two expenses come out as
      /// £12.00 and then as £6.00.
      ///
      /// Adding one is not a breaking change and a **removal** is, which is
      /// why the sentence in a CHANGELOG matters more than the direction the
      /// count moved.
      const runnable = {
        'expenses.dart',
        'migrate.dart',
        'serve.dart',
        'writers.dart',
      };

      final onDisk = {
        for (final file in Directory('bin').listSync())
          file.uri.pathSegments.last,
      };

      expect(
        onDisk,
        runnable,
        reason:
            'dart run <package>:<name> reaches every one of these, so '
            'removing one is a major version exactly as removing an export is',
      );
    });
  });
  // #endregion runnable

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
