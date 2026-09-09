// Study 17 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// A reading from a sensor, and two adjustments that can be applied to it.

abstract class Reading {
  const new();

  int get raw;

  int value() => raw;
}

/// 1. Never let a reading through above 100. Anything at or below passes
///    unchanged. Adjust whatever the mixins before you produced, not [raw].
mixin Capped on Reading {
  @override
  int value() => throw UnimplementedError('challenge 1');
}

/// 2. Double whatever reached you, again from what came before rather than
///    from [raw].
mixin Doubled on Reading {
  @override
  int value() => throw UnimplementedError('challenge 2');
}

/// 3. Two sensors, same two adjustments, different order.
///    [Loose] doubles first and then caps, so a raw 60 reads 100.
///    [Strict] caps first and then doubles, so a raw 60 reads 120.
///    Only the `with` clauses change.
class const Loose(@override final int raw) extends Reading {}

class const Strict(@override final int raw) extends Reading {}
