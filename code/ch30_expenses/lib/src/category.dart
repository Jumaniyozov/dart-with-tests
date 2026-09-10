// #region category
/// A label a person chose for their spending.
///
/// Two categories written differently but meaning the same thing are the same
/// category, so the normalising happens once, here, on the way in. Nothing
/// downstream has to remember to compare carefully.
class const Category._(final String name) {
  factory Category(String name) {
    final tidied = name.trim().toLowerCase();
    if (tidied.isEmpty) {
      throw ArgumentError.value(name, 'name', 'a category needs a name');
    }
    return Category._(tidied);
  }

  @override
  bool operator ==(Object other) => other is Category && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}
// #endregion category
