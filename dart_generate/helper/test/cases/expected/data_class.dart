import 'package:collection/collection.dart';

class Order {
  final String id;
  final List<String> items;
  final Map<int, String> notes;

  const Order({required this.id, required this.items, required this.notes});

  @override
  String toString() => 'Order(id: $id, items: $items, notes: $notes)';

  @override
  bool operator ==(Object other) =>
      other is Order &&
      other.id == id &&
      const DeepCollectionEquality().equals(other.items, items) &&
      const DeepCollectionEquality().equals(other.notes, notes);

  @override
  int get hashCode => Object.hash(
    id,
    const DeepCollectionEquality().hash(items),
    const DeepCollectionEquality().hash(notes),
  );

  Order copyWith({String? id, List<String>? items, Map<int, String>? notes}) =>
      Order(
        id: id ?? this.id,
        items: items ?? this.items,
        notes: notes ?? this.notes,
      );
}
