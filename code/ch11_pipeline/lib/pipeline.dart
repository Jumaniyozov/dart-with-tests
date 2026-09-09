// #region step
/// One stage of a price pipeline: takes an amount in pence, hands back another.
///
/// The name `pence` in that type is for you, not for the compiler. Any function
/// taking one `int` and returning an `int` is a `Step`, whatever it calls its
/// parameter.
typedef Step = int Function(int pence);
// #endregion step

// #region run
/// Puts [pence] through each of [steps], in order.
int runPipeline(int pence, List<Step> steps) {
  var value = pence;
  for (final step in steps) {
    value = step(value);
  }
  return value;
}
// #endregion run

// #region made
/// A step that adds a flat [fee] to whatever it is given.
Step addFee(int fee) =>
    (pence) => pence + fee;

/// A step that takes [percent] off, rounding down to the penny.
Step discount(int percent) =>
    (pence) => pence - (pence * percent) ~/ 100;
// #endregion made

// #region named
/// A step written as an ordinary named function, so it can be handed over by
/// name rather than written out at the call site.
int roundToTenPence(int pence) => ((pence + 5) ~/ 10) * 10;
// #endregion named

// #region optional
/// Puts [pence] through [step] [times] over. Once, unless you say otherwise.
int repeat(int pence, Step step, [int times = 1]) {
  var value = pence;
  for (var i = 0; i < times; i++) {
    value = step(value);
  }
  return value;
}
// #endregion optional

// #region line
/// One line of the printed report.
///
/// `pence` is named and `required`: there is no sensible default for a price,
/// and `line('jam', 250)` at the call site would not say which number is which.
String line(String label, {required int pence, int width = 12, String? note}) {
  final amount = '${label.padRight(width)}${pence}p';
  return note == null ? amount : '$amount ($note)';
}
// #endregion line

// #region counter
/// Hands back a function that counts how many times it has been called.
///
/// `count` outlives this call. The returned function did not copy it — it kept
/// the variable itself.
int Function() counter() {
  var count = 0;
  return () => ++count;
}
// #endregion counter

// #region capture
/// One step per fee, each remembering the fee it was built from.
List<Step> feeSteps(List<int> fees) {
  final steps = <Step>[];
  for (final fee in fees) {
    steps.add((pence) => pence + fee);
  }
  return steps;
}
// #endregion capture
