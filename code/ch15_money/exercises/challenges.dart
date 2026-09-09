// Study 15 challenges.
//
// Each one below is unfinished. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.
//
// Two of the three classes are declared with a primary constructor and should
// stay that way. The third cannot be, and working out why is the challenge.

/// 1. A weight in whole grams.
///    `kilos` is the whole kilograms in it, so `1500` has `1`.
///    `format()` reads `1.5kg` at a kilogram or more and `900g` below one.
///    A weight of `1500` reads `1.5kg`; `1050` reads `1.05kg`; `900` reads
///    `900g`.
class const Grams(final int grams) {
  int get kilos => throw UnimplementedError('challenge 1');

  String format() => throw UnimplementedError('challenge 1');
}

/// 2. A slot in a timetable. Two slots on the same day at the same hour are
///    the same slot, and a `Map` must agree — which means writing two things,
///    not one. Do not change the fields or the constructor.
class const Slot(final String day, final int hour) {
  // Your == and hashCode go here.
}

/// 3. A percentage, which is never below 0 and never above 100.
///    `Percent(101)` must fail an assertion rather than exist.
///    `Percent.clamped(140)` is `100`, and `Percent.clamped(-3)` is `0`.
///
///    This one cannot keep a primary constructor. The analyzer will tell you
///    why the moment you try to add the check.
class Percent {
  final int value;

  const new(this.value);

  factory clamped(int value) => throw UnimplementedError('challenge 3');
}
