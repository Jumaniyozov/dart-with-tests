// A private primary constructor behind a validating factory. The factory is
// the builder, so copyWith and fromJson validate.
// @generate toString, equality, copyWith, json
class const Money._(final int pence) {
  factory Money.fromPence(int pence) {
    if (pence < 0) {
      throw ArgumentError.value(pence, 'pence', 'must not be negative');
    }
    return Money._(pence);
  }

  factory Money.fromJson(Object? json) => switch (json) {
    {'pence': final int pence} => Money.fromPence(pence),
    _ => throw FormatException('Invalid Money JSON', json),
  };

  @override
  String toString() => 'Money(pence: $pence)';

  @override
  bool operator ==(Object other) => other is Money && other.pence == pence;

  @override
  int get hashCode => pence.hashCode;

  Money copyWith({int? pence}) => Money.fromPence(pence ?? this.pence);

  Map<String, Object?> toJson() => {'pence': pence};
}
