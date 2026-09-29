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
}
