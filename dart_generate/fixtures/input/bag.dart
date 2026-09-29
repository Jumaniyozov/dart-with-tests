import 'money.dart';

// Collections of every element rule, num, Object?, and a nullable field with
// a non-null default.
// @generate equality, json
class const Bag(
  final List<double> rates,
  final Set<String> tags,
  final List<DateTime> days,
  final List<String?> maybe,
  final Map<String, int> counts,
  final Map<String, Money> prices,
  final num n,
  final Object? raw, {
  final String? label = 'none',
});
