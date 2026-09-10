# Outline

Book I: Foundations (studies 1–22) — written. Book II: Writing good Dart
(studies 23–34) — written through study 28, outlined to 34. Book III (35–39) and
Book IV (40–44) have no outline.

Entries marked **WRITTEN** are no longer plans. They are the record of what
construction measured, including the places where it contradicted the plan, and
they are the reason a later study can trust the one before it.

## Book I: Foundations (studies 1–22)

Spine A′: nouns (4–9) → flow and behaviour (10–12) → composite data (13–14) →
objects (15–19) → failure and time (20–22).

Two ordering rules are load-bearing and were chosen against the obvious
alternative. Do not reshuffle without reading them.

- **Null safety follows Maps, it does not precede them.** Numbers, strings,
  enums and lists can all be taught honestly with no nullable type in sight.
  `map['missing']` returns `V?` and cannot be dodged. The analyzer is a
  character in this book, so the study where its message first says `String?`
  is the study that must explain it — and the one after teaches it properly.
- **Iterables follow functions.** `list.map((x) => x * 2)` needs function
  literals. The v1 book put the Iterable pipeline before closures; that was
  backwards and is corrected here.

Two debts this spine accepts on purpose, both matching how studies 1–3 already
work: study 6 uses `switch` before study 10 formalises it, and study 7 uses
`for-in` before study 10 formalises it. Light use then deepen is the method.

---

## Written

| # | Title | Slug | Package |
| --- | --- | --- | --- |
| 1 | Hello, Dart | `hello-dart` | `ch01_hello` |
| 2 | Your first test | `your-first-test` | `ch02_greeting` |
| 3 | Variables | `variables` | `ch03_variables` |
| 4 | Numbers | `numbers` | `ch04_money` |
| 5 | Strings and text | `strings` | `ch05_label` |
| 6 | Enums | `enums` | `ch06_language` |
| 7 | Lists | `lists` | `ch07_basket` |
| 8 | Maps and sets | `maps-and-sets` | `ch08_tally` |
| 9 | Null safety | `null-safety` | `ch09_lookup` |
| 10 | Control flow | `control-flow` | `ch10_ledger` |
| 11 | Functions and closures | `functions` | `ch11_pipeline` |
| 12 | Iterables | `iterables` | `ch12_report` |
| 13 | Records | `records` | `ch13_split` |
| 14 | Patterns and switch | `patterns` | `ch14_command` |
| 15 | Classes and constructors | `classes` | `ch15_money` |
| 16 | Inheritance and interfaces | `inheritance` | `ch16_entries` |
| 17 | Mixins | `mixins` | `ch17_receipts` |
| 18 | Generics | `generics` | `ch18_range` |
| 19 | Extensions and extension types | `extension-types` | `ch19_pence` |
| 20 | Errors and exceptions | `errors` | `ch20_till` |
| 21 | Futures and async/await | `futures` | `ch21_payment` |
| 22 | Streams | `streams` | `ch22_feed` |

### Promises already in print

Published Gloss blocks commit to specific study numbers. These are contracts with
the reader, not suggestions.

- `your-first-test.mdx` — *"Study 6 replaces this with an enum"*. Study 6 must
  return to `hello(name, language: 'Spanish')` and kill the stringly-typed
  parameter.
- `variables.mdx`, on `final` binding the name rather than freezing the value —
  *"meet it properly in Study 7"*. Study 7 must show `final` list vs `const` list
  with a mutation.
- `variables.mdx`, on canonicalisation — *"`const` constructors get their own
  study later — Study 15"*. Originally said Study 7, which was impossible:
  `const` constructors need classes. Corrected in the source.

Studies 4-14 added more. These are the ones **not yet paid**, gathered by
grepping every study for a reference to a later one. Read this list before
writing 15, 16 or 20; each is a sentence a reader has already been given.

| Owed by | Made in | The reader was promised |
| --- | --- | --- |
**Paid.** Study 23 is written, and it settled the row above: `Money._` is refused from
another library (`new_with_undefined_constructor`), reached freely from inside its own
file, and an extension type with the same private constructor is still walked past by
`-1 as Pence`. Book I's promise table is now empty.

Also paid since: 15→16 (a family that shares behaviour), 16→17 (sharing
without a family), 17→18 (same behaviour, different type), 18→19 (a type that
exists for the compiler and disappears before the program runs), 4→19 (pence
stop being an `int` by convention and become a type), 10→20 and 15→20 and
19→20 (bad input answered at run time, all three promises paid by one study),
9→20 (`tryParse`'s null against an exception that can say why), 20→21 (the
failure that arrives after the function that caused it has returned), 12→22
and 21→22 (the same verbs and the same waiting, over many values).

Paid and verified: 2→6 (enum kills the stringly-typed parameter), 3→7
(`final` list vs `const` list), 7→12 (the shorter way to sum, needing
closures), 8→9 (the question mark), 10→11 and 10→12 (functions named, then
the loops deleted), 12→13 and 12→14, 13→14, 3→15 (`const` constructors),
13→15 (name, methods, invariants), 6→16 (enums with fields and methods),
14→16 (`sealed` closes exhaustive switching).

---

## To write

**Book I is written.** Studies 1-22 are committed; the entries below are kept
as the record of what was intended, and each study's own commit message
records what construction actually measured.

**Book II is outlined below**, and studies 23–28 are written. It opens at study 23
with libraries, imports and `_` privacy, which pays the only debt Book I leaves
unpaid. `part` / `export` was folded into that study as a Gloss rather than taught.

### 4 — Numbers · `numbers` · `ch04_money`

Teaches `int`, `double`, `num`, arithmetic, integer division `~/`, `%`,
comparison, and **digit separators** (Dart 3.6).

Toy: `money.dart`, holding amounts as whole cents in an `int`.

The mechanism to name: why money is not a `double`. `0.1 + 0.2` is not `0.3`
because binary floating point cannot represent tenths, exactly as decimal cannot
represent a third. Show the failing test, then store cents. This is Principle 3
working for us — the reader meets the bad choice, sees it fail in a transcript,
and the fix is the study.

Seeds Book II: the expense tracker's money type starts here.

Gloss: `int` on the web compiles to a JS number and is not 64-bit. Named now,
met properly if and when the book targets the web.

### 5 — Strings and text · `strings` · `ch05_label`

Teaches interpolation beyond `$name`, adjacent literals, raw strings, multi-line
strings, `StringBuffer`, and the difference between code units, code points and
grapheme clusters.

Toy: `label.dart` — truncate a label to a width without cutting a character in
half.

The mechanism to name: `'👋'.length` is 2. A Dart `String` is UTF-16 code units,
so `length` counts storage, not characters. `runes` gets code points;
`package:characters` gets what a human calls a character. Study 3 already wrote
`name.split('')`, and this study is where we say what that does and does not
handle. Measured, not assumed: `'café'.split('')` is 4 when the é is one code
point, 5 when it is `e` plus a combining accent, and any emoji splits into
surrogate halves. So the rule is not "non-ASCII breaks it" — it is that
`split('')` cuts on storage boundaries, which stop matching characters as soon
as the text leaves the Basic Multilingual Plane or uses combining marks.

Gloss: building a string in a loop with `+=` allocates every time.
`StringBuffer` does not. Costs nothing to learn now.

### 6 — Enums · `enums` · `ch06_language`

**Pays the study-2 promise.** Teaches `enum`, `values`, `.name`, `index`,
exhaustive `switch` expressions over an enum, and **dot shorthands** (Dart 3.10)
— `hello('Elodie', language: .spanish)`.

Toy: `greeting.dart` from study 2, rewritten so `language: 'Klingon'` no longer
compiles.

The mechanism to name: exhaustiveness. With a `String` the compiler cannot know
you handled every case; with an enum it can, so adding a case turns every
unhandled `switch` into a compile error. The type does not merely document the
closed set, it enforces it — and it moves the failure from run time to compile
time, which is the same trade study 3 drew for `const`.

