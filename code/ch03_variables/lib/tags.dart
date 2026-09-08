// #region constants
const hashPrefix = '#';
const untitled = 'untitled';
// #endregion constants

// #region tag
/// Turns [name] into a tag: trimmed, lowercased, and prefixed.
///
/// An empty or blank [name] becomes `#untitled`.
String tag(String name) {
  final cleaned = name.trim().toLowerCase();
  final body = cleaned.isEmpty ? untitled : cleaned;
  return '$hashPrefix$body';
}
// #endregion tag

// #region counting
/// Counts the characters in [name], ignoring what each one is.
///
/// `_` is a wildcard: it says "a value goes here and I will not use it".
/// Since Dart 3.7 a wildcard binds nothing at all, so you cannot read it
/// by accident.
int lengthOf(String name) {
  var count = 0;
  for (final _ in name.split('')) {
    count++;
  }
  return count;
}
// #endregion counting
