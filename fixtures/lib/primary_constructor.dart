// @generate primaryConstructor
/// Makes a pair.
class const Pair(
  /// The left side.
  final int left,
  final int right,
) {}

// @generate primaryConstructor
/// A tag with defaults.
class Tag(final String name, {@Deprecated('Use name') var int size = 0}) {
  int get length => name.length;
}

// An initializer list does not move. Only this. and super. parameters do.
// @not primaryConstructor notConvertible
class Checked {
  final int value;

  Checked(this.value) : assert(value >= 0);
}

// A comment at the end of a moved field's line moves with its parameter.
// @generate primaryConstructor
class User(
  final String name, // the display name
) {}

// Both variables of one declaration move.
// @generate primaryConstructor
class Range(final int start, final int end) {}

// A late field does not move.
// @not primaryConstructor notConvertible
class Deferred {
  late final int value;

  Deferred(this.value);
}

// A field with an initializer does not move.
// @not primaryConstructor notConvertible
class Counted {
  int count = 0;

  Counted(this.count);
}

// A function-typed parameter does not move.
// @not primaryConstructor notConvertible
class Button {
  final void Function() onTap;

  // ignore: use_function_type_syntax_for_parameters
  Button(this.onTap());
}

// A declaration cannot move in part: b moves, c does not.
// @not primaryConstructor notConvertible
class Partial {
  final int a;
  int? b, c;

  Partial(this.a, this.b);
}
