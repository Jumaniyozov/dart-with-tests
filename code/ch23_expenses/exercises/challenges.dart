// Study 23 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are about a door. The first two ask you to build one; the third
// asks you to notice that you are standing on the wrong side of it.

/// 1. A slug: an identifier made from whatever a person typed.
///
///    `Slug.of(' Hello  World ')` is `hello-world`. Trim the ends, lower the
///    case, and replace any run of spaces with a single hyphen. Empty text,
///    or text that is nothing but spaces, is refused with an [ArgumentError].
///
///    The constructor must be private, so that `value` is always normalised.
///    A `Slug` that skipped the normalising would be a `Slug` that does not
///    compare equal to the one a reader expects.
class const Slug._(final String value) {
  factory Slug.of(String text) => throw UnimplementedError('challenge 1');
}

/// 2. A rating: a whole number from 1 to 5, and nothing else.
///
///    Keep the primary constructor in the header, and put the check in a
///    factory beside it. A generative constructor is not allowed next to a
///    primary one — 23.3 says why, and the analyzer will say it again if you
///    reach for one.
class const Rating._(final int stars) {
  factory Rating.of(int stars) => throw UnimplementedError('challenge 2');
}

/// 3. The honour system.
///
///    [Vault] is in this file, which is the same library as [Rating], so it
///    can reach `Rating._` and does. It builds ratings nobody checked.
///
///    You cannot stop it with `_`. Privacy is not the tool here, because the
///    boundary is already behind you. Make `Vault.rate` go through the door
///    that exists.
class Vault {
  static Rating rate(int stars) => Rating._(stars);
}