Later: enhanced enums (members, `implements`) need classes, so they wait for 16.

### 7 — Lists · `lists` · `ch07_basket`

**Pays the study-3 promise.** Teaches `List<T>`, literals, indexing, `add`,
`length`, growable vs fixed-length, `const` lists, spread `...`, and
collection-`if` / collection-`for`.

Toy: `basket.dart` — a list of items you add to.

The mechanism to name: `final items = [...]` stops reassignment, `items.add()`
still works, `const [...]` is frozen and mutating it throws at run time — not
compile time, which surprises people. Show all three in a transcript.

Also pays the canonicalisation half of study 3's second Gloss: `const [1, 2]` and
`const [1, 2]` are *identical*, one object, not two equal ones. That is
canonicalisation arriving at objects, which is what the Gloss promised.
The `const` *constructor* half of that Gloss now points at study 15, where it
belongs. Study 7 owes the reader canonicalisation, not constructors.

Gloss: `List<int>` vs `List<int?>` vs `List<int>?` are three different types.
Named here, met properly in 9.

### 8 — Maps and sets · `maps-and-sets` · `ch08_tally`

Teaches `Map<K, V>`, literals, `[]`, `putIfAbsent`, `containsKey`, iteration
order, `Set<T>`, and set operations.

Toy: `tally.dart` — count how often each word appears.

The mechanism to name: `map[key]` returns `V?`, always. It has to — the key may
be absent, and Dart will not invent a value. This is the study where the
analyzer first says `int?` in a transcript, and we point at it and say: the next
study is about this.

Gloss: `{}` is an empty `Map`, not an empty `Set`. `<int>{}` is a set.

### 9 — Null safety · `null-safety` · `ch09_lookup`

Teaches `T?`, `??`, `??=`, `?.`, `!`, `late`, flow analysis and promotion,
`int.tryParse` vs `int.parse`, and **null-aware elements** (Dart 3.8).

Toy: continues `tally.dart` — read a count that may not be there.

The mechanism to name: nullability is in the type, checked at compile time, and
erased at run time. `String?` and `String` are different types the compiler
tracks; `!` is not a conversion, it is a run-time assertion you are promising to
be right about. Show `!` throwing in a transcript so the reader sees the cost.
Then promotion: after `if (x != null)`, `x` is `String` inside the branch, and
the reason it does not promote for a field is that another thread of the program
could change it between the check and the use.

Best practice: prefer `??` and promotion over `!`. Verify the lint name before
quoting it.

### 10 — Control flow and loops · `control-flow` · `ch10_ledger`

Teaches `if`/`else`, `for`, `for-in`, `while`, `do-while`, `break`, `continue`,
labels, the `switch` **statement** (against the expression form from 6), and
`assert`.

Toy: `ledger.dart` — walk a list of entries and total them by hand, before
study 12 shows the short way.

Principle 3 applies hard here: say out loud that the loops in this study are
the verbose form, and name study 12 as the one that replaces them.

Gloss: `assert` is stripped from release builds. It is for catching your own
bugs, never for validating input.

### 11 — Functions and closures · `functions` · `ch11_pipeline`

Teaches positional, optional positional and named parameters, defaults,
`required`, `=>`, anonymous functions, function types, tear-offs, and closures.

Toy: `pipeline.dart` — a list of transformations applied in order.

The mechanism to name: a closure captures the variable, not its value.
**Measured, and it corrects what this outline first said:** a C-style
`for (var i = 0; …)` in Dart *does* give a fresh binding per iteration, exactly
like `for (final x in …)` — both produce `[0, 1, 2]`, not `[3, 3, 3]`. Dart does
not have JavaScript's `var` trap. The rule still bites when the variable is
declared *outside* the loop, and that is where the study demonstrates it.

This study finally names machinery the reader has used since study 2 — say that
explicitly, it is satisfying.

### 12 — Iterables · `iterables` · `ch12_report`

**Depends on 11.** Teaches `Iterable<T>`, `map`, `where`, `fold`, `reduce`,
`expand`, `take`, `skip`, `any`, `every`, `toList`, and laziness.

Toy: `report.dart` — replaces the hand-written loops from study 10.

The mechanism to name: `map` does no work. It returns a lazy `Iterable`, and
nothing runs until something asks for elements. Prove it with a `print` inside
the callback and a transcript showing the order. Then the trap: iterating a lazy
chain twice does the work twice.

### 13 — Records · `records` · `ch13_split`

Teaches record types, positional and named fields, record equality, destructuring
in a variable declaration, and returning more than one value.

Toy: `split.dart` — return the whole and the remainder together.

The mechanism to name: records are structurally typed and have value equality by
default, which classes do not. `(1, 2) == (1, 2)` is true. That is the whole
reason they exist and it is where they stop — a record has no name, no methods
and no invariants, so the moment you want any of those you want a class (15).

### 14 — Patterns and switch · `patterns` · `ch14_command`

Teaches destructuring patterns, `switch` expressions with patterns, guards
(`when`), `if-case`, exhaustiveness over enums and records, and the `_` wildcard
in pattern position (which study 3 already met in its other role).

Toy: `command.dart` — parse a small command into a record and act on it.

Exhaustiveness over `sealed` classes needs 16; forward-reference it.

## Studies 15–22 — objects, failure and time

Deliberately thin. These are fifteen studies away; specific toys and mechanisms
guessed from here would read as commitments and be wrong. Each entry fixes the
title, the teaching goal and the dependency that pins its position. They earn
detail when we outline them properly, the way 4–14 were.

| # | Title | Goal | Pinned by |
| --- | --- | --- | --- |
| 15 | Classes and constructors | Build a type with primary constructors (3.13) and the `new();` declaration form as the default | Needs records (13) for the contrast: what a record cannot do |
| 16 | Inheritance, interfaces, abstract | `extends` / `implements` / `abstract`, and the class modifiers; `sealed` closes exhaustive switching | Needs classes (15) and patterns (14) |
| 17 | Mixins | Share behaviour without inheritance; clash order is left-to-right, rightmost wins | Needs inheritance (16) to contrast against |
| 18 | Generics | Generic classes and methods, bounds, and reified type arguments at run time | Needs classes (15) |
| 19 | Extensions and extension types | Add methods to a type you do not own; extension types as compile-time-only wrappers | Needs generics (18); closes the cents/dollars problem study 4 opens |
| 20 | Errors and exceptions | `throw`, `try`/`on`/`catch`/`finally`, `rethrow`, and which of `Error` and `Exception` you mean | Needs classes (15) to define exception types |
| 21 | Futures and async/await | One value later; the event loop, and why `await` does not block | Needs errors (20) for async failure |
| 22 | Streams | Many values later; closes Book I | Needs futures (21) |

The one detail worth fixing now, because it is the book's sharpest
differentiator: **study 15 teaches primary constructors as the default form**
and shows the long form once so the reader can read older code. Primary
constructors went stable in 3.13 and the constructor declaration syntax changed
with them (`new();`, `factory ()`). Every other Dart book teaches the long form
as the default. This one does not have to.

## Deliberately not in Book I

- **Libraries, imports, `_` privacy, `part` / `export`.** Needed to build a real
  package, so it opens Book II at study 23.
- **Operator overloading.** ~~Book IV.~~ **Book II, study 31** — study 25 overrides
  `operator ==`, so the book teaches operator overloading whether it admits to it or
  not. Study 31 owns it, where totalling makes `Money + Money` the obvious want.
- **Isolates, FFI, codegen, performance.** Book IV (40–44), per PRODUCT.md.
- **Enhanced enums.** Folded into 16, once classes exist.
- **`package:checks`.** Mentioned once, never taught, per PRODUCT.md.

## Book II: Writing good Dart (studies 23–34)

One expense tracker, grown one slice per study, shipped as twelve snapshot packages —
`code/ch23_expenses/` through `code/ch34_expenses/`. ADR 0004 records why twelve copies
rather than one growing package, and the `SLICE` manifest that keeps them honest. ADR
0003 records the order.

