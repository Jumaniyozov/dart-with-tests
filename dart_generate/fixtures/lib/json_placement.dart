// Fields first and the constructor last: fromJson goes after the
// constructor, then toJson.
// @generate json
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);

  factory Point.fromJson(Object? json) => switch (json) {
    {'x': final int x, 'y': final int y} => Point(x, y),
    _ => throw FormatException('Invalid Point JSON', json),
  };

  Map<String, Object?> toJson() => {'x': x, 'y': y};
}

// A factory is the last member, so fromJson goes after it.
// @generate json
class const Tag._(final String name) {
  factory Tag.of(String name) => Tag._(name.trim());

  factory Tag.fromJson(Object? json) => switch (json) {
    {'name': final String name} => Tag.of(name),
    _ => throw FormatException('Invalid Tag JSON', json),
  };

  Map<String, Object?> toJson() => {'name': name};
}

// A primary constructor with an empty body: the start is the end.
// @generate json
class const Code(final String value) {
  factory Code.fromJson(Object? json) => switch (json) {
    {'value': final String value} => Code(value),
    _ => throw FormatException('Invalid Code JSON', json),
  };

  Map<String, Object?> toJson() => {'value': value};
}

// A member follows the constructor with no blank line. fromJson gets a blank
// line on both sides.
// @generate json
class Tagged {
  final String tag;
  Tagged(this.tag);

  factory Tagged.fromJson(Object? json) => switch (json) {
    {'tag': final String tag} => Tagged(tag),
    _ => throw FormatException('Invalid Tagged JSON', json),
  };

  String get upper => tag.toUpperCase();

  Map<String, Object?> toJson() => {'tag': tag};
}

// A body with only a comment: the members go after the comment.
// @generate json
class const Note(final String text) {
  // Keep this small.

  factory Note.fromJson(Object? json) => switch (json) {
    {'text': final String text} => Note(text),
    _ => throw FormatException('Invalid Note JSON', json),
  };

  Map<String, Object?> toJson() => {'text': text};
}
