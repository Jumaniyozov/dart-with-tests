// A getter for a body field goes after the field.
// @generate getter at _count
class Counter {
  int _count = 0;

  void bump() => _count++;
}

// The cursor can be anywhere in a declaration of one field, such as on its
// type.
// @generate getter at int
class Score {
  final int _points = 0;
}

// A getter for a header field goes at the start of the body.
// @generate getter at _secret
class const Vault(final String _secret);

// The public name is taken.
// @not getter publicNameTaken at _size
class Sized {
  final int _size = 0;

  int get size => _size + 1;
}

// The constructor follows the field with no blank line. The getter gets a
// blank line on both sides.
// @generate getter at _value
class Wrapper {
  final int _value;
  Wrapper(this._value);
}

// A comment on a later line follows the field. The getter gets a blank
// line on both sides.
// @generate getter at _last
class Tail {
  final int _last = 0;
  // More fields go here.
}