The domain's vocabulary is in `CONTEXT.md`, which is a glossary and holds no
implementation detail. Read it before writing any of these.

Book II's spine is **when the reader can run it**. `dart run` works in study 24 and
every later study changes a program that already works. That is the structural
difference from Book I, where each study is an independent toy.

### Facts measured while outlining, so no study need guess them

Everything below was run on Dart 3.13.2 with `code/analysis_options.yaml`
(`package:lints/recommended.yaml` 6.1.0 plus strict casts, inference and raw types).
Anything in a study entry that is *not* on this list is unverified and must be run
before it is written as prose.

| Measured | Result |
| --- | --- |
| `class const Money._(final int pence)` | Legal. A private **primary** constructor analyzes clean. |
| A generative ctor beside a primary one | `non_redirecting_generative_constructor_with_primary`. A **factory** is fine — ADR 0002 amended. |
| `Money._` called from another library | `new_with_undefined_constructor` — "doesn't have a constructor named `_`". |
| `Money._` called from **the same library** | Compiles and runs. An unrelated class walks straight past the check. |
| `-1 as Pence` past a private extension-type ctor | Succeeds, yields `-1`, `dart analyze` clean. |
| `lib/src/` + barrel `export` + relative imports inside `lib/` | Analyzes clean under this lint set. |
| `ch23_expenses` → `ch24_expenses` rename | All of `lib/` byte-identical; `bin/` differs by one line. |
| `local.microsecondsSinceEpoch == utc.…` | `true`. |
| `local == utc` for that same instant | **`false`.** |
| `local.hashCode == utc.hashCode` | **`true`** — equal hashes, unequal objects. |
| `DateTime(2026, 9, 9).toIso8601String()` | `2026-09-09T00:00:00.000` — no offset, and identical in every timezone. |
| `DateTime(2026, 2, 31)` | `2026-03-03`. Silent overflow, never throws. |
| `dart pub add args` | Resolves to **2.7.0**. |
| `avoid_slow_async_io` | **Not** in this book's lint set, and argues the opposite for `exists`/`stat`. |
| `implements` against study 25's concrete `Store` | `non_abstract_class_inherits_abstract_member` — the double must write `totals` too. |
| `one_member_abstracts` on a one-**method** abstract class | Fires, on `abstract class` and `abstract interface class` alike. |
| `one_member_abstracts` on a one-**getter** abstract class | **Silent.** The lint is narrower than the guideline behind it. |
| `one_member_abstracts` in this book's lint set | **Not** in it. All three shapes analyze clean until it is switched on. |
| `Money.fromPence(250) == Money.fromPence(250)` before study 27 | **`false`** — no `==`, and a factory builds a new object each call. |
| A primary constructor on a mutable class with `implements` | Legal. `class CappedStore(final int limit) implements Store { … }` analyzes clean and runs. |
| A primary constructor on a generic class | Legal. `class Slots<T>(final int capacity) { … }` analyzes clean and runs. |
| `await` inside a `switch` expression arm | Legal. Study 24's parser became `async` without changing shape. |
| `Store`'s two signatures made `Future` | **19 errors in six files**, no implementation touched. |
| `file.writeAsString` twice | **Truncates.** `one` then `two` leaves `two`; `FileMode.append` is the fix. |
| `File('missing').readAsString()` | `PathNotFoundException`, "Cannot open file", errno 2. |
| `writeAsString` into a directory that is not there | `PathNotFoundException` too — hence `file.parent.create(recursive: true)`. |
| `''.split('\n')` | `['']` — **length one**, not zero. |
| `'a\nb\n'.split('\n')` | `['a', 'b', '']` — always one empty entry too many. |
| A note with a newline, through the line format | Reads back as an ordinary expense with **half its note gone**. Silent. |

### 23 — Libraries, imports and privacy · `libraries` · `ch23_expenses` — **WRITTEN**

Shipped: 7 green, 3 challenges at 5 failing, 8 transcripts. Two things the writing found
that this entry did not predict. The barrel would not analyze clean — a `///` above an
`export` trips `dangling_library_doc_comments`, so `library;` is in the study. And
`crowded.dart` and `pence.dart` are **demonstration files, not tracker code**: study 24's
SLICE must delete them, or eleven later snapshots carry code the program never calls.

**Pays the study-19 promise**, the only debt Book I leaves unpaid. Teaches: a file is a
library; `import` with `show`, `hide` and `as`; `_` privacy; `lib/src/`; `export` and the
barrel file. `part` / `part of` is a Gloss, not a section.

Toy: `lib/src/money.dart`, holding `Money` and nothing else, behind `lib/expenses.dart`.

The mechanism to name: **privacy in Dart is a property of the library, not the class**,
and a library is a file. From outside, `Money._` is not merely inaccessible — the
analyzer says the class *does not have* a constructor by that name, because the private
member is not part of the type's outside surface at all. Inside the same file, anything
can call it: measured, an unrelated `Sneak` class constructs `Money._(-5)` and analyze
stays clean. So the reason `Money` sits alone in `lib/src/money.dart` is not tidiness.
The file **is** the boundary, and a small file is a small boundary.

Then the honest half, which is what study 19 actually asked for. A class's private
constructor cannot be reached from another library. An extension type's can be walked
past anyway, because `7 as Pence` is checked against `int` and succeeds — measured,
silently, analyze clean. Three transcripts, one argument: the promise is paid *and*
study 19's closing sentence ("nothing will ever close the cast") is proved rather than
repeated.

Seeds: every later study imports through the barrel. `lib/` against `lib/src/` returns
in study 34 as the thing a version number makes a promise about.

Practice: *Effective Dart — Usage*, "DON'T import libraries that are inside the `src`
directory of another package". **Verified** — page opened while writing study 23, anchor
`#dont-import-libraries-that-are-inside-the-src-directory-of-another-package`. The
matching lint, `implementation_imports`, is in `package:lints/recommended.yaml` 6.1.0,
which `code/analysis_options.yaml` includes, so the book enforces what it quotes.

Also verified on that page and used by ADR 0004: "PREFER relative import paths", which
is why Book II's `lib/` imports carry no package name.

Gloss: `library_private_types_in_public_api`, also enabled — a public API that mentions
a private type. And `part` / `part of`: it exists, it is mostly for generated code, and
Book IV's codegen study is where it earns a place. Nothing in this book needs it.

### 24 — A program that runs · `a-program-that-runs` · `ch24_expenses` — **WRITTEN**

Shipped: 12 green, 3 challenges at 7 failing, 7 transcripts. The first snapshot with a
predecessor, so the first real exercise of `check_slices` — it passed, and both negative
controls fired: an undeclared edit to a carried-forward `money.dart`, and an undeclared
deletion. The `<Practice>` carries no attribution: two dart.dev pages were opened looking
for a rule about exit codes and stream separation and neither has one, because that
convention belongs to the shell rather than to Dart.

Teaches `bin/`, `main(List<String> args)`, `stdout` against `stderr`, `exit` and exit
codes, and an argument parser hand-written with study 14's patterns and study 13's
records.

Toy: `bin/expenses.dart` and `lib/src/command.dart` — `expenses add 12.50 coffee` works
from a terminal.

First job, before any of that: **delete study 23's demonstration files.**
`lib/src/crowded.dart`, `lib/src/pence.dart`, `bin/inside.dart`, `bin/cast.dart` and
`bin/imports.dart` exist to make study 23's argument and are not part of the tracker.
Study 24's SLICE declares the removals, and `check_slices` fails if it does not. This is
the first snapshot with a predecessor and so the first real test of that check.

The mechanism to name: a CLI's return value is not what it prints. It is the **exit
code**, and the shell is the caller reading it. `print` goes to stdout, which is the
program's *answer*; a diagnostic goes to stderr, which is not, and the difference is
what makes `expenses list > file.txt` produce a file with no error text in it. Show it
with a real redirect in a transcript.

