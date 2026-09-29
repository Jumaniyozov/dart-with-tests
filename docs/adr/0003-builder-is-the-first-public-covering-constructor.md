# copyWith and JSON call the first public constructor that covers every field

copyWith and fromJson must build a new object, so they call the builder. The builder
is the first constructor that meets four conditions:

1. It is public.
2. It can be called.
3. Each parameter names a field with an assignable type.
4. The parameters cover every field, except `late` fields with an initializer.

The unnamed constructor is tried first, then named constructors in declaration order.
If none qualifies, copyWith and JSON are not offered.

## Why

- **Validation must not be skipped.** darty ADR 0002 (fourth amendment) makes a
  primary constructor private and puts the check in a public factory, as in
  `class const Limit._(...)` with `factory Limit(...)`. A copyWith that calls
  `Limit._` builds a value the type refuses. That is the "two edges" bug the ADR
  describes.
- **State must not be dropped.** `final List<Expense> _recorded = []` in darty's
  stores is not a constructor parameter. A copy built through the constructor starts
  with an empty list, and nothing reports it.
- **Measured on analyzer 14.4.0.** The element model gives `isPrimary`, `isFactory`,
  `isPrivate`, `isAbstract`, `isLate`, `hasInitializer` and `defaultValueCode`.
  `typeSystem.isAssignableTo` checks the types.

## Considered options

- **Fall back to the private primary constructor.** Rejected: take a class like
  `class const Day._(year, month, day)` whose only public way in is `Day.parse`. The
  fallback lets copyWith build month 13. darty's `Day` does not have this problem,
  because it also has `factory Day(int year, int month, int day)`.
- **Take the public unnamed constructor first, then check its parameters.** Rejected:
  for a factory with raw parameters, such as `factory Limit(String raw, int pence)`, it
  picks a constructor and then refuses it, although a named constructor can qualify.
- **Build from the field list.** Rejected: it breaks for `super.` parameters and
  named parameters with defaults.

## Consequences

**Parameters come from the builder.** `Payment(super.pence, ...)` gets `pence` in
copyWith. The named parameter `{acknowledged = false}` stays named.

**Validation runs in copyWith.** In each of ch25 to ch40, darty's `Day` has
`factory Day(int year, int month, int day)`. That factory is the builder, so
`copyWith(month: 13)` throws instead of building an invalid day.

**Some classes get no copyWith and no JSON.** This holds for darty's stores. The
README lists the reason `noBuilder` with the four conditions above.

**A validating factory can throw on JSON data.** fromJson passes well-typed values to
the builder. If the builder is `Money.fromPence`, a negative number throws
`ArgumentError`. darty avoids this by hand with `_assembled` in ch36. The generator
cannot know a domain rule.
