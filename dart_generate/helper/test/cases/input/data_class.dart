class Order {
  final String id;
  final List<String> items;
  final Map<int, String> notes;

  const Order({required this.id, required this.items, required this.notes});
}