Pays across a book boundary: study 14's toy was `command.dart`, "parse a small command
into a record and act on it". This is that, grown until it runs.

Principle 4, named in the prose: this parser is hand-rolled and study 33 replaces it
with `package:args`. Say which parts are weak — no `--help`, no abbreviations, no
`--flag=value` — so study 33 has something specific to fix.

Practice: candidate is *dart.dev — Write command-line apps*, on exit codes and
`stderr`. **Unverified.** Open the page and confirm it says this before quoting it; if
it does not, this study's `<Practice>` omits both props the way study 2's does.

Gloss: `dart run` compiles to a kernel snapshot each time; `dart compile exe` is what
you ship. Named now, met in study 34. *Unverified — measure the two before writing.*

### 25 — Values and entities · `values-and-entities` · `ch25_expenses` — **WRITTEN**

Shipped: 27 green, 3 challenges at 8 failing, 8 transcripts. The outline's planned
`<Practice>` was wrong — study 15 already cites *DO override `hashCode` if you override
`==`*, so this study cites *AVOID defining custom equality for mutable classes* instead,
which is the value/entity lesson rather than a repeat. A book-wide duplicate-citation
check now runs with the other audits.

Teaches `Category` and `Expense`; normalising on construction; `operator ==` and
`hashCode`; immutability, `final` fields and unmodifiable collection views; and the
difference between a value and an entity.

Toy: `lib/src/category.dart` and `lib/src/expense.dart`. A `Map<Category, Money>` of
totals is what forces the issue.

The mechanism to name: **`hashCode` picks the bucket and `==` searches it**, so a type
that overrides one and not the other lands in the right bucket and fails to be found —
or worse, is found twice. Show the failing lookup before the fix. Then the sharper half,
already measured and a gift to this study: for one instant, `local == utc` is `false`
while `local.hashCode == utc.hashCode` is `true`. Equal hash codes do not mean equal
objects, and a test that only compares hash codes proves nothing. That is
`OUTLINE.md`'s "beware the claim a passing test appears to support" in a new shape,
found in `dart:core` rather than invented.

`Money` and `Category` are **values** — no identity, two of them with the same contents
are the same thing. `Expense` is an **entity** — two coffees for the same amount on the
same day are two expenses. That is the distinction the study exists to draw, and it is
why `Expense` does not get value equality.

Seeds: `Category` as a `Map` key is what study 31's grouping depends on.

Practice: `hash_and_equals`. Verified present in `package:lints/core.yaml` 6.1.0.

Gloss: `Day` arrives here as `Expense`'s date because a `DateTime` cannot be trusted in
a domain — the four measurements are in study 30, and this Gloss forward-references
them rather than restating them.

### 26 — Errors: thrown or returned · `errors-by-design` · `ch26_expenses` — **WRITTEN**

Shipped: 34 green, 3 challenges at 6 failing, 8 transcripts. Two things measured that the
entry did not predict. A `sealed` base needs its own `const` constructor
(`sealed class const Reading();`) or every `const` subclass fails — found on the first
attempt. And study 10's Gloss is weaker than it sounds: **`dart run` does not enable
asserts either**, nor does a `dart compile exe` binary. Asserts fire under `dart test` and
under `dart run --enable-asserts`, and nowhere else, which is the study's sharpest
transcript.

Teaches the design decision study 20 left open: which failures throw and which are
returned as data. `ArgumentError` against a domain result type, `Object?`-free error
values, and where validation lives.

Toy: `lib/src/parse.dart` — turning `"12.50"` typed at a terminal into a `Money`.

The mechanism to name: **`assert` is stripped from release builds** — study 10's Gloss,
now load-bearing. An `assert` guards against the programmer's own mistake and nothing
else. A number a person typed is a fact about the world arriving at run time, so
`Money.fromPence` throws and does not assert. This is also why `Money` keeps its primary
constructor and validates in a **factory**: measured, a generative constructor cannot
sit beside a primary one, but a factory can, and a factory has a body to check in. ADR
0002 is amended with this.

Then the choice itself: a malformed amount is expected, so it is returned as a value the
caller must look at. A negative `Money` is a bug, so it throws. Name the rule — *expected
failures are data, bugs are exceptions* — and apply it out loud for the rest of Book II.

Pays: study 20 taught the machinery of throwing; this is the study that decides when to.

Practice: **the planned `empty_catches` citation was a duplicate** — study 20 already
cites it, along with `use_rethrow_when_possible` and `control_flow_in_finally`, under
*dart.dev — Error handling*. Study 26 cites *Effective Dart — Usage*, "DO throw objects
that implement `Error` only for programmatic errors", with its companion "DON'T explicitly
catch `Error` or types that implement it". Verified on the live page. That pair is the
rule that decides whether to reach for study 20's machinery at all, and it changed the
code: `readMoney` checks the sign itself rather than catching `Money.fromPence`'s
`ArgumentError`, and `lib/` now contains no `catch` at all.

Gloss: `Error` against `Exception` in `dart:core`, and why `ArgumentError` is an `Error`.

### 27 — Testing without mocks · `testing-without-mocks` · `ch27_expenses` — **WRITTEN**

Teaches seams: an interface you own, an extension for what is derived from it, an
in-memory fake, injection by parameter, `setUp`, and why `package:mockito` is not needed
here.

Toy: `lib/src/store.dart` becomes `abstract interface class Store`; `InMemoryStore`
implements it; `totals` leaves the interface and becomes an extension; `run` takes a
`Day today`.

First job, done: study 26's `lib/src/asserting.dart` and `bin/asserting.dart` are gone,
and `test/reading_test.dart` dropped its import and its two assert tests. The `SLICE`
names all three.

The mechanism to name: a fake is not a lesser mock. A **mock records calls**, so the test
is coupled to how the code works; a **fake implements behaviour**, so the test is coupled
only to what it does. `test/store_test.dart` ships both, and the mock's blindness is a
passing assertion rather than a claim: it sees `record` happen, and then `list` through
the same mock answers `nothing recorded yet`.

Principle 4 settled, and measured rather than asserted: study 25's concrete `Store` could
not be doubled at all without writing out `totals`. `bin/faking.dart`, captured from a
temporary state of `ch25_expenses` and then deleted, is the Drill's first transcript —
`non_abstract_class_inherits_abstract_member`, *"Missing concrete implementation of
'getter Store.totals'"*. That is the cost Effective Dart names, on this book's own code.

**The `Clock` the outline planned does not exist, and its absence is the study's second
half.** A `Clock` interface, a `SystemClock` and a `FixedClock` are three types where a
parameter does the job, and study 27's own Principle-4 paragraph would have condemned
them two sections later. `run(args, store, today)` is the seam. The prose says so out
loud and cites the guideline that decides it.

Seeds: `today` as a parameter is what makes study 30's date tests deterministic, and
`InMemoryStore` is what studies 28–32 test against instead of a disk. Study 31 is
promised `totals` — the Gloss says the extension is a holding position and a `Report` is
where it ends up.

Practice: **the planned citation did not exist.** *Effective Dart — Design* has no rule
about "narrow interfaces". It has three that decide this study instead, all verified on
the live page and none previously cited by this book: **AVOID implementing a class that
isn't intended to be an interface** (the Drill), **DO use class modifiers to control if
your class can be an interface** (`abstract interface class`), and **AVOID defining a
one-member abstract class when a simple function will do** (no `Clock`).

Gloss 1: `package:mockito`, what it generates, that it needs `build_runner`, and the
three cases where it is the right tool — a large interface, a type you did not write, or
a test whose subject really is *how* a call was made. None applies here.

Gloss 2: where `totals` ends up — study 31's `Report`. The extension is what makes that
move cheap, because nothing implements it.

Found while writing, and fixed in place: **`Money` had no `operator ==`.** It is the
book's flagship value type and study 25's own 25.3 states the rule that decides it —
identical contents, one thing or two. `Money.fromPence(250) == Money.fromPence(250)` was
`false`, and the first line in the book to compare two of them was study 27's
`expect(store.totals, {…})`, which failed with `<Instance of 'Money'> instead of
<Instance of 'Money'>`. Fixed in `ch25_expenses` and carried forward; 25.3 gained a
paragraph and the `money` region; `ch25_expenses/SLICE` gained `lib/src/money.dart`.

