// copyWith and toJson leave out note: two warnings.
class Task {
  final String title;
  final String? note;

  const Task(this.title, {this.note});

  Task copyWith({String? title}) => Task(title ?? this.title);

  Map<String, Object?> toJson() => {'title': title};
}

// fromJson leaves out note: a warning on fromJson.
class Tag {
  final String name;
  final String? note;

  const Tag(this.name, {this.note});

  factory Tag.fromJson(Map<String, Object?> json) =>
      Tag(json['name']! as String);

  Map<String, Object?> toJson() => {'name': name, 'note': note};
}

// toString and == leave out y: a hint on each.
class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

  @override
  String toString() => 'Point(x: $x)';

  @override
  bool operator ==(Object other) => other is Point && other.x == x;

  @override
  int get hashCode => x.hashCode;
}

// A hand-written fromJson with its own keys covers every field: no mark.
class Reading {
  final double temperature;
  final int code;

  const Reading({required this.temperature, required this.code});

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
    temperature: json['temperature_2m'] as double,
    code: json['weather_code'] as int,
  );
}

// A mutable class gets no == hint. A hand-written toString gets no hint.
class Counter {
  int count;
  int step;

  Counter(this.count, this.step);

  @override
  String toString() => 'count is $count';

  @override
  bool operator ==(Object other) => other is Counter && other.count == count;

  @override
  int get hashCode => count.hashCode;
}

// toString and == read the private field through its getter: no mark.
class Money {
  final int _pence;

  const Money(this._pence);

  int get pence => _pence;

  @override
  String toString() => 'Money(pence: $pence)';

  @override
  bool operator ==(Object other) => other is Money && other.pence == pence;

  @override
  int get hashCode => pence.hashCode;
}

// A fromJson that sets each field in its initializer list covers every field:
// no mark.
class Contact {
  final String name;
  final String email;

  const Contact(this.name, this.email);

  Contact.fromJson(Map<String, Object?> json)
    : name = json['name']! as String,
      email = json['email']! as String;

  Map<String, Object?> toJson() => {'name': name, 'email': email};
}
