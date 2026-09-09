// Study 5 challenges.
//
// Each function below throws. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.
//
// Every answer counts characters, never code units. `length` is the wrong
// tool in all three.
//
// You will need one import that is not here yet. Write a solution without it
// and the analyzer will tell you exactly what is missing.

/// 1. The first letter of each word, in capitals.
///    `initials('Ada Lovelace')` is `'AL'`. Words are separated by spaces,
///    and two spaces in a row do not make an empty initial.
String initials(String name) {
  throw UnimplementedError('challenge 1');
}

/// 2. Pad [text] with spaces on the right until it is [width] characters wide.
///    `padTo('Hi', 5)` is `'Hi   '` and `padTo('👋', 3)` is `'👋  '`.
///    Text that is already wide enough is returned unchanged.
///    Dart's own `padRight` counts code units, so it is no help here.
String padTo(String text, int width) {
  throw UnimplementedError('challenge 2');
}

/// 3. Reverse [text] without breaking anything.
///    `reverse('abc')` is `'cba'` and `reverse('ab👋')` is `'👋ba'`.
String reverse(String text) {
  throw UnimplementedError('challenge 3');
}