Also fixed: the barrel doc comment said **"Five exports now"** over six exports in
`ch25_expenses` and seven in `ch26_expenses`, and both were on the page.

Found by the audit pass after it shipped, and all of it prose or tooling rather than
design:

- **Two of Book I's transcripts had been false since `efa9fb6`**, and this study's own
  `Money` fix falsified three more. `tool/check_transcripts.dart` now re-runs every green
  `dart test` transcript and every "Three challenges, N failing tests" sentence. It is
  proved against injected drift in both directions.
- **Three stubs used the pre-3.13 constructor form**, two of them written this session and
  one in study 18's challenges since Book I. Measured: the header form is legal on a
  mutable class with `implements` and on a generic one, so nothing justified the older
  spelling. ADR 0002 is amended and the sweep is one grep.
- **Two shown regions used a name declared outside every region** — `day` in
  `store_test.dart` and `late Store store` in `command_test.dart`. This is the inverse-orphan
  defect the standing requirements describe and no tool can see. Both declarations moved
  inside. A sweep of all five Book II packages found no others.
- **The `one_member` transcript named lines in a file the reader never saw**, and the
  `faking.dart` block started at the class while the error said line 4. Both files are now
  inlined whole, so the line numbers in the errors point at code on the page.
- **"async returns after eleven studies away" is five**, and ADR 0003 said it in a sentence
  that named all five. Measured: `grep -rl 'async\|await'` over 23–27 returns nothing.
- **Three more counts were written from an impression**: `Store.totals` "four lines" is ten,
  and `bin/expenses.dart` "nine lines" is eight, repeated on two pages. Both are now stated
  as *four statements* or not at all. A standing requirement records the sweep.
- Challenge 1 lost its `ArgumentError` requirement with the constructor change, so the
  count is **nine failing tests**, not ten.

### 28 — Files · `files` · `ch28_expenses` — **WRITTEN**

Teaches `dart:io`: `File`, `readAsString`, `writeAsString`, `FileMode.append`, `exists`,
`Directory.systemTemp.createTemp`, `tearDown`, and `async`/`await` returning after five
studies away.

Toy: `lib/src/file_store.dart` — a second `Store` implementation, one expense per line.

**The hinge the outline did not settle: `Store` was a synchronous interface, and a file
cannot honour one.** That is the study, and almost none of it is the file. `void
record(Expense)` promises the expense is kept by the time the call returns; `List<Expense>
get all` promises the list is already in hand. Both become `Future`, and the argument for
doing it in the *interface* rather than reaching for `readAsStringSync` in the
implementation is that `Store` is a promise every implementation must keep — Book III puts
a server behind this same type, and a promise only a CLI can keep should not have been
made in a CLI.

Measured, and it is the Drill: changing those two lines and nothing else gives **19 errors
across six files** — four in `store.dart` itself, where the `totals` extension still treated
`all` as a list, and fifteen in five files that have never heard of a disk. `async` travels up the call stack
and cannot be hidden. The transcript was captured from a temporary state of
`ch27_expenses` and reverted.

Also measured, because none of it was obvious: `await` is legal inside a `switch`
expression arm, so study 24's parser became asynchronous without changing shape.
`writeAsString` **truncates** by default, which would have kept only the last expense ever
recorded. Writing into a directory that does not exist throws `PathNotFoundException`, so
`record` calls `file.parent.create(recursive: true)`. And `''.split('\n')` has length
**one**, not zero.

Principle 4, named in the prose and asserted in tests: the format breaks on two characters
and breaks differently. A **comma** makes five fields, the list pattern does not match, and
the expense is gone — loud. A **newline** splits one expense across two lines, and the
first four fields still line up, so it reads back as an ordinary expense with half its note
missing and nothing anywhere saying so. **This study first assumed the newline case lost
the expense too; the test measured otherwise and the prose was corrected.** Silent
corruption is the better argument for study 29, and 28.5 also says why widening the pattern
is not a fix — it repairs the comma only because the note happens to be last, and does
nothing for the newline, which `split` did before the pattern ever saw it.

Practice: **the outline was wrong to say there is none.** There is no citable guideline for
"prefer async I/O" — that part holds — but the study's actual decision was about a *return
type*, and Effective Dart covers it exactly: **DO use `Future<void>` as the return type of
asynchronous members that do not produce values**, whose own wording is *"that the caller
might need to await"*. Its companion **AVOID using `FutureOr<T>` as a return type** closes
the shortcut a reader will reach for — `FutureOr<void> record` would let `InMemoryStore`
off the hook and leave every caller unable to tell whether awaiting is required. Both
verified on the live page, neither cited before.

Gloss 1: `avoid_slow_async_io` exists, is not in this book's lint set, and argues the
opposite for `exists` and `stat`. Named so a reader who enables it later recognises the
complaint.

Gloss 2: `all` re-reads the file on every call and `_list` asks twice. Fine for a CLI that
runs one command and exits, not fine for the Book III server, and a cache is a second thing
to be wrong about.

**`check_regions` gained a recorded exemption, because this study broke its rule honestly.**
Five regions changed by nothing but `async` and `await` — the same mocks, the same
assertions, one keyword heavier — and re-showing them would suggest something new about
mocks. A SLICE may now carry `# unshown: <path>#<region> — <reason>` lines, and **the
reason is required**: a line without one is reported as a problem, so every exemption is a
sentence a person wrote and a reviewer can disagree with. Proved by adding a reasonless
line and watching it fail. 55 regions changed, 50 shown, 5 exempted.

Also: `.gitignore` gained `code/ch*/expenses.txt`, because running the study's own program
from its package writes one.

### 29 — JSON · `json` · `ch29_expenses`

Teaches `dart:convert`: `jsonEncode`, `jsonDecode`, `toJson` and `fromJson` by hand,
`Map<String, dynamic>` at the boundary, and round-trip tests.

Toy: `file_store.dart` rewritten to write JSON, and the note with a comma in it that
made study 28's format fail.

The mechanism to name: `jsonDecode` returns `dynamic`, which is the one place this book
lets a type go. Everything the analyzer knew is gone at that line, so the conversion
back into `Expense` is where the checking has to happen — which makes `fromJson` a
parser, and study 26's rule applies to it unchanged.

Then the measured trap, and it is the reason `Day` exists: a local `DateTime`
serialises as `2026-09-09T00:00:00.000` with **no offset**, and that string is byte-identical
whether the program runs in Tashkent, London or New York. The file looks fine. The
instant it means is different. A `Day` has no such hole because it never claimed to be
an instant.

Seeds: this file format is what study 35's API reads.

Practice: candidate is *dart.dev — JSON serialization*, on hand-written `fromJson`
against generated code. **Unverified** — open it, and note whether it recommends
`json_serializable`, which this book defers to Book IV with the rest of codegen.

Gloss: `jsonEncode` calls `toJson()` if your object has one, and throws if it does not.
*Unverified — run the failure and capture its message.*

### 30 — Dates, times and periods · `dates-and-times` · `ch30_expenses`

Teaches `DateTime`, `Duration`, `isUtc`, `toUtc`/`toLocal`, `isAtSameMomentAs`,
`DateTime.parse`, and the `Day` and `Period` value types the domain actually uses.

Toy: `lib/src/period.dart` — the calendar month a report covers.

The mechanism to name: **a `DateTime` is an instant; a calendar day is not.** All four
of these were measured and every one is a trap the reader will otherwise meet in
production:

- `local.microsecondsSinceEpoch == utc.microsecondsSinceEpoch` is `true`, and yet
  `local == utc` is `false`. `DateTime.==` is not instant equality;
  `isAtSameMomentAs` is.
- `local.hashCode == utc.hashCode` is `true` while `==` is `false`. Study 25 already
  used this; here is where it is explained.
