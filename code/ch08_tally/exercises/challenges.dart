// Study 8 challenges.
//
// Each function below throws. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.
//
// Reading a key that is not there gives you nothing, not zero. `?? 0` is the
// tool for that until study 9 explains it properly.

/// 1. How many words were counted altogether:
///    `totalWords({'red': 2, 'blue': 1})` is `3`.
int totalWords(Map<String, int> counts) {
  throw UnimplementedError('challenge 1');
}

/// 2. The word with the highest count. When two words tie, keep the one that
///    was inserted first. An empty map has no most common word, so return `''`.
///    `mostCommon({'red': 2, 'blue': 1})` is `'red'`.
String mostCommon(Map<String, int> counts) {
  throw UnimplementedError('challenge 2');
}

/// 3. Add two tallies together:
///    `merged({'red': 2}, {'red': 1, 'blue': 4})` is `{'red': 3, 'blue': 4}`.
///    Neither map you were given may be changed.
Map<String, int> merged(Map<String, int> a, Map<String, int> b) {
  throw UnimplementedError('challenge 3');
}
