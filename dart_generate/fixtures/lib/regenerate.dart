// A nullable field was added after copyWith was generated, and there is no
// _unset yet. copyWith is the last member.
// @regenerate copyWith
class const Memo(final String text, final String? tag) {
  Memo copyWith({String? text, Object? tag = _unset}) => Memo(
    text ?? this.text,
    identical(tag, _unset) ? this.tag : tag as String?,
  );

  static const _unset = Object();
}

// A hand-written fromJson is the last member, and toJson is missing.
// @regenerate json
class User {
  final String name;

  User(this.name);

  factory User.fromJson(Object? json) => switch (json) {
    {'name': final String name} => User(name),
    _ => throw FormatException('Invalid User JSON', json),
  };

  Map<String, Object?> toJson() => {'name': name};
}

// toJson comes right after the constructor, and fromJson is missing.
// @regenerate json
class Point {
  final int x;

  Point(this.x);

  factory Point.fromJson(Object? json) => switch (json) {
    {'x': final int x} => Point(x),
    _ => throw FormatException('Invalid Point JSON', json),
  };

  Map<String, Object?> toJson() => {'x': x};

  int get twice => x * 2;
}

// A header constructor, toJson is the first member, and fromJson is missing.
// @regenerate json
class const Id(final String value) {
  factory Id.fromJson(Object? json) => switch (json) {
    {'value': final String value} => Id(value),
    _ => throw FormatException('Invalid Id JSON', json),
  };

  Map<String, Object?> toJson() => {'value': value};

  int get length => value.length;
}

// == is the last member, and hashCode is missing.
// @regenerate equality
class const Pt(final int x, final int y) {
  @override
  bool operator ==(Object other) => other is Pt && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

// hashCode is the last member, and == is missing.
// @regenerate equality
class const Size(final int width, final int height) {
  @override
  int get hashCode => Object.hash(width, height);

  @override
  bool operator ==(Object other) =>
      other is Size && other.width == width && other.height == height;
}