- `toIso8601String()` on a local `DateTime` emits no offset at all.
- `DateTime(2026, 2, 31)` is the 3rd of March. Month arithmetic overflows silently and
  never throws, so there is no error to catch.

Which is the argument for `Day`: the 9th of September is the same day everywhere, an
expense happens on a day, and a type that cannot represent a timezone cannot get one
wrong. Instants live at the edges — `bin/expenses.dart` reads one and `Day.on` converts
it, and study 27 is where that stopped happening in the middle of the work. There is no
`Clock` interface to name; the seam is a `Day today` parameter.

Seeds: `Period` is what study 32's budget is scoped to.

Practice: candidate is *dart.dev — Date and time* or *Effective Dart — Design* on
narrow types. **Unverified, and likely neither says what this study needs.** If no
published guideline covers "do not put an instant where a date belongs", the
`<Practice>` states it as this book's own convention and carries no props.

Gloss: DST is deliberately not demonstrated. A transcript of it would depend on the
machine's timezone, and this book's transcripts must reproduce on the reader's. Name the
hazard, cite `package:timezone` as where the answer lives, and do not fake a run.

### 31 — Reports · `reports` · `ch31_expenses`

Teaches grouping with `fold` into a `Map`, `Comparable` and `compareTo`, `sort` with and
without a comparator, and `operator +` and `operator -` on `Money`.

Toy: `lib/src/report.dart` — total by category for a period.

The mechanism to name: this is study 12's `fold` with a `Category` key, and it only
works because study 25 gave `Category` an `==` and a `hashCode` that agree. Show the
same report against a `Category` with a broken `hashCode` and watch one category become
two rows. That is the payoff for study 25, made visible.

Then operators, which the book has been using without admitting to: study 25 already
overrode `operator ==`. `Money + Money` is the same machinery with a different symbol,
and it is what totalling wants. `Money - Money` is the interesting one — it can take an
amount below zero, which `Money` forbids, so subtraction is a **partial operation** and
has to say so. That is a real design lesson, not a syntax tour.

Amends `OUTLINE.md`: operator overloading was listed as Book IV. It is here.

Practice: `prefer_for_elements_to_map_fromIterable` — building a `Map` from an
iterable with a collection-`for` rather than `Map.fromIterable`. Verified present in
`package:lints/recommended.yaml` 6.1.0, and it is exactly the grouping this study
writes.

Gloss: `Comparable<T>` is what `sort` uses when you give it no comparator, and
implementing it is a promise about a *total* order. Two expenses on the same day are not
equal just because `compareTo` returns 0.

### 32 — Budgets · `budgets` · `ch32_expenses`

Teaches an invariant that no single object can check: a `Budget` holding a limit and the
expenses counted against it, and the difference between a rule and a warning.

Toy: `lib/src/budget.dart` — `expenses budget food 200.00`, and an `add` that is refused.

The mechanism to name: every invariant so far belonged to one object. `Money` checks
itself; `Category` normalises itself. **A budget's limit cannot be checked by an
expense, by a category, or by a limit** — it needs all the expenses in one category and
one period at once. That cluster is the unit the rule lives on, and holding it together
is the only reason the type exists. Name the idea (a consistency boundary) once, in one
sentence, and then spend the study on the mechanism rather than the vocabulary.

The honest complication, which the study must not dodge: software that refuses to record
what a person actually spent is lying about their money. So an acknowledged overspend is
a different thing from an ordinary expense and is representable; only the
*unacknowledged* breach is refused. The invariant survives and the program stays true.

Pays: study 26's rule, spent on a business failure rather than a parse failure — a
refusal is expected, so it is returned as data.

Seeds: `Store.record` becomes fallible here, after eight studies of being infallible.
The `SLICE` manifest makes that change visible rather than silent.

Practice: **no attribution.** No published guideline covers where an invariant that
spans several objects should live, so this states the book's own convention — *the rule
goes on the smallest thing that can see all of it* — and omits both props, as study 2
does. Do not attribute it to Effective Dart.

Gloss: what Book II does **not** take from this — commands and queries as separate
handlers, transaction boundaries, units of work. They answer concurrency, and a
single-user CLI writing one file has none. Book III is where that argument gets made,
with a real concurrent writer on the page.

### 33 — Taking a dependency · `taking-a-dependency` · `ch33_expenses`

Teaches `dart pub add`, `pubspec.yaml` dependencies, caret constraints, the lockfile,
`dart pub outdated`, and `package:args` **2.7.0** replacing study 24's parser.

Toy: `bin/expenses.dart` rewritten on `ArgParser` and `ArgRunner`; `--help` for free.

The mechanism to name: `^2.7.0` means "at least 2.7.0 and less than 3.0.0", and it is a
bet on someone else's discipline — that they will not break you before the major bump.
The lockfile is what makes the bet reproducible: the constraint says what you *allow*,
the lock says what you *got*. Show `pubspec.lock` in the study and say which one a
teammate's machine reads.

Pays: study 24's named weaknesses, one at a time — `--help`, abbreviations,
`--flag=value`. The comparison is the study, so transclude study 24's parser beside the
new one the way study 12 transcludes study 10's loop.

*Unverified: every claim about `ArgParser`'s API. `args` 2.7.0 is the resolved version —
verify each call against the installed package, not from memory, and note that Context7
has no Dart `args` entry.*

Practice: `depend_on_referenced_packages` — every package you `import` must be in
your `pubspec.yaml`, not merely reachable through someone else's. Verified present in
`package:lints/core.yaml` 6.1.0. It is the lint that makes a dependency a declaration
rather than an accident.

Gloss: `dart pub add --dev` and why `test` and `lints` are dev dependencies — they are
not part of what your callers get.

### 34 — Being a dependency · `being-a-dependency` · `ch34_expenses`

Closes Book II. Teaches doc comments and `///`, `dart doc`, `dart pub publish --dry-run`,
semantic versioning as a promise, `analysis_options.yaml` as policy, and
`dart compile exe`.

Toy: `lib/expenses.dart`, the barrel from study 23, read back as a public API.

The mechanism to name: study 23's `lib/` against `lib/src/` was a privacy mechanism.
Here it is a **contract**: everything the barrel exports is what a version number
promises about, and everything in `lib/src/` is yours to change. A major version bump is
the sentence "I broke something you were using", and `lib/src/` is how you make that
sentence rare. `dart pub publish --dry-run` reads your package back to you and is the
closest thing to a machine checking the promise.

Then lints as policy: `analysis_options.yaml` is a set of errors you chose to opt into,
enforced at compile time by the same analyzer that enforces the language. Show one lint
being enabled and a file that was clean becoming not clean.

Closes the arc: 33 is what a caret constraint promises *you*, 34 is what it promises
*your callers*.

*Unverified: `dart pub publish --dry-run` output on a `publish_to: none` package. Run it
before writing the transcript — it may refuse, which would itself be the transcript.*

Practice: `slash_for_doc_comments` — `///` and not `/** */`. Verified present in
`package:lints/recommended.yaml` 6.1.0, and apt here because this is the study where doc
comments stop being decoration and become the thing `dart doc` publishes.

Gloss: `dart compile exe` produces a native binary with no Dart on the target machine,
paying study 24's Gloss.

### Promises Book II makes to itself

Every forward reference in the *written* prose, checked against it rather than against
intention. Two kinds of defect live here and both have been found: a promise the prose
makes and this table does not record, and a row recording a promise the prose never made.
Book I's table had the second kind once; this one had three.

Navigation lines — "Study 25 gives the program something to record" at the end of a
Wrapping up — are not promises and are not listed. A promise names something the reader is
told will be explained or fixed.

| Owed by | Made in | The reader is promised |
| --- | --- | --- |
| 31 | 27 | `totals` is a holding position and becomes a `Report` |
| 29 | 28 | a comma loses the expense and a newline corrupts it silently |
| 33 | 28 | which file the tracker keeps becomes something you can say |
| 30 | 25 | why `Expense` carries a `Day` and not a `DateTime` |
| 33 | 24 | a parser with `--help`, abbreviations and `--flag=value` |

