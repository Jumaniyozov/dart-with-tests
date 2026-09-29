# The generator set follows Effective Dart and primary constructors

The plugin offers six actions: toString, `==` and hashCode, copyWith, toJson and
fromJson, a getter for a private field, and "Convert to primary constructor". The
Android Studio items Setter, Getter and Setter, and Named Constructor are not built.
Its Constructor item becomes the conversion.

## Why

- **Getter and Setter.** The
  [Effective Dart usage guideline](https://dart.dev/effective-dart/usage#dont-wrap-a-field-in-a-getter-and-setter-unnecessarily)
  is `DON'T wrap a field in a getter and setter unnecessarily`. The lint
  `unnecessary_getters_setters` is in `package:lints/recommended.yaml`. Generated pairs
  have no logic, so every one breaks that lint.
- **Setter alone.** The
  [Effective Dart design guideline](https://dart.dev/effective-dart/design#dont-define-a-setter-without-a-corresponding-getter)
  is `DON'T define a setter without a corresponding getter`.
- **Named Constructor.** Beside a primary constructor, a generative constructor must
  redirect (`non_redirecting_generative_constructor_with_primary`, darty ADR 0002). The
  generator cannot know the arguments, so it can only write placeholders. A snippet
  does that job.
- **Constructor.** The built-in "Create constructor for final fields" inserts
  `Point(this.x, this.y);`, the older form that darty ADR 0002 names as not the
  default. "Convert to primary constructor" writes the header form instead.
- **Getter.** A read-only view of a private field (`int get count => _count;`) is
  idiomatic and breaks no lint.

## Considered options

- **Build the full Android Studio set.** Rejected: two of its items break a lint in
  the user's own rule set, and one has no correct output beside a primary
  constructor.

## Consequences

**The conversion follows darty ADR 0002's rule.** A primary constructor cannot check
anything. A constructor with a body, an initializer list, an assert or an annotation
therefore stays as it is. The conversion never writes `: super(...)`, which breaks
`use_super_parameters`.

**A class with a non-final field gets no `==`.** The
[Effective Dart design guideline](https://dart.dev/effective-dart/design#avoid-defining-custom-equality-for-mutable-classes)
is `AVOID defining custom equality for mutable classes`.

**Collection fields use `package:collection`.** `List ==` compares identity, so the
generated `==` uses `const DeepCollectionEquality()`. If the package is not a
dependency, `depend_on_referenced_packages` (in `package:lints/core.yaml`) reports it.
