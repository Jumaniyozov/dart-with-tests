import 'package:collection/collection.dart';

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
}) {
  factory Expense.fromJson(Object? json) => switch (json) {
    final Map<String, Object?> map &&
        {
          'amount': final Object amount,
          'kind': final String kind,
          'day': final String day,
          'rate': final num rate,
          'tags': final List<Object?> tags,
          'parts': final List<Object?> parts,
        } =>
      Expense(
        Money.fromJson(amount),
        Kind.values.asNameMap()[kind] ??
            (throw FormatException('Invalid "kind" in Expense JSON', json)),
        DateTime.tryParse(day) ??
            (throw FormatException('Invalid "day" in Expense JSON', json)),
        rate.toDouble(),
        switch (map['note']) {
          null => null,
          final String v => v,
          _ => throw FormatException('Invalid "note" in Expense JSON', json),
        },
        switch (map['tip']) {
          null => null,
          final Object v => Money.fromJson(v),
        },
        [
          for (final e in tags)
            e is String
                ? e
                : throw FormatException('Invalid "tags" in Expense JSON', json),
        ],
        [for (final e in parts) Money.fromJson(e)],
        acknowledged: switch (map['acknowledged']) {
          null => false,
          final bool v => v,
          _ => throw FormatException(
            'Invalid "acknowledged" in Expense JSON',
            json,
          ),
        },
      ),
    _ => throw FormatException('Invalid Expense JSON', json),
  };

  @override
  String toString() =>
      'Expense(amount: $amount, kind: $kind, day: $day, rate: $rate, '
      'note: $note, tip: $tip, tags: $tags, parts: $parts, '
      'acknowledged: $acknowledged)';

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.amount == amount &&
      other.kind == kind &&
      other.day == day &&
      other.rate == rate &&
      other.note == note &&
      other.tip == tip &&
      const DeepCollectionEquality().equals(other.tags, tags) &&
      const DeepCollectionEquality().equals(other.parts, parts) &&
      other.acknowledged == acknowledged;

  @override
  int get hashCode => Object.hash(
    amount,
    kind,
    day,
    rate,
    note,
    tip,
    const DeepCollectionEquality().hash(tags),
    const DeepCollectionEquality().hash(parts),
    acknowledged,
  );

  static const _unset = Object();

  Expense copyWith({
    Money? amount,
    Kind? kind,
    DateTime? day,
    double? rate,
    Object? note = _unset,
    Object? tip = _unset,
    List<String>? tags,
    List<Money>? parts,
    bool? acknowledged,
  }) => Expense(
    amount ?? this.amount,
    kind ?? this.kind,
    day ?? this.day,
    rate ?? this.rate,
    identical(note, _unset) ? this.note : note as String?,
    identical(tip, _unset) ? this.tip : tip as Money?,
    tags ?? this.tags,
    parts ?? this.parts,
    acknowledged: acknowledged ?? this.acknowledged,
  );

  Map<String, Object?> toJson() => {
    'amount': amount.toJson(),
    'kind': kind.name,
    'day': day.toIso8601String(),
    'rate': rate,
    'note': note,
    'tip': tip?.toJson(),
    'tags': tags,
    'parts': [for (final e in parts) e.toJson()],
    'acknowledged': acknowledged,
  };
}
