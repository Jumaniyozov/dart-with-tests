// #region directory
/// Extension numbers, by name.
const directory = {'ada': 101, 'grace': 102, 'alan': 103};
// #endregion directory

// #region find
/// The extension for [name], or nothing when the name is not in the directory.
///
/// The `?` on the return type is a promise to the caller: this may be nothing,
/// and you must say what to do about that before you can use it.
int? extensionFor(String name) => directory[name];
// #endregion find

// #region nameat
/// The name of whoever has [extension], or nothing when nobody does.
String? nameAt(int extension) {
  for (final entry in directory.entries) {
    if (entry.value == extension) return entry.key;
  }
  return null;
}
// #endregion nameat

// #region or
/// The extension for [name], or [fallback] when there is none.
int extensionOr(String name, int fallback) => directory[name] ?? fallback;
// #endregion or

// #region describe
/// Describes whoever [name] refers to. A missing name is nobody.
String describe(String? name) {
  if (name == null) return 'nobody';

  // From here down `name` is a `String`, not a `String?`. The analyzer worked
  // that out from the line above and will let you use it without asking again.
  return '$name has ${name.length} letters';
}
// #endregion describe

// #region parse
/// Reads a whole number of pence out of text a person typed.
///
/// `int.tryParse` hands back nothing when the text is not a number.
/// `int.parse` throws instead, which is the wrong shape for typed input.
int penceFrom(String typed, {int fallback = 0}) =>
    int.tryParse(typed.trim()) ?? fallback;
// #endregion parse

// #region roster
/// The extensions for [names], quietly skipping any name that has none.
List<int> rosterFor(List<String> names) => [
  for (final name in names) ?directory[name],
];
// #endregion roster