Paid: 26←24 (`null` could not say which part was wrong; a sealed `Reading` can),
26←24 again (`dart compile exe` named in a Gloss, measured in 26.4), 27←24 (the seam
behind `Outcome` is named and two more are cut), 27←25 (`Store` is an interface now that
a second implementation exists), 27←26 (both lines study 26 left alone became
parameters), 28←25 (the store stops forgetting when the program stops).

Removed as fiction, found by checking the prose rather than the plan: **31←25** — the
outline meant study 25 to promise study 31 that `Category`'s equality is what makes
grouping work, and the written study never names study 31. **34←23** and **34←24** —
neither study's prose mentions study 34 at all. A table that records promises nobody made
cannot cost a reorder, which is the only reason it exists.

## Working in a fresh worktree

`.dart_tool/` and `node_modules/` are gitignored, so a new worktree has neither.
Run both before believing any output:

```bash
cd code && dart pub get && cd ../web && npm install
```

Skipping the first makes `dart analyze` report ~61 phantom errors about
unresolved `package:` imports. It looks like the book is broken. It is not.

## The transcript convention

The handoff says this is written down nowhere. It is now. Derived from the
existing transcripts and verified to reproduce.

- **Line 1 is the command, written by hand**, prefixed `$ ` — `dart` never
  prints it. Everything after line 1 is real captured output.
- **Passing runs are cut to the final status line.** `all.txt` is two lines: the
  command and `00:00 +10: All tests passed!`. The per-test progress lines are
  dropped.
- **Failing runs keep the narrative** — the loading line, the failure, the
  error text with its caret — and are **cut off mid-stream** once the point is
  made. `challenges.txt` stops after two of six failures on purpose; six would
  be repetition, not evidence.
- **Stack-frame lines are removed.** `dart test` prints frames under a failure
  (`  exercises/challenges.dart 10:3       slugTag`) and none of the committed
  transcripts contain them. Verified: re-run study 3's exercises today and the
  frames appear, so they were trimmed by hand. Drop the frame lines and the
  blank lines around them; keep everything else contiguous.
- **Deliberately-broken examples are captured by breaking the source, running,
  and reverting.** `const-runtime.txt` shows two errors at `timing.dart:17:19`
  from a `const startedAt = DateTime.now();` that is not in the shipped file.
  Verified: append that line back and the transcript reproduces byte for byte,
  same line, same column. So a re-capture means restoring the break at the same
  line number, not editing the text.
- **Book II adds cross-study includes.** A study may transclude an earlier study's
  file to set the old version beside the new one — study 12 already does this with
  `ch10_ledger/lib/ledger.dart`, and ADR 0001 calls it the good kind of coupling,
  because moving either study breaks a build. Use it where the *change* is the
  lesson (studies 29 and 33 both replace something named in an earlier study), not
  as a default. Snapshots make this safe: the earlier file can never move.
- **File names by role**: `undefined.txt` (red, nothing exists yet), `pass.txt`
  (first green), `all.txt` (the study's full suite), `challenges.txt` (the
  deliberately-failing exercises). Topical ones are named for what they show —
  `const-runtime.txt`, `generated.txt`, `hello.txt`.

## Standing requirements for every study

- Prose in `web/content/docs/<book>/<slug>.mdx` — `foundations/` for Book I,
  `writing-good-dart/` for Book II; code in a real package at
  `code/chNN_<name>/` that `dart analyze` and `dart test` actually run.
- Frontmatter carries `title`, `study`, `direction`, `description`. `PressHead`
  and `Prescription` render the number and the direction from frontmatter — the
  MDX body never writes the study title or the direction itself.
- Components come from `web/src/components/press.tsx`, registered in `mdx.tsx`:
  `Drill`, `Direction`, `Gloss`, `Practice`, `Console`.
