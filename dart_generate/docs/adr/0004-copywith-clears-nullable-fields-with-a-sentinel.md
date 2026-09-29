# copyWith clears a nullable field with a sentinel default

For a nullable field, copyWith takes `Object? note = _unset` and passes
`identical(note, _unset) ? this.note : note as String?`. The class gets one
`static const _unset = Object();`. A non-nullable field takes `T? x` and passes
`x ?? this.x`.

## Why

- **The natural call clears the field.** `e.copyWith(note: null)` sets `note` to null.
  With `note ?? this.note`, that call keeps the old value, and the caller has no way
  to clear it.
- **It compiles under the strictest settings.** A test under `strict-casts`,
  `strict-inference`, `strict-raw-types` and `package:lints/recommended.yaml` reported
  no issues. `copyWith(note: null).note` printed `null`.

## Considered options

- **A closure parameter, `String? Function()? note`.** Type-checked at compile time,
  but the call site becomes `copyWith(note: () => null)`. Rejected by the user.
- **Plain `??`.** The simplest form. Rejected: it cannot clear a field.

## Consequences

**The parameter type is `Object?`.** A wrong type fails at run time in the cast, not
at compile time.

**A type parameter with a nullable bound uses the sentinel too.** In `Box<T>`, `T` can
be `int?`. Then `T? value` with `??` cannot clear the field. A test with `Box<int?>`
cleared it with `value as T`.

**A private builder parameter gets a public name.** A named parameter cannot be
private. So `_count` becomes `{int? count}`, and the call passes `count ?? _count`.

**Regenerating removes a stale sentinel.** A class with no nullable field left has no
use for `_unset`. The edit removes it, so no `unused_field` warning appears.

**An `Object?` or `dynamic` parameter gets no cast.** `raw as Object?` is the warning
`unnecessary_cast`. The sentinel still applies, so `copyWith(raw: null)` clears it.
