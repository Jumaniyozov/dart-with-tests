// A public unnamed factory is the builder, so copyWith validates.
// @generate copyWith
class const Limit._(final String category, final int pence) {
  factory Limit(String category, int pence) {
    if (category.isEmpty) throw ArgumentError.value(category, 'category');
    return Limit._(category, pence);
  }
}

// An abstract class has no builder.
// @not copyWith noBuilder
sealed class const Account(final int pence);

// A super parameter, and a nullable field that copyWith can clear.
// @generate copyWith
class const Deposit(super.pence, final String? note) extends Account;

class Base {
  const Base({required this.id});

  final String id;
}

// A super parameter of a classic constructor: the inherited field counts, as
// it does for a primary constructor.
// @generate copyWith, toString, equality
class Item extends Base {
  const Item({required super.id, required this.name});

  final String name;
}

// The unnamed constructor does not take the inherited field, so the named
// one is the builder, and a copy keeps its id.
// @generate copyWith
class Tag extends Base {
  const Tag(this.name) : super(id: 'fixed');

  const Tag.full({required super.id, required this.name});

  final String name;
}

// An unbounded type parameter, a private header field and a var field.
// @generate copyWith
class Box<T>(final T value, final int _count, var String note);

// State outside the constructor: no builder.
// @not copyWith noBuilder
class Store {
  final List<int> _recorded = [];

  void add(int value) => _recorded.add(value);
}

// copyWith no longer needs the sentinel, so it goes.
// @regenerate copyWith
class const Note(final String text) {
  static const _unset = Object();

  Note copyWith({Object? text = _unset}) =>
      Note(identical(text, _unset) ? this.text : text as String);
}

// A stale copyWith is replaced, and the sentinel that it still needs stays
// as it is written.
// @regenerate copyWith
class const Memo(final String text, final String? tag) {
  static const Object _unset = Object();

  Memo copyWith({String? text}) => Memo(text ?? this.text, tag);
}

// A sentinel without a copyWith is a leftover. The action is still
// "Generate", and the sentinel stays as it is written.
// @generate copyWith
class const Draft(final String title, final String? body) {
  // ignore: unused_field
  static const Object _unset = Object();
}
