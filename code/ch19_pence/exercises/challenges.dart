// Study 19 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// Two of the three are about where code lives rather than what it does. If an
// answer needs a free function taking the value as a parameter, the extension
// was the answer.

/// 1. The sum of the squares of some whole numbers.
///    `[1, 2, 3].sumOfSquares` is `14`. An empty iterable is `0`.
///
///    The receiver is `Iterable<int>`, which you cannot open and do not need
///    to.
extension Squares on Iterable<int> {
  int get sumOfSquares => throw UnimplementedError('challenge 1');
}

/// 2. A percentage: a whole number from 0 to 100 and no other.
///
///    `Percent.of(101)` must throw an `AssertionError`, and `Percent.of(50)`
///    must not. `Percent(25).applied(400)` is `100`, rounded down.
///
///    `Percent(101)` still compiles and still runs. That is 19.4, not a bug
///    in your answer.
extension type const Percent(int value) {
  Percent.of(this.value);

  int applied(int amount) => throw UnimplementedError('challenge 2');
}

/// 3. Two units of length that must never be handed to each other's
///    functions.
///
///    `Metres(2).asCentimetres` is `Centimetres(200)`.
///    `describe(Centimetres(250))` is `'2m 50cm'`, and `Centimetres(0)` is
///    `'0m 0cm'`.
///
///    A length here is never negative. Nothing in the declaration can promise
///    that, which is the honest half of 19.4.
extension type const Metres(int value) {
  Centimetres get asCentimetres => throw UnimplementedError('challenge 3');
}

extension type const Centimetres(int value) {}

String describe(Centimetres length) => throw UnimplementedError('challenge 3');
