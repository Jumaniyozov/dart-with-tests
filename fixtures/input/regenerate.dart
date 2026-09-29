// A nullable field was added after copyWith was generated, and there is no
// _unset yet. copyWith is the last member.
// @regenerate copyWith
class const Memo(final String text, final String? tag) {
  Memo copyWith({String? text}) => Memo(text ?? this.text, tag);
}

// A hand-written fromJson is the last member, and toJson is missing.
// @regenerate json
class User {
  final String name;

  User(this.name);

  factory User.fromJson(Object? json) =>
      User((json! as Map<String, Object?>)['name']! as String);
}

// toJson comes right after the constructor, and fromJson is missing.
// @regenerate json
class Point {
  final int x;

  Point(this.x);

  Map<String, Object?> toJson() => {'x': x};

  int get twice => x * 2;
}

// A header constructor, toJson is the first member, and fromJson is missing.
// @regenerate json
class const Id(final String value) {
  Map<String, Object?> toJson() => {'value': value};

  int get length => value.length;
}

// == is the last member, and hashCode is missing.
// @regenerate equality
class const Pt(final int x, final int y) {
  @override
  bool operator ==(Object other) => other is Pt && other.x == x;
}

// hashCode is the last member, and == is missing.
// @regenerate equality
class const Size(final int width, final int height) {
  @override
  int get hashCode => width.hashCode;
}
