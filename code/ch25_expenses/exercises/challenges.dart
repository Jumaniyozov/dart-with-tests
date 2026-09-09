// Study 25 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// One value, one entity, one thing that must not leak. Getting the second one
// wrong in the same way as the first is the mistake this study exists to stop.

/// 1. A postcode: a value, normalised on the way in.
///
///    `Postcode('  sw1a  1aa ')` and `Postcode('SW1A 1AA')` are the same
///    postcode. Trim the ends, upper the case, and collapse any run of spaces
///    inside to a single space. Text with nothing in it is refused with an
///    [ArgumentError].
///
///    Two equal postcodes must also agree about `hashCode`, or a `Map` keyed by
///    one will quietly hold the same postcode twice. The analyzer will remind
///    you if you forget: the lint is `hash_and_equals`.
class const Postcode._(final String value) {
  factory Postcode(String text) => throw UnimplementedError('challenge 1');
}

/// 2. A receipt: an entity, and equal by identity rather than by contents.
///
///    A receipt has an `id` and a `total` in pence. Two receipts with the same
///    `id` are the same receipt even if their totals disagree — one of them is
///    simply out of date. Two receipts with different ids are different
///    receipts even if everything else matches.
///
///    This is not the rule from challenge 1, and copying that answer here is
///    the whole trap.
class const Receipt(final String id, final int total) {}

/// 3. A basket that does not leak.
///
///    `Basket(items)` holds a copy, so changing the list you passed in must not
///    change the basket. `items` hands back a list that throws if anyone adds
///    to it.
///
///    Two escapes, both easy to miss: the list that comes in, and the list that
///    goes out.
class Basket {
  Basket(List<String> items) {
    throw UnimplementedError('challenge 3');
  }

  List<String> get items => throw UnimplementedError('challenge 3');
}
