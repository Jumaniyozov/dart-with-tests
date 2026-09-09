import 'pipeline.dart';

// #region capture
/// The same steps, built with one counter the whole loop shares.
List<Step> feeSteps(List<int> fees) {
  final steps = <Step>[];
  var i = 0;
  while (i < fees.length) {
    steps.add((pence) => pence + fees[i]);
    i++;
  }
  return steps;
}
// #endregion capture
