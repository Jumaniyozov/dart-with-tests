# Primary constructors are the book's default class syntax

Every class this book declares uses the Dart 3.13 primary constructor — the
parameter list in the class header — and the `new(...)` / `factory name(...)`
declaration forms in the body. The pre-3.13 spelling, where the class name is
repeated on each constructor, is shown once and named as the older form.

```dart
class const Money(final int pence) { … }   // this book
class Money { final int pence; const Money(this.pence); }   // everyone else
```

## Why

The header form says once what the long form says three times: the field, the
constructor parameter, and the assignment. For a book whose classes are mostly
small value types, that is the difference between a class being one line and
being five, and it keeps the reader's attention on what the type *means*.

It also lets study 15 teach constructors and fields as one idea rather than two,
which is the order a beginner meets them anyway.

## Considered options

- **Teach the long form as the default, mention the new one.** What every other
  Dart book does, and the safe choice. Rejected: it spends the reader's first
  encounter on syntax that exists for historical reasons, and this book has no
  legacy code to be compatible with. A book published now that teaches the older
  spelling as the default is dated on the day it ships.
- **Teach both from the start, side by side.** Rejected: doubles the surface of
  study 15 and gives the reader a choice they have no basis to make yet.

## Consequences

**The book requires Dart 3.13 or later, hard.** Study 1 already says "3.13 or
later"; this is what makes that non-negotiable rather than a preference. Primary
constructors were experimental in 3.12 and stable in 3.13, and the constructor
declaration forms changed with them.

**The reader must be able to read the older form,** because almost all existing
Dart uses it. Study 15 handles this with `ch15_money/lib/older.dart`: a real,
compiled file spelling `Split` the pre-3.13 way, with a test asserting it behaves
identically. That file is the contract — the older form is *shown*, not
described, and it cannot drift.

**A primary constructor cannot check anything, and this shapes the code.**
Measured while writing study 15: a class with a primary constructor may only have
constructors that redirect to it, and a redirecting constructor may not `assert`.
So every class in this book with an invariant is written out in the body form —
`Split` in 15, `Range` in 18 — and the rule for choosing between the two forms is
the analyzer's rather than a matter of taste. This turned out to be a feature:
the choice is mechanical and explicable.

**Interaction with inheritance and mixins is not obvious and had to be measured.**
`@override` is legal on a header parameter, which is how a header field satisfies
an inherited getter or a mixin's requirement (studies 16 and 17 both need this).
`super.pence` works in the header, and the longhand `: super(pence)` trips
`use_super_parameters` from `package:lints/recommended.yaml`.

**The same rule turned up again in a second declaration form.** Study 19's
extension types have their own header — `extension type const Pence(int value)` —
and it behaves the same way: it has no initialiser list, and it has already taken
the unnamed constructor, so a checked constructor beside it is a
`duplicate_constructor` error and the check has to go on a named one. Two
unrelated features, one rule: *when a type must check something, the check goes on
a constructor with a body to put it in.* That is now the book's phrasing of it, and
it is worth preferring over "write the class out in body form", which was the
study-15-only version and does not generalise — an extension type has no body form
to fall back to.

**Reversing this is expensive and gets more so.** Studies 15 to 22 declare classes
and extension types this way. Reverting would mean rewriting every class in Book I
and rewriting study 15 around a different spine.

**Amended while outlining Book II: a factory may sit beside a primary constructor, and
that is a third option this record missed.** The rule above was drawn from one route
only — an `assert` in an initialiser list — and concluded that every class with an
invariant must be written out in body form. Measured on Dart 3.13.2, the analyzer's
actual rule is narrower:

```
error - Classes with primary constructors can't have non-redirecting generative
        constructors. - non_redirecting_generative_constructor_with_primary
```

It names *generative* constructors. A **factory** is not one, and a factory has a body
to check in. So a class may keep its primary constructor, make it private, and validate
in a factory:

```dart
class const Money._(final int pence) {
  factory Money.fromPence(int pence) {
    if (pence < 0) throw ArgumentError.value(pence, 'pence', 'must not be negative');
    return Money._(pence);
  }
}
```

Restated, the rule is: **a generative constructor cannot sit beside a primary
constructor; a factory can.** Studies 15 and 18 are unaffected — `Split` and `Range`
still want body form, because an `assert` is the right check for arguments that come
from code.

That distinction is the reason the two forms coexist rather than one replacing the
other. Study 10's Gloss already told the reader `assert` is stripped from release
builds, so an `assert` guards against the programmer's own mistake and nothing else.
`Money.fromPence` takes a number a person typed at a terminal, which is a fact about the
world arriving at run time, so it must throw. Book II's `Money` therefore uses the
factory form and study 26 says why — which confirms study 10's Gloss rather than
contradicting it.
