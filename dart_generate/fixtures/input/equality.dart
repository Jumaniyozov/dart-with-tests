sealed class const Entry(final int pence);

// An inherited field through a super parameter.
// @generate toString, equality
class const Payment(super.pence, final String to) extends Entry;

// A generic class with a bound.
// @generate equality
class const Range<T extends Comparable<T>>(final T low, final T high);

// A collection field compares deeply and adds the import.
// @generate equality
class const Tagged(final String id, final List<String> tags);

// Only the selected fields.
// @generate equality select left..right
class const Span(final int left, final int right, final int extra);

// A mutable class gets no ==.
// @not equality mutableClass
class Tally {
  int count = 0;
}
