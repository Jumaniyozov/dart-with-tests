// Study 11 challenges.
//
// Each function below throws. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.
//
// All three hand a function back. None of them needs a class, a loop over an
// index, or anything from a later study.

import 'package:ch11_pipeline/pipeline.dart';

/// 1. A step that never lets an amount go above [ceiling].
///    `capAt(500)` applied to `600` is `500`, and applied to `400` is `400`.
Step capAt(int ceiling) {
  throw UnimplementedError('challenge 1');
}

/// 2. One step that does the work of all of [steps], in order.
///    `combine([addFee(50), discount(10)])` behaves exactly like running the
///    two of them one after the other. Combining nothing changes nothing.
Step combine(List<Step> steps) {
  throw UnimplementedError('challenge 2');
}

/// 3. A function that keeps a running total of everything handed to it.
///    Call it with `100` and it answers `100`; call the same one with `50` and
///    it answers `150`. Two of them count separately.
Step runningTotal() {
  throw UnimplementedError('challenge 3');
}
