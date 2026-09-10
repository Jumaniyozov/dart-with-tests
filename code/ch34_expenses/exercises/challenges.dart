// Study 34 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are the promise a version number makes, written out as code. Every
// rule below was measured against `pub_semver`, which is the resolver pub
// itself uses, so the answers are pub's rather than this book's.

/// What happened to a package between two versions.
enum Change {
  /// Nothing a caller can see changed.
  fix,

  /// Something was added, and everything that worked still works.
  feature,

  /// Something a caller could have been using is gone or different.
  breaking,
}

/// 1. The next version number, given what changed.
///
///    Above 1.0.0 this is the rule everybody quotes: a [Change.fix] bumps the
///    patch, a [Change.feature] bumps the minor and zeroes the patch, a
///    [Change.breaking] bumps the major and zeroes the rest.
///
///    Below 1.0.0 it is not. `0.x` means *no promises yet*, so pub shifts every
///    rule one place left: a breaking change to `0.4.2` gives `0.5.0`, and a
///    feature gives `0.4.3`. Measured — `^0.4.2` allows `0.4.9` and refuses
///    `0.5.0`, so the minor is where a `0.x` package breaks you.
///
///    `1.4.2` + fix is `1.4.3`; `1.4.2` + feature is `1.5.0`; `1.4.2` +
///    breaking is `2.0.0`. `0.4.2` + fix is `0.4.3`; `0.4.2` + feature is also
///    `0.4.3`; `0.4.2` + breaking is `0.5.0`.
String nextVersion(String current, Change change) =>
    throw UnimplementedError('1');

/// 2. Whether a caret constraint allows a version.
///
///    `^2.7.0` is `>=2.7.0 <3.0.0`. `^0.4.2` is `>=0.4.2 <0.5.0`, for the
///    reason above. Compare the three numbers in order, not as text: `0.10.0`
///    is above `0.9.0`, and a string comparison says the opposite.
///
///    Both arguments are plain `major.minor.patch`, three numbers and two dots.
///    Anything else is not a version and answers `false` rather than throwing —
///    this reads what somebody typed, which is study 26's rule.
bool allows(String constraint, String version) => throw UnimplementedError('2');

/// 3. What a change to the public surface actually was.
///
///    [changeBetween] takes the set of names a package exported before and the
///    set it exports after, and says which [Change] that is. Anything gone is
///    [Change.breaking], whatever else happened alongside it. Nothing gone and
///    something new is [Change.feature]. Two identical sets are [Change.fix].
///
///    This is the whole of study 34 in one function: a major version is the
///    sentence *I removed something you were using*, and `lib/src/` is how you
///    keep that sentence rare, because nothing in there is in either set.
Change changeBetween(Set<String> before, Set<String> after) =>
    throw UnimplementedError('3');
