// Fields first and the constructor last: fromJson goes after the
// constructor, then toJson.
// @generate json
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}

// A factory is the last member, so fromJson goes after it.
// @generate json
class const Tag._(final String name) {
  factory Tag.of(String name) => Tag._(name.trim());
}

// A primary constructor with an empty body: the start is the end.
// @generate json
class const Code(final String value) {}

// A member follows the constructor with no blank line. fromJson gets a blank
// line on both sides.
// @generate json
class Tagged {
  final String tag;
  Tagged(this.tag);
  String get upper => tag.toUpperCase();
}

// A body with only a comment: the members go after the comment.
// @generate json
class const Note(final String text) {
  // Keep this small.
}
