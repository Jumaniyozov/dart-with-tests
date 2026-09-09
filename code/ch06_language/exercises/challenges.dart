// Study 6 challenges.
//
// Each function below throws. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.
//
// Every switch here should be exhaustive. If you find yourself writing a
// default case (`_`), you have given away the thing the enum was for.

enum Size { small, medium, large }

enum Doneness { rare, medium, wellDone }

/// 1. One capital letter for a size: `initial(Size.small)` is `'S'`.
String initial(Size size) {
  throw UnimplementedError('challenge 1');
}

/// 2. How many minutes each doneness needs: rare 2, medium 4, wellDone 7.
int minutesFor(Doneness doneness) {
  throw UnimplementedError('challenge 2');
}

/// 3. Every size, in declaration order, separated by a comma and a space:
///    `allSizes()` is `'small, medium, large'`. Use `Size.values` and each
///    member's `name`, so adding a size to the enum needs no change here.
String allSizes() {
  throw UnimplementedError('challenge 3');
}