- Includes:
  `<include cwd lang="dart" meta='title="lib/x.dart"'>../code/chNN_*/…</include>`,
  with `#region` markers for partial files. Terminal output is
  `lang="saff-console"` inside `<Console>` — never `lang="bash"`, which picks the
  wrong grammar and palette. Prose-level shell commands the reader types are
  plain fenced ```bash.
- Transcripts are captured from real runs into `code/chNN_*/transcripts/*.txt`.
  Never hand-written.
- Sections are numbered `## N.1`, `## N.2`, …, then `## Wrapping up`, then
  `## Challenges` — three already-failing tests in `exercises/`. Study 1 is the
  exception on all three counts: unnumbered sections, no package tests and no
  challenges, because the reader has not met `test()` yet. Every study from 2
  onward has all of them.
- `Wrapping up` closes with an `Also met:` line — that exact wording, in every
  study from 2 onward.
- Add the slug to that book's `meta.json`, and the book to
  `web/content/docs/meta.json`. A study that is not
  listed there does not appear in the rail, and nothing warns you.
- The unit is a **study**. `chapter` survives in `PRODUCT.md`, the `chNN_`
  directory prefix and two `pubspec.yaml` descriptions; prose, frontmatter and
  anything the reader can see say *study*.
- **Every factual claim in the prose must be an assertion in a test.** Not a
  guideline — the rule that catches the errors this book is most likely to make.
  Audit of studies 4-9 found four false claims, and all four were sentences
  written from knowledge rather than from a run: sets comparing by contents,
  insertion order being a language guarantee, `int?` and `int` compiling
  identically, and `List.filled`'s error message. Nothing that had been executed
  was wrong. If a sentence states behaviour, `expect` it somewhere.
- Beware the claim a passing test appears to support. `expect({'a','b'},
  {'b','a'})` passes, and it does **not** mean `==` is true — the matcher
  compares contents and ignores order for a set. A green test is evidence about
  the matcher, not about the language.
- **No orphan `#region`.** A region marker with no `<include>` pointing at it is
  either dead weight or, more often, a gap: seven were found in studies 2-7 and
  every one turned out to be a definition the reader met by name and was never
  shown — `standardPrices` used in a test, `hashPrefix` used in `tag`, the
  four-language `enum` when only the three-language stage was on the page. Check
  with: for each `// #region X` in `code/`, some MDX must include that path`#X`.
- **No unshown definition — the inverse of the rule above, and `check_regions`
  cannot see it.** `dart run tool/check_shown.dart` can, and does. A helper
  declared *outside* every region, in a file whose
  regions are on the page, is invisible to the orphan check and is exactly the
  same gap: study 20 shipped a `#trace` region calling `traceOf(…)` with
  `traceOf` declared above `main()` and never shown. Check with: for each shown
  region, every name it calls must be declared either inside a shown region, in
  `dart:core`, or in a package the reader has been told about.

  It kept happening after that, twice in two studies — study 27 shipped `day` and
  `late Store store` outside the regions that used them, study 28 did the same with
  `directory`, `file` and `expenseOf` — so it is a tool now, and the tool found four
  more in Book I that had never been noticed: `const day` above the regions in both
  `ch10_ledger` and `ch12_report`, `const statement` in `ch16_entries`, and worst,
  `const decomposed = 'café'` in `ch05_label`, where the fixture *is* the lesson —
  study 5 asks the reader to read `widths(decomposed)` and never shows that the
  string is a decomposed `é`. All four fixed by moving the declaration into the
  first region that uses it, or by giving it a region of its own.

  The tool discounts comments, string literals and member accesses before a name
  counts as used; each of the three was added because leaving it out invented a
  problem. It is a heuristic and not a parser, so it errs towards silence.
- **A count in prose is a claim, and none of the counts in this book were counted.**
  Four were wrong and every one was written from an impression: `Store.totals` called
  "four lines" is ten; `bin/expenses.dart` called "nine lines" is eight lines of code and
  fourteen as rendered, and study 25 repeated the number without checking it; the barrel's
  "Five exports now" stood over six and then seven; `async` returning "after eleven
  studies away" is five, in a sentence that names all five. Sweep with
  `grep -rnoE "\b(one|two|…|twelve) (lines?|exports?|studies|types?|members?)\b"` over
  `web/content/docs/`, and prefer a count that cannot rot — *four statements* over *nine
  lines*, or no number at all where the number was never the point.
- **Inline code in prose drifts; transcluded code cannot.** Backtick fragments
  that quote real source are outside the include machinery and nothing checks
  them. Study 20's prose quoted `value == null || value < 0 ? noAmount(typed)
  : value` for two commits after that line was rewritten. Either transclude the
  line or quote it in a form too small to go stale.
- **`dart format` must be clean across `code/`**, because study 1 tells the
  reader to format on save and two included files had drifted.
  `dart format --output=none --set-exit-if-changed .` is the check.
- **The challenge intro states a count, so the count is a claim.** Where a study
  opens its Challenges with "Three challenges, N failing tests", N must equal the
  `-N` on the last line of `dart test exercises/` in that study's package.
  `dart run tool/check_transcripts.dart` now enforces this; all 22 were correct
  when it was first run. Studies 15-18 deliberately state no count and describe
  the shape of the challenge instead — a study that states no number cannot have
  a stale one, and this requirement previously claimed a uniformity the book does
  not have. Studies 2-14 spent the whole of Book I saying "three tests"
  when the real number was four to seven, which is the smallest possible
  version of this book's central failure — a sentence written from an
  expectation rather than from a run. Re-run the count whenever a challenge
  test is added.
- One `<Practice>` per study. When it carries an attribution it must be a real
  link the writer has opened: `<Practice source="Effective Dart — Usage"
  href="https://dart.dev/…">`. The candidate rules named above are starting
  points, not citations. A Practice with no citable source omits both props
  rather than inventing one — study 2 does exactly that.
- **Book II only — every file is a snapshot.** Studies 23-34 each ship the whole
  expense tracker as it stands at the end of that study, in `code/chNN_expenses/`.
  A package is written once and never edited again, which is what keeps its
  includes and its transcripts true. ADR 0004 has the reasoning.
- **Book II only — imports inside `lib/` are relative, never `package:`.** A
  snapshot's package name carries its study number, so a `package:` import inside
  `lib/` would change every file in every study and defeat the drift check.
  `bin/` and `test/` must use `package:` and differ by that one line; the check
  normalises it. Verified: `always_use_package_imports` is not in this book's lint
  set, so relative imports inside your own `lib/` are clean here.
- **Book II only — every package carries a `SLICE` file** naming the files that
  study adds or changes. `dart run tool/check_slices.dart` asserts that every file
  not named there is identical to the previous study's copy, and that every file
  named there genuinely differs. A stale manifest fails as loudly as a stray edit,
  for the same reason a wrong challenge count does.
- **Book II only — the orphan-`#region` rule is by region, not by file.** A snapshot
  carries every earlier study's regions, so every one of them would read as an orphan in
  every later package — dozens by study 34, and a check that cries wolf is a check nobody
  runs. Scoping by `SLICE` is not enough either: study 25 changed `run` inside
  `command.dart` and left `codes`, `outcome` and `parse` alone, and only the first needed
  showing again. The rule is therefore: **a region must be on a page if it is new in this
  study, or if its text differs from the previous study's copy.**
  `dart run tool/check_regions.dart` enforces it and normalises the package name first.
  It found the file-scoped version's four true misses in study 25 and cleared its three
  false alarms. **Study 28 earned it an escape hatch**, because a study can change a region
  honestly and mechanically: five of its regions gained `async` and `await` and nothing
  else, and re-showing them would suggest something new about mocks. A SLICE may carry
  `# unshown: <path>#<region> — <reason>` lines, and the reason is required — a line without
  one is reported as a problem. An exemption is therefore always a sentence a person wrote,
  never a silent skip.
- **A transcript is captured once and can be falsified by any later commit, and
  nothing was watching.** `check_slices` skips `transcripts/` on purpose, because a
  transcript legitimately differs whenever the suite grows; `check_regions` and
  `check_promises` never look at one. So the audit at `efa9fb6` — the pass that added
  tests to `ch07_basket` and `ch08_tally` so two unasserted claims would be executed —
  left both packages' `all.txt` saying `+12` over a suite of 13, on published pages,
  for every commit since. Its own message records "90 tests pass": it counted the
  workspace and not the transcripts. `dart run tool/check_transcripts.dart` re-runs
  every `dart test` transcript that claims **All tests passed** and compares the count.
  It cannot check a transcript of a *failure* — those are captured from a temporary
  broken state that no longer exists, which is what these requirements ask for — nor a
  truncated one, so it reports how many it skipped rather than implying coverage it
  does not have.
- **The promise table is checked, not trusted.** `dart run tool/check_promises.dart`
  asserts that every row corresponds to a study whose page really does name the study it
  is said to promise. Three rows failed on first run, two of them naming a study neither
  page mentions at all — the table had been written from the outline's intention rather
  than from the prose. It also lists forward references the table omits, for a person to
  triage: a Wrapping up saying "Study 25 gives the program something to record" is
  navigation, not a promise.
- **A demonstration file is not part of the package.** Study 26 exported
  `lib/src/asserting.dart` from the barrel, which told every reader that `half` is
  something this package supports — contradicting study 23, whose whole lesson is that the
  barrel is a deliberate offer. Teaching files stay out of the barrel and are reached
  through `lib/src/` directly, which is legal inside one package.
- **A transcript must carry no absolute path.** A `Failed assertion` raised from `bin/`
  prints a `file:///Users/…` URI naming the author's machine, which no reader can
  reproduce. The same assert raised from `lib/` prints `package:chNN_name/…`, which
  everyone can. Book I's only assertion transcript (`ch10_ledger`) is the package form,
  and study 26 had to move `half` out of `bin/` and into `lib/` to match it. Grep new
  transcripts for `/Users/` before committing.
- **The `<Practice>` a study plans is not the one it should cite.** Twice now the outline
  named a guideline an earlier study had already used — study 15's `hashCode` rule for
  study 25, study 20's `empty_catches` for study 26. Before writing a Practice, grep every
  `.mdx` for the candidate `href`. A duplicate citation is a study that found nothing new.
- **`int.tryParse` is more generous than the sentence you are about to write.** It reads
  `0x10` as 16 and accepts a sign wherever it is handed one. The studies 19-22 audit found
  this in study 20's shipped parser; study 24 shipped it again, and `penceFrom('5.-1')`
  answered 499 — £4.99 recorded for input that means nothing, with nothing thrown and
  nothing warned. Check the characters before parsing them, and make the check an
  assertion. The same applies to any type that claims to be a real-world value: study 25's
  `Day` accepted the 31st of February until it was measured.
- **A value type with no `==` fails silently, and keeps failing until something
  compares two of them.** `Money` went four studies without one. Nothing warned:
  `hash_and_equals` fires when you override one half, not when you override neither, and
  every test until study 27 compared `.asText` or `.pence` instead. The first line to
  compare two `Money` objects failed with `<Instance of 'Money'> instead of <Instance of
  'Money'>`, which names nothing. Study 25 states the test — *identical contents, one
  thing or two?* — so apply it to every type the moment it exists, not the moment a map
  needs it.
- **Book II only — the domain never holds a `DateTime`.** Measured: for one
  instant `local == utc` is `false` while their hash codes are equal,
  `toIso8601String()` drops the offset, and `DateTime(2026, 2, 31)` is the 3rd of
  March. `Expense` carries a `Day`. Instants live at the edges only.
- Deliberately-broken code that fails to **compile** cannot live in `lib/`: it
  would put the workspace analyze above zero and contradict study 1's Practice.
  Capture its transcript from a temporary state and inline the code in the MDX
  (study 8 does this). Code that fails at **run time** may stay as a real file
  (study 7's `bin/frozen.dart`, study 9's `bin/bang.dart`), which is better —
  the transcript stays reproducible by just running it.
