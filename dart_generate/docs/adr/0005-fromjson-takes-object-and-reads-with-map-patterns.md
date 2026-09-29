# fromJson takes Object? and reads with map patterns

The generated fromJson is `factory X.fromJson(Object? json) => switch (json) {...}`.
Required keys go in a map pattern. Nullable and defaulted keys are read after the
match. Every failure throws `FormatException` with the key name. toJson is an
instance member.

## Why

- **`jsonDecode` returns `dynamic`.** Under `strict-casts: true`, passing it to a
  `Map<String, Object?>` parameter is the error `argument_type_not_assignable`. An
  `Object?` parameter takes it directly, and an untyped map pattern matches the
  runtime `_Map<String, dynamic>`.
- **A map pattern checks the type and the key together.** This is also darty's own
  style in `expenseFromJson`. A cast such as `json['day'] as String` throws a
  `TypeError`, which is an `Error`, and darty study 26 says an `Error` is never caught.
- **`FormatException` is an `Exception`.** A caller can catch it. It carries the whole
  JSON value as its source.
- **toJson must be a member.** `jsonEncode` calls `toJson()` through a dynamic call, and
  an extension method is resolved from the static type. A test with an extension
  `toJson` threw `JsonUnsupportedObjectError`.

## Considered options

- **Casts, as the hzgood extension writes them.** Rejected: bad input throws an
  `Error` that names no key.
- **darty's style: an extension plus a top-level `X? xFromJson(Object? json)` that
  returns null.** Rejected by the user for generated code: `jsonEncode` cannot see an
  extension `toJson`.
- **The Dart 3.13 short form `factory fromJson(...)`.** darty ADR 0002 names this
  form. Rejected by the user: darty's code writes 69 named factories as
  `factory X.name(...)`, and only 2 in ch15 use the short form.

## Consequences

Each rule below comes from a test on Dart 3.13.2.

- **A map pattern cannot mark a key as optional.** `{'body': String? _}` did not match
  `{"title": "t"}`. So nullable and defaulted keys are read after the match. darty's
  `code/ch36_expenses/lib/src/expense.dart:94` does the same by hand for
  `acknowledged`.
- **A default needs `containsKey`.** For `{final String? label = 'none'}`, a check on
  `null` alone turns a JSON `null` into `'none'`. With
  `map.containsKey('label') ? check : 'none'`, the explicit `null` survives.
- **`double` reads through `num`.** JSON `1` did not match `double _` but matched
  `num _`. The rule reads `num` and calls `.toDouble()`, for lists too.
- **An enum reads through `asNameMap()`.** `values.byName('nope')` threw
  `ArgumentError`, which is an `Error`. `asNameMap()['nope']` returned `null`, and the
  rule throws `FormatException` for it.
- **Some types get no JSON.** JSON is not offered for type-parameter fields, nested
  collections or maps with non-String keys.
- **A missing `X.fromJson` is a compile error.** The error appears on the generated
  line and names the type. The generator does not hide the action for it.
- **Validation can still throw.** See ADR 0003: a validating builder can throw
  `ArgumentError` on well-typed data.
- **`DateTime` reads through `tryParse`.** `DateTime.parse('x')` throws a
  `FormatException` that names no key. `tryParse` returns `null`, and the rule throws
  its own `FormatException` with the key.
- **`Object?` and `dynamic` are read after the match.** They are nullable, so they
  follow the rule for nullable keys: `map['raw']`, with no check.
