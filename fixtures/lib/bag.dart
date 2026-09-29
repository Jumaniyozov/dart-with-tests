import 'package:collection/collection.dart';

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
}) {
  factory Bag.fromJson(Object? json) => switch (json) {
    final Map<String, Object?> map &&
        {
          'rates': final List<Object?> rates,
          'tags': final List<Object?> tags,
          'days': final List<Object?> days,
          'maybe': final List<Object?> maybe,
          'counts': final Map<String, Object?> counts,
          'prices': final Map<String, Object?> prices,
          'n': final num n,
        } =>
      Bag(
        [
          for (final e in rates)
            e is num
                ? e.toDouble()
                : throw FormatException('Invalid "rates" in Bag JSON', json),
        ],
        {
          for (final e in tags)
            e is String
                ? e
                : throw FormatException('Invalid "tags" in Bag JSON', json),
        },
        [
          for (final e in days)
            (e is String ? DateTime.tryParse(e) : null) ??
                (throw FormatException('Invalid "days" in Bag JSON', json)),
        ],
        [
          for (final e in maybe)
            e is String?
                ? e
                : throw FormatException('Invalid "maybe" in Bag JSON', json),
        ],
        {
          for (final MapEntry(:key, :value) in counts.entries)
            key: value is int
                ? value
                : throw FormatException('Invalid "counts" in Bag JSON', json),
        },
        {
          for (final MapEntry(:key, :value) in prices.entries)
            key: Money.fromJson(value),
        },
        n,
        map['raw'],
        label: map.containsKey('label')
            ? switch (map['label']) {
                null => null,
                final String v => v,
                _ => throw FormatException('Invalid "label" in Bag JSON', json),
              }
            : 'none',
      ),
    _ => throw FormatException('Invalid Bag JSON', json),
  };

  @override
  bool operator ==(Object other) =>
      other is Bag &&
      const DeepCollectionEquality().equals(other.rates, rates) &&
      const DeepCollectionEquality().equals(other.tags, tags) &&
      const DeepCollectionEquality().equals(other.days, days) &&
      const DeepCollectionEquality().equals(other.maybe, maybe) &&
      const DeepCollectionEquality().equals(other.counts, counts) &&
      const DeepCollectionEquality().equals(other.prices, prices) &&
      other.n == n &&
      other.raw == raw &&
      other.label == label;

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(rates),
    const DeepCollectionEquality().hash(tags),
    const DeepCollectionEquality().hash(days),
    const DeepCollectionEquality().hash(maybe),
    const DeepCollectionEquality().hash(counts),
    const DeepCollectionEquality().hash(prices),
    n,
    raw,
    label,
  );

  Map<String, Object?> toJson() => {
    'rates': rates,
    'tags': tags.toList(),
    'days': [for (final e in days) e.toIso8601String()],
    'maybe': maybe,
    'counts': counts,
    'prices': {
      for (final MapEntry(:key, :value) in prices.entries) key: value.toJson(),
    },
    'n': n,
    'raw': raw,
    'label': label,
  };
}
