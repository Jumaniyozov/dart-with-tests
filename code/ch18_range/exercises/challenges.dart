// Study 18 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// The signatures are written for you, and none of them mentions a concrete
// type. Keep it that way: if `String` or `int` appears in a body, the type
// parameter was the answer.

/// 1. Where each value was first seen.
///    `firstSeenAt(['a', 'b', 'a'])` is `{'a': 0, 'b': 1}` — the second `'a'`
///    does not move it. An empty list gives an empty map.
Map<T, int> firstSeenAt<T>(List<T> values) {
  throw UnimplementedError('challenge 1');
}

/// 2. A box holding at most [capacity] things.
///    `add` puts a value in and answers `true`, or answers `false` and
///    changes nothing when the box is full. [held] is what is in it.
class Slots<T>(final int capacity) {
  final List<T> held = [];

  bool add(T value) {
    throw UnimplementedError('challenge 2');
  }
}

/// 3. The largest value strictly below [limit], or nothing when every value
///    is at or above it. `highestUnder([3, 9, 2], 9)` is `3`.
///
///    The bound is the one study 18 measured, not the one that reads better.
T? highestUnder<T extends Comparable<Object>>(List<T> values, T limit) {
  throw UnimplementedError('challenge 3');
}
