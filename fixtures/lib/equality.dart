import 'package:collection/collection.dart';

sealed class const Entry(final int pence);

// An inherited field through a super parameter.
// @generate toString, equality
class const Payment(super.pence, final String to) extends Entry {
  @override
  String toString() => 'Payment(pence: $pence, to: $to)';

  @override
  bool operator ==(Object other) =>
      other is Payment && other.pence == pence && other.to == to;

  @override
  int get hashCode => Object.hash(pence, to);
}

// A generic class with a bound.
// @generate equality
class const Range<T extends Comparable<T>>(final T low, final T high) {
  @override
  bool operator ==(Object other) =>
      other is Range<T> && other.low == low && other.high == high;

  @override
  int get hashCode => Object.hash(low, high);
}

// A collection field compares deeply and adds the import.
// @generate equality
class const Tagged(final String id, final List<String> tags) {
  @override
  bool operator ==(Object other) =>
      other is Tagged &&
      other.id == id &&
      const DeepCollectionEquality().equals(other.tags, tags);

  @override
  int get hashCode =>
      Object.hash(id, const DeepCollectionEquality().hash(tags));
}

// Only the selected fields.
// @generate equality select left..right
class const Span(final int left, final int right, final int extra) {
  @override
  bool operator ==(Object other) =>
      other is Span && other.left == left && other.right == right;

  @override
  int get hashCode => Object.hash(left, right);
}

// A mutable class gets no ==.
// @not equality mutableClass
class Tally {
  int count = 0;
}
