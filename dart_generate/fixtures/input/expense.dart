import 'money.dart';

enum Kind { food, rent }

// Every JSON type rule at once.
// @generate toString, equality, copyWith, json
class const Expense(
  final Money amount,
  final Kind kind,
  final DateTime day,
  final double rate,
  final String? note,
  final Money? tip,
  final List<String> tags,
  final List<Money> parts, {
  final bool acknowledged = false,
});
