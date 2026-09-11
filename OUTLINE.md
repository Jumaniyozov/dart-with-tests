# Outline

Book I: Foundations (studies 1–22) — written. Book II: Writing good Dart
(studies 23–34) — written. Book III: Build the API (35–40) — outlined below, with
provisional titles. Book IV (41–45) has no outline.

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
and 21→22 (the same verbs and the same waiting, over many values), 19→23
(*"Study 23 will show how to hide a constructor"* — `extension-types.mdx` makes
that promise in as many words, and the paragraph above records it being paid;
adding the pair here is what lets `check_promises` see it, which it could not
while the tool read Book II only).

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

**Book II is written.** All twelve studies, 23–34, are committed, and its promise table
is empty because every promise its prose made has been paid. It opens at study 23
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
- **Isolates, FFI, codegen, performance.** Book IV (41–45), per PRODUCT.md.
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
| `jsonEncode` on a note with `,` and a newline | Escapes both; **no literal newline**, so one expense is still one line. |
| `jsonEncode` on an object with no `toJson` | `JsonUnsupportedObjectError` — an **`Error`**. Forgetting it is a bug, not an input. |
| `jsonDecode('not json')` | `FormatException`, "Unexpected character" — an **`Exception`**, so catching is licensed. |
| `map['pence'] as int` where it is a `String` | `TypeError` — an `Error`, which study 26 forbids catching. |
| `const LineSplitter().convert('')` | `[]`. And `'a\nb\n'` gives `['a', 'b']` — no phantom last line. |
| `DateTime(2026, 9, 9).toUtc().toIso8601String()` | `2026-09-08T19:00:00.000Z` — **a different date** from its local form. |
| `avoid_dynamic_calls` | **Not** in this book's lint set. Nothing would flag the cast version. |
| `DateTime.parse('2026-09-10T04:30:00+05:00')` | `2026-09-09T23:30:00.000Z`, `isUtc` true, `.day` **9**. The written calendar day is discarded. |
| `DateTime.parse('2026-02-31')` | `2026-03-03`. **`parse` does not validate either**, so a badly edited file is a wrong day rather than a rejected one. |
| `DateTime.parse('2026-09-09T25:00')` | The 10th at 01:00. Hours overflow too. |
| `DateTime(2026, 3, 0)` | `2026-02-28`; `DateTime(2024, 3, 0)` is the 29th. The overflow that is a bug is also the standard idiom. |
| `local == utc` / `hashCode` / `isAtSameMomentAs` | Measured in seven zones from UTC−11 to UTC+14: **timezone-independent**, because `==` compares `isUtc` too. |
| `local.toUtc()` landing on a different **date** | **Timezone-dependent.** True in Tashkent, false at UTC and in the Americas. Study 29 shipped a test asserting it; fixed. |
| A primary constructor with an optional named parameter | Legal. `class const Expense(…, {final bool acknowledged = false})` analyzes clean. |
| A constant pattern inside a map pattern | Legal and load-bearing: `{'kind': 'limit', …}` binds nothing and is what keeps an expense from reading as a limit. |
| An optional JSON key beside a map pattern | Cannot be expressed as a pattern. Read off the matched map instead — a bound `'acknowledged': final bool` refuses every older line. |
| `List.sort` stability | **Stable to 33 equal elements, not at 34.** Deterministic across runs, and every hand-written test list is on the safe side. |
| `Map.fromIterable` under this lint set | `prefer_for_elements_to_map_fromiterable` fires — note the analyzer lowercases the name the yaml spells `fromIterable`. |
| `Money? operator -` | Legal. An operator may return a nullable type, which is how a partial operation says so. |
| Adding two members to `Store` | **4 implementations broken**, two of them test doubles with no opinion about the new members. |
| `SpyStore.calls` after study 32's budget check | `['limits', 'record']` where study 27 asserted `['record']`, with no change to what the program does. |
| A **factory in the unnamed slot** beside a private primary constructor | Legal. `class const Limit._(…) { factory Limit(…) }` — a published type gains a check and no call site moves. |
| `dart pub add args` in a **workspace** | Prints the workspace root's paths and no version line. A standalone package prints `+ args 2.7.0` / `Changed 1 dependency!`. |
| `args` in the workspace lock | `dependency: transitive` — `package:test` already depends on it. In a standalone package it is `direct main`. |
| `--fi` for `--file` | **Throws.** `args` has single-letter `abbr:` and no unique-prefix abbreviation. `--hel` is not `--help`. |
| `add -5.00 food` through `ArgParser` | **Throws** `Could not find an option with short name "-5"`; `-5` gives `Could not find an option or flag "-5"`. No setting turns this off. |
| `--` before a leading-dash word | Restores it: `add -- -5 food coffee` reaches `readMoney` and answers `refused`. |
| `ArgParserException` | `is FormatException`, `is Exception`, **not** an `Error` — so study 26 licenses catching it. |
| `ArgResults` typed accessors | `flag`→`bool`, `option`→`String?`, `multiOption`→`List<String>`. The package's own doc says to prefer them over `[]`, which is `dynamic`. |
| `ArgParser.usage` with `addCommand` | Lists **options only**. Commands are not in it; `parser.commands` is an `UnmodifiableMapView<String, ArgParser>`. |
| `CommandRunner` and `--help` | Free, and it **prints to stdout from inside the library** — the one thing `lib/` has not done since study 24. |
| `addOption(allowed: […])` | Rejects with `"colour" is not an allowed value for option "--sort"`; usage renders `[day (default), amount]`. |
| `unintended_html_in_doc_comment` | In this book's lint set. `/// add <amount>` in a doc comment fires it; backticks fix it. |
| Removing a dependency, keeping the import | Still compiles — `args` is reachable through `test`. One `info`: `depend_on_referenced_packages`. |
| `dart pub publish --dry-run` on `publish_to: none` | **Does not refuse.** Builds the archive, validates, exits **65**. |
| That validation on study 33's package | **2 errors** (LICENSE, `version:`) and **4 potential issues**, on code that analyzes clean and passes every test. |
| What study 33's package would have shipped | `SLICE`, `exercises/` and all of `test/` — 33 KB. With a `.pubignore`: 18 KB. |
| The last warning, on a package named `expenses` | **Gone.** 0 warnings, exit 0. The residual warning is the snapshot naming, not the package. |
| `dart doc` on this package | **1 public library, 19 types**, 0 warnings, 0 errors — exactly what the barrel exports. |
| `public_member_api_docs` on study 33's package | **22 issues** on code analyzing clean. 12 real; the other 10 are primary constructors. |
| Documenting a class to satisfy that lint | **Does not.** It points at the constructor in the header. A doc on a header parameter does not either. |
| The only spelling that satisfies it | The pre-3.13 body form. So the lint costs ADR 0002, and this book does not take it. |
| `^2.7.0` / `^0.4.2` / `^0.0.3`, from `pub_semver` | `>=2.7.0 <3.0.0-0` / `>=0.4.2 <0.5.0-0` / `>=0.0.3 <0.1.0-0`. Below 1.0.0 the minor is the breaking one. |
| `dart compile exe` on this program | 5.7 MB, ~1.4s to build. **~0.53s for `dart run` against ~0.01s** for the binary. |

### 23 — Libraries, imports and privacy · `libraries` · `ch23_expenses` — **WRITTEN**

Shipped: 7 green, 3 challenges at 5 failing, 10 transcripts. Two things the writing found
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

Shipped: 14 green, 3 challenges at 7 failing, 7 transcripts. The first snapshot with a
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

Practice: the candidate was *dart.dev — Write command-line apps*, on exit codes and
`stderr`. **Resolved: it does not say it.** The shipped `<Practice>` omits both props the
way study 2's does, and says so on the page — "two dart.dev pages were opened looking for
one before this note was written".

Gloss: `dart run` compiles to a kernel snapshot each time; `dart compile exe` is what
you ship. Named now, met in study 34. **Measured there:** 5.7 MB binary, ~0.53s for
`dart run` against ~0.01s for the binary, on the same command.

### 25 — Values and entities · `values-and-entities` · `ch25_expenses` — **WRITTEN**

Shipped: 33 green, 3 challenges at 8 failing, 7 transcripts. The outline's planned
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

Shipped: 36 green, 3 challenges at 6 failing, 7 transcripts. Two things measured that the
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

- **Two of Book I's transcripts had been false since `97f639e`**, and this study's own
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

### 29 — JSON · `json` · `ch29_expenses` — **WRITTEN**

Teaches `dart:convert`: `jsonEncode`, `jsonDecode`, `toJson` by hand, `LineSplitter`,
`Object?` where `dynamic` was on offer, and round-trip tests.

Toy: `file_store.dart` rewritten to write one JSON object per line, and both notes that
study 28 could not carry.

Drill: the same command in both programs. Study 28 prints the expense, writes it to the
file, and then answers `nothing recorded yet` — three separate things saying it worked
while the money is gone. Captured by running each package's own `bin/expenses.dart`.

**One object per line, not one array.** An array is the usual shape for a JSON file and
cannot be appended to — you would read every expense, add one, and write them all back on
every `add`. Measured: `jsonEncode` escapes a newline as the two characters `\` and `n`,
so one expense is still one line and study 28's `FileMode.append` survives.

The mechanism to name, and it is better than the outline planned: **a map pattern is the
cast that checks.** `jsonDecode` returns `dynamic`, and the obvious way out is
`map['pence'] as int` — which throws a `TypeError` on a file somebody edited. Measured:
`TypeError` implements `Error`, so study 26's rule leaves no good move — catch an `Error`
(forbidden) or die because of a stray quote. `{'pence': final int pence}` asks instead of
asserting, ignores keys it has not heard of, and answers `null`. Study 14's patterns doing
the work, at the one place in the program where the analyzer knows nothing.

Then the second question, which JSON has no opinion about: `-1250` is a perfectly good
`int` and is not money; `2026-02-31` is a perfectly good string and is not a day. The type
check and the domain check are separate and run in that order.

`lib/` gains its **first `catch` since study 26 removed them all**, and the study says why
it is not a retreat: `jsonDecode` throws `FormatException`, which is an `Exception` and not
an `Error`, and unlike study 28's `exists()` there is no way to ask first — deciding whether
text is JSON *is* parsing it.

Found while writing, by the study's own test: **the first version of `Day.parse` had the
exact hole it was written to close.** Checking that every character is a digit *or* a dash
is not enough — `-123-01-01` is ten characters with a dash in both the places the shape
wants one, and `int.parse` takes the sign, giving the year -123. The check has to be
positional. Written into the method's doc and asserted.

Practice: **the outline's candidate is an index page, not a guideline.**
*dart.dev — JSON serialization* lists `dart:convert`, `json_serializable` and `built_value`
and recommends nothing, so there is nothing to cite there. What fits exactly, and is
uncited, is *Effective Dart — Design*: **AVOID using `dynamic` unless you want to disable
static checking**, whose body says *"Rely on `is` checks and type promotion to ensure that
the value's runtime type supports the member you want to access before you access it"* — a
map pattern is precisely that. It is also why `expenseFromJson` takes an `Object?`.
Verified on the live page. `avoid_dynamic_calls` is **not** in this book's lint set, so
nothing would have flagged the cast version; `strict-casts` catches only implicit casts and
every cast in that version was written out.

Gloss 1 (the outline's, now measured): `jsonEncode` calls `toJson()` and throws
`JsonUnsupportedObjectError` — *"Converting object to an encodable object failed"* — when
there is none. An **`Error`**, which is the right category: forgetting `toJson` is a fact
about the code.

Gloss 2: the first `catch` in `lib/`, above.

`toJson` is an **extension** and `expenseFromJson` a top-level function, both in
`expense.dart`, by study 27's rule — serialisation is one thing done to an expense and not
part of what an expense is. `Day.parse` stays on `Day`, because a type that writes itself
down owns reading itself back.

`#day` is exempted in the SLICE: `Day.parse` was added to a class study 25 shows whole, and
re-showing seventy lines to point at one method is what the exemption exists for. What
`parse` does is on the page as assertions, and 29.4 quotes the one line that matters.

### 30 — Dates, times and periods · `dates-and-times` · `ch30_expenses` — **WRITTEN**

Shipped: 103 green, 3 challenges at 11 failing, 4 transcripts. Four `DateTime` traps, one of
which (`==` against `isAtSameMomentAs`, with hash codes agreeing) study 25 had already spent —
so study 30 measures four and calls three of them its own, which is what study 29's "the other
three" had promised. The equality assertions **moved** out of `values_test.dart` into
`instant_test.dart` so all four have one home rather than two copies.

Two things the writing found that this entry did not predict.

**`DateTime.parse` does not validate.** `2026-02-31` parses to the 3rd of March, and
`T25:00` rolls into the next day. That is the trap that reaches a file, because study 29 stores
a day as text and reads it with `Day.parse`, which answers `null`. It became the Drill.

**Study 29 shipped a machine-dependent test.** It asserted that `local.toUtc()` lands on a
different *date*, which is true in Tashkent and false at UTC and everywhere west of it.
Measured across seven zones: exactly one test in the whole book was timezone-dependent. Fixed
to assert the dependence rather than the answer, and the book now passes from UTC−11 to UTC+14.

Departure from the plan, argued: `Period` needed a caller or it was speculative code, so `list`
gained an optional `YYYY-MM`. That forced `totals` off `Store` and onto `Iterable<Expense>` —
the move study 27 said it was waiting for — and the `Future` came off with it, which is the
precise shape of async contagion: it travels along calls, so removing the call removes the
future. `Day._lastDayOf` lost its underscore because `Period` is another library.

Practice: **no attribution.** Confirmed by opening the pages: Effective Dart — Design has no
guideline about dates, times or narrow types, and the `DateTime` API page carries no warning
about equality or overflow. The nearest published caution is dart.dev's `dart:core` tour —
*"Using a `Duration` to shift a `DateTime` by days can be problematic…"* — which is one
consequence of the rule rather than the rule, so it is quoted inside the Practice as such and
the props stay off.

Gloss: DST named, not demonstrated, with `package:timezone` 0.11.1 (`labs.dart.dev`) cited as
where the answer lives.

### 31 — Reports · `reports` · `ch31_expenses` — **WRITTEN**

Shipped: 116 green, 3 challenges at 12 failing, 6 transcripts. `Report` arrives and `totals`
stops being an extension, which pays study 27 in full: deleting it named **8 call sites and no
implementations**, and that analyzer run is on the page.

The study's own fact, found by measuring rather than planning: **`List.sort` is not stable, and
it does not degrade gently.** 33 equal elements keep their order; 34 do not, and the first
becomes the twelfth. Deterministic. Every list a person writes by hand in a test is on the safe
side of the threshold, so a missing tie-break holds in testing and fails for a user — which is
what makes `Comparable`'s promise of a *total* order mechanical rather than pedantic.

Two departures, both because reality got there first.

**The broken-`hashCode` demo is not here.** This entry wanted one category becoming two rows;
study 25 already spends that in full, with its own `Sloppy` class and a `hash_and_equals`
transcript. Study 31 pays study 25 the other way instead — four spellings of *food* land on one
line and nothing in `Report` mentions why.

**`operator -` is not here either.** Subtraction on a non-negative type is partial and needs
somewhere for the failure to go, and a report never subtracts. Shipping `Money?` with a `null`
that means nothing would have taught the syntax and not the lesson, so it went to study 32,
where `null` means *overspent*. `Money` gained `+`, `zero` and `Comparable`; `Day` gained
`compareTo`.

Practice: `prefer_for_elements_to_map_fromIterable`, **verified** on the live page. The rule's
own words are *"Prefer `for` elements when building maps from iterables"*; the analyzer's
message is *"Use 'for' elements…"*; and the page lists five benefits, of which inference and
null safety are the ones that bite. Present in `package:lints/recommended.yaml` 6.1.0.

### 32 — Budgets · `budgets` · `ch32_expenses` — **WRITTEN**

Shipped: 156 green, 3 challenges at 14 failing, 5 transcripts. The tracker's only aggregate:
`Budget` holds a `Limit`, a `Period` and the expenses that fall in both, because no object in
the program can answer the rule alone. The vocabulary — *consistency boundary* — gets one
sentence and the rest of the study is mechanism, as planned.

The honest complication is kept: an acknowledged overspend is representable
(`acknowledged: true`, printed `(over budget)`, stored), and only the unacknowledged breach is
refused. `--anyway` is the escape.

Two things the writing found.

**Study 29's forward compatibility paid off exactly as designed.** `toJson` writes the fifth key
only when true, so an ordinary expense is byte-identical to the line study 29 wrote — and an
optional key *cannot* be expressed as a map pattern, so it is read off the matched map. A bound
`'acknowledged': final bool` would refuse every file the program has ever written.

**Study 27's warning arrived twice, unprompted.** Growing `Store` by two members broke four
implementations, two of them doubles with no opinion about limits. And `SpyStore`'s
`calls == ['record']` failed because `add` now asks for the limits first — *the program does
exactly what it did before*, every fake-based test passed untouched, and that assertion has now
been rewritten for two changes that broke nothing. Study 27 could only describe this
hypothetically; it happened by itself.

Departure from the plan, argued: this entry said `Store.record` becomes fallible. It does not.
The rule is asked before the store is called, because putting a domain rule behind the
persistence interface is precisely what study 27's separation forbids — every fake would have to
grow the rule or lie about it. What became fallible is *adding an expense*, which is `run`'s
job, via the aggregate.

Practice: **no attribution**, as planned — *put the rule on the smallest thing that can see all
of it.*

Gloss: CQRS, units of work and transaction boundaries named and refused, with the reason stated
as concurrency this program does not have.

**Found by the audit after shipping: `Limit` did not enforce its own invariant.** `Money` allows
zero and should; a limit of nothing is not a limit. That rule was written twice — the `budget`
command refused it with an exit code, and `limitFromJson`'s `when` clause refused it with `null`
— and the type between them had neither. So `Limit(Category('food'), Money.zero)` constructed,
serialised to `{'kind': 'limit', 'category': 'food', 'pence': 0}`, and read back as `null`: a
value the program could write and could not read. Measured, then fixed by making the primary
constructor private and putting a factory in the unnamed slot, which cost no call site. The page
gained the paragraph and a Gloss, because the fix is a better lesson than the original code was.

The study's own rule of thumb is what names the defect: *put the rule on the smallest thing that
can see all of it.* It was stated in bold on the page and broken four inches below by the page's
own code.
### 33 — Taking a dependency · `taking-a-dependency` · `ch33_expenses` — **WRITTEN**

Shipped: 165 green, 3 challenges at 9 failing, 9 transcripts. `package:args` **2.7.0**
replaces the parser three studies apologised for, and all three of study 33's debts are
paid in one slice: `--file` (28), `--help` and `--flag=value` and single-letter
abbreviations (24), and the deletion of `_flagged` (32).

**Every claim about `ArgParser` was measured before it was written, as the plan demanded.**
Context7 has no Dart `args` entry — checked, not assumed — so the API was read out of
`~/.pub-cache/…/args-2.7.0/lib/` and exercised in a throwaway package. Four of those
measurements changed the study.

**The dependency took a behaviour away, and that became the study.** `add -5 food coffee`
was `refused` in study 24 — a well-formed request `Money` forbids, exit 1 — and
`package:args` reads a leading `-` as an option, so it is now `misuse`, exit 2. Measured:
one test out of 165 failed when the dependency went in, and it was that one. There is no
setting for it (`ArgParser` takes `allowTrailingOptions` and `usageLineLength` and nothing
else) and it is not about the abbreviations this program declares, because a parser with no
abbreviations at all does the same. `--` restores it, and 33.4 is built on the whole
sequence. That is a better lesson than the `--help` was.

Departures from the plan, each argued and measured:

- **`ArgParser` with `addCommand`, not `CommandRunner`.** The outline said "`ArgRunner`",
  which is not a name in this package. `CommandRunner` does give `--help` for free —
  measured, it prints the usage itself and `run` answers `null` — and the printing is the
  problem: it writes to stdout from inside a library. Every study since 24 has rested on
  `lib/` never printing and `run` answering an `Outcome`, which is what makes a command
  testable without a terminal. Taking `CommandRunner` would trade study 27's seam for a
  help flag.
- **`--help` is therefore not free, and what is free is better.** Half the usage text is
  generated from the parser and can no longer disagree with it; the other half — the
  positional grammar — `ArgParser` does not model at all, so it is still hand-written and
  can still rot. Naming which half the dependency took over is 33.3.
- **`package:args` appears in no public signature.** `run` still takes `List<String>` and
  `fileFrom` answers a `String`. Putting `ArgResults` in `run` would have been the tidier
  design and would have made the dependency part of what this library promises its
  callers — which is study 34's subject, so the study says so instead of doing it.
- **The typed accessors, not the subscript.** `results['anyway']` answers `dynamic` and
  this book turns on `strict-casts`; `flag`/`option`/`multiOption` are typed, and the
  package's own doc comment says to prefer them.

**Found while writing: two flaws in `check_shown`, both false positives, both real bugs.**
Its declaration pattern had `\s` inside the leading character class, so the *indentation*
could stand in for a type and every `test('…', () async {` outside a region registered a
declaration of `test`. And `_string` reads one line at a time, so a `'''` block's prose was
read as code — study 33's `usage` says *show what has been recorded* and the checker
reported the region as using `recorded`. Both fixed, and the fix proved in both directions:
an injected helper declared outside every region is still caught.

The real report underneath them stood: `_list` and `_listMonth` were the only helpers in
`command.dart` outside every region, which only surfaced because study 33 is the first page
to show `#run`. They are a region now, exempted in `SLICE` with the reason.

Practice: `depend_on_referenced_packages`, verified against the live page and against
`lints-6.1.0/lib/core.yaml:19`. Demonstrated rather than asserted: `args` is already
reachable through `package:test`, so deleting the dependency and keeping the import leaves
a program that compiles with one `info` — captured in `undeclared.txt`.

Gloss: `dependencies` against `dev_dependencies`, argued from what a *caller* receives
rather than from tidiness.

**Audit, pass nine — the first pass to reach this study.** Passes one to eight all predate
it. One false count: the page said `package:args` "replaced a parser three studies had
apologised for", and two did — study 24, which wrote the parser and named study 33 as its
replacement, and study 32, which built more parsing on top of it and said so on the page and
again in a `command.dart` doc comment. Study 28 is the near-miss that makes the sentence easy
to write from memory: it mentions the parser to say it *did not have to be rewritten* to go
async, which is the opposite of an apology. Everything else re-measured true — 165 green under
`TZ=UTC` and `TZ=Pacific/Kiritimati`, `dash.txt` still shows a test that really exists at
`ch32_expenses/test/command_test.dart:339`, and every code-shaped backtick fragment on the
page is either a filename, CLI syntax, or an `args` API the study deliberately does not use.

### 34 — Being a dependency · `being-a-dependency` · `ch34_expenses` — **WRITTEN**

Shipped: 168 green, 3 challenges at 10 failing, 9 transcripts. Closes Book II. Study 23's
`lib/src/` stops being a privacy mechanism and becomes a contract: `dart doc` documents
**one public library** and **nineteen types**, which is exactly what the barrel exports.

**The outline's guess about `dart pub publish --dry-run` was wrong, and the truth was
better.** It does not refuse a `publish_to: none` package. It builds the archive, prints
it, validates it, and exits **65** — measured on study 33's package: **2 errors** (no
LICENSE, no `version:`) and **4 potential issues** (library name, no homepage/repository,
no README, no CHANGELOG), on a package whose tests all pass and whose analyzer is silent.
None of them is about the code.

The archive listing turned out to be the better half. Study 33's package would have shipped
`SLICE`, `exercises/` and every file in `test/` to every stranger who downloaded it — 33 KB
of archive, of which 15 KB is this book's own scaffolding. `.pubignore` takes it to 18 KB.
That is a fact nobody would have guessed and everybody can check.

After the fixes, one warning is left and it is the book's fault rather than the package's:
`pub` wants `lib/<package name>.dart`, and these packages are named for their study number.
Measured on the identical code in a package named `expenses`: **0 warnings, exit 0.** The
page says so rather than renaming the barrel, because `lib/ch34_expenses.dart` is not a
thing any reader should copy.

**The lint this study turned on, read, and did not take.** `public_member_api_docs` is not
in `recommended.yaml`, so switching it on is a decision — and for a package about to be read
by strangers it looks like the obviously right one. Measured on study 33's package: **22
issues** on code that had been analyzing clean since study 23. Twelve were real (public
getters and factories with nothing said about them, and two exit-code constants documented
with `//` where `///` was meant) and are fixed here. The other **ten are primary
constructors**, and they cannot be fixed:

- documenting the class does not silence it — the lint points at the constructor inside the
  header, not the class;
- a doc comment on a parameter inside the header does not silence it either;
- the only spelling that satisfies it is the pre-3.13 body form.

So the lint would cost ADR 0002's default class syntax, and this book does not take it. That
is a better lesson than adopting it would have been: a policy is a thing you weigh by turning
it on and reading what it says.

The study's own new test is the one worth carrying into Book III: `test/surface_test.dart`
reads `lib/expenses.dart` back as text and compares its exports against a list somebody wrote
on purpose, and checks that `pubspec.yaml`'s version and the top of `CHANGELOG.md` agree. A
contract nobody checks is a contract that drifts.

**Paid study 33's promise about a dependency in the public API**, with the cost stated: a
type from a dependency in your public signatures makes that dependency's major versions into
yours, and your callers pay for somebody else's decision. `dart doc` publishes nineteen types
and `ArgParser` is not one of them.

Licence: MIT, in `ch34_expenses/` only, chosen by the author when the study surfaced the
question. The repository root is still unlicensed and that item stays on `HANDOFF.md`'s open
list.

Practice: `slash_for_doc_comments`, verified in `lints-6.1.0/lib/recommended.yaml:51` and
never cited before. Apt here because it is the study where `///` stops being a prettier
comment and becomes the thing `dart doc` publishes and an IDE shows a caller.

Gloss: `dart compile exe`, paying study 24's Gloss with numbers.

**Audit, pass nine — also its first.** One false count: 34.4 said study 1's argument arrives
"twenty-three studies later", and 34 − 1 is thirty-three. The counts that could be settled
against something all held — nineteen types (counted from `dart doc`'s generated pages, not
from the source), eleven files under `lib/src/` and eleven exports, seven files in the SLICE,
twenty-two lint issues, thirty-three kilobytes down to eighteen. The caret claims were
re-measured against `pub_semver` in a throwaway package: `^1.4.2` is `>=1.4.2 <2.0.0-0`,
`^0.4.2` is `>=0.4.2 <0.5.0-0`, and `^2.7.0` refuses `3.0.0-dev` — all three as the page and
the measured-facts table state them.

The pass also found the ADR defect this study's own subject exposes: **ADR 0003 predicted that
study 28 would cite nothing, and study 28 cites something.** The record's premises were sound
and its conclusion was a guess made before the study was written. Both are now standing
requirements.

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

**Empty.** Book II made fourteen promises and paid all fourteen, which is what the table
exists to make checkable. Study 34 paid the last one — 34←33, what a dependency in your
public API costs — by measuring it: `dart doc` publishes nineteen types and `ArgParser` is
not one of them, because study 33 kept it out of every signature on purpose.

Paid: 26←24 (`null` could not say which part was wrong; a sealed `Reading` can),
26←24 again (`dart compile exe` named in a Gloss, measured in 26.4), 27←24 (the seam
behind `Outcome` is named and two more are cut), 27←25 (`Store` is an interface now that
a second implementation exists), 27←26 (both lines study 26 left alone became
parameters), 28←25 (the store stops forgetting when the program stops), 29←28 (both
characters study 28's format could not carry now survive a round trip), 30←25 (`Day`
against `DateTime`, argued with four measurements instead of one line), 30←29 (the other
three ways, and study 30 is careful that its count and study 29's agree), 31←27 (`totals`
stopped being an extension and became `Report`), 31←30 (`list <month>`
became a report with an order and a total), 32←31 (`Money` got the `operator -` study 31
argued for and withheld), 33←28 (`--file` says where the tracker lives, and the `const`
in `bin/` is gone), 33←24 (`--help`, `--flag=value` and single-letter abbreviations —
**two of the three in full and one smaller than the promise sounded**, because `args` does
not abbreviate long names and study 33 says so), 33←32 (`_flagged` deleted, and study 32's
own `--anyway` tests pass untouched against the new parser), 34←33 (a dependency's types
kept out of the public surface, and the cost of the alternative stated in versions).

Study 33 carried three and paid all three, which is the most any study in this book has
both owed and settled. One of them came back smaller than it was promised: study 24 said
*abbreviations*, and what `package:args` has is single letters declared with `abbr:`, not
unique prefixes. `--hel` is not `--help`, measured. The study pays what the dependency
actually provides and names the gap rather than letting the word cover both.

Removed as fiction, found by checking the prose rather than the plan: **31←25** — the
outline meant study 25 to promise study 31 that `Category`'s equality is what makes
grouping work, and the written study never names study 31. **34←23** and **34←24** —
neither study's prose mentions study 34 at all. A table that records promises nobody made
cannot cost a reorder, which is the only reason it exists.

## Book III: Build the API (studies 35–40)

The same expense tracker, given a second edge, shipped as six snapshot packages —
`code/ch35_expenses/` through `code/ch40_expenses/`. ADR 0005 records the order and what
the sixth study cost. ADR 0004 records the snapshot layout, which this book inherits
unchanged.

Prose lives in `web/content/docs/build-the-api/`. Add the book to
`web/content/docs/meta.json` and each slug to that directory's `meta.json`, or the study
does not appear in the rail and nothing warns you.

Book III's spine is **when the reader can call it**. Study 35 answers `curl`, and every
later study changes a server that already answers. The structural difference from Book II
is what failure looks like: a CLI that is wrong prints the wrong thing and exits, and a
server that is wrong keeps running, holding something that stopped being true, answering
a stranger who is still waiting.

**`ch35_expenses` is `ch34_expenses` plus a server, and the CLI survives.** That is what
turns `PRODUCT.md`'s "reusing the CLI's domain package" from a narrative claim into a
checked one: `check_slices` asserts every domain file is byte-identical, and
`diff ch34_expenses ch35_expenses` is the server and nothing else. It also hands study 38
a free second writer — the CLI, run from another terminal, writing the same file the
server is holding in memory.

### What a snapshot carries, and what it must not

The handoff asked what a `SLICE` means when the package is a server rather than a CLI.
**It means exactly what it meant** — the files this study adds or changes, with everything
unnamed proved byte-identical to the previous study's copy. Nothing about that definition
mentions what the program does, and Book III is the test of that.

Verified rather than assumed: `check_slices` and `check_regions` both select packages with
`^ch(\d\d)_expenses$` and sort lexically, so `ch35_expenses` chains onto `ch34_expenses`
with **no change to either tool**. That is the mechanical case for continuing the
numbering, and it is why the name stays `_expenses` even though the program grows a
second edge — the program is still the expense tracker.

Three things Book III must get right that Book II learned the hard way:

- **Delete `transcripts/` after copying.** `ch35_expenses` starts as a copy of
  `ch34_expenses`, which holds seven of study 34's transcripts. `check_slices` skips
  `transcripts/` on purpose, so an inherited transcript is invisible to every checker.
  Study 33 shipped three of study 32's this way. Compare `ls chNN/transcripts` against the
  previous study's before committing.
- **`web/content/docs/build-the-api/meta.json` needs a `title` key**, not just a page list:
  `"title": "Book III: Build the API"`, matching how `writing-good-dart/meta.json` names
  Book II. The book must also be added to `web/content/docs/meta.json`'s `pages` array.
- **The spike is not a snapshot.** It must not be called `chNN_expenses` or the two tools
  above will pick it up and demand a `SLICE`. It lives outside `code/`, is never committed,
  and its only output is rows in the tables below.

### Titles are provisional; the numbering is not

Book II's two best studies got their theses from measurement rather than from this file.
Study 33's argument appeared when `package:args` silently changed one test of 165, and
study 34 turned on `public_member_api_docs`, read the 22 issues, found ten unfixable
under ADR 0002, and declined the lint on the page. Neither was in the outline.

So the entries below name what each study is *for* and leave the thesis to construction.
Study 39 has no title at all, because naming it would be predicting what `sqlite3` does
before anyone has run it.

### Facts measured while outlining, so no study need guess them

Run on Dart 3.13.2 stable (macos_arm64), in a throwaway package outside the workspace.

| Measured | Result |
| --- | --- |
| `dart pub add shelf shelf_router sqlite3` | `shelf` **1.4.2**, `shelf_router` **1.1.4**, `sqlite3` **3.5.2** |
| `sqlite3` 3.5.2 on **stable** 3.13.2 | Runs. **No `--enable-experiment` flag.** |
| What `sqlite3` 3.5.2 pulls in | `native_toolchain_c` — which it **does not use by default**. Outlining wrote "compiles SQLite from source" from that dependency's presence; the spike found it false |
| What the build hook actually does | **Downloads a prebuilt binary** from the package's GitHub releases. Measured: `.dart_tool/hooks_runner/shared/sqlite3/build/download-*/libsqlite3.dylib`, a **1.6 MB Mach-O arm64** library, and **zero `.o` files** anywhere |
| The prerequisite this creates | **Network on first build, not a C toolchain.** Verified by shadowing `clang`, `cc`, `gcc` and `xcrun` with failing stubs: the build still succeeded. `hooks: user_defines: sqlite3: source:` opts into `system`, `process` or a local `sqlite3.c` |
| The SQLite it binds | **Prebuilt 3.53.4**, not the host's — so it is the same on every reader's machine |
| `sqlite3` as a **pub workspace** member | Works. `dart pub get` at the root and `dart test` in the member both succeed, so study 39 is possible in this repo's layout |
| `Running build hooks...` | Printed **twice, on stdout, on every run** — warm and cold alike, byte-identical across consecutive runs |
| Where that lands in `dart test` output | Prefixed to the **first progress line**, with no newline after it. The **last** line is clean: `00:00 +1: All tests passed!` |
| What that costs the transcript convention | **Nothing for a passing run** — Book II already cuts those to the final status line, which is clean. `check_transcripts` reads only `\+(\d+): All tests passed!`, a count. A **failing** transcript keeps the narrative from the top, so studies 39–40's failing transcripts carry the prefix and must keep it verbatim rather than tidy it away |
| `sqlite3.openInMemory()` + `CREATE`/`INSERT`/`select` | Works; `select` yields `[{pence: 450}]` |
| `implements Store` in `ch34_expenses` | **Four**: `InMemoryStore`, `FileStore`, and two doubles in `test/store_test.dart` |
| Book II's study size, all twelve | **4 or 5 numbered sections**, **1535–2489 words**. No exceptions |
| The CLI's entire surface | `add <amount> <category> <note>` `[--anyway]`, `list [YYYY-MM]`, `budget [<category> <amount>]`, `help`; codes `okay 0` / `refused 1` / `misuse 2` |
| `_add`, `_setLimit`, `_list`, `_record` | **Already take `Store` and `Day` as parameters.** Study 27 cut those seams for testability, and they are the application layer |
| `Outcome` | `({int code, String out, String err})` — a shell's exit code and human text. The one thing an API cannot reuse |

### Read in the docs, not yet run — measure before writing as prose

Every row here came from `package:shelf`'s own documentation via Context7. The standing
requirement is that a factual claim in prose is an assertion in a test or a transcript, so
each of these is a claim to be executed, not quoted.

| Documented | To verify |
| --- | --- |
| `shelf_io.serve` returns `Future<HttpServer>` | That the `dart:io` type is really what comes back — it is study 35's whole argument that `shelf` is not a replacement for `dart:io` |
| `Handler` is `FutureOr<Response> Function(Request)` | That a handler is callable in a test with a constructed `Request` and no socket |
| `serve` adds `Date` and `X-Powered-By` | Both, and that `poweredByHeader: null` omits the second. This is study 35's measured difference between the hand-rolled server and `shelf` |

### What the spike measured

**RUN.** A `shelf` server in front of a copy of `ch34_expenses`'s real `lib/`, outside
`code/`, never committed. Book III's spine survives; two of this outline's own claims did
not.

**1. Interleaving — the load-bearing one. Prediction confirmed, and sharper than predicted.**
Two requests written to two already-open sockets before either response is read:

| The handler awaits | Verdict, five passes |
| --- | --- |
| `InMemoryStore` — already-complete futures | **SEQUENTIAL**, 5/5 — one request always finishes before the next is entered |
| `FileStore` — real disk I/O | **INTERLEAVED**, 5/5 |
| `Future.delayed(Duration.zero)` — a timer | **INTERLEAVED**, 5/5 |

**Print the verdict, never the trace.** The verdicts are stable; the trace is not. An
interleaved run is sometimes `A enter, B enter, A exit, B exit` and sometimes
`B enter, A enter, B exit, A exit` — which request wins the race varies between runs, and
a first draft of this section published one of the two orders as though it were the
result. A transcript of a trace would fail `check_transcripts` on somebody's second run.

So an `await` on a completed future really does resume on the microtask queue, which
drains before the event loop takes the next socket event. **Study 40 keeps its argument.**

The first harness said all three were sequential and was wrong: it `await`ed
`Socket.connect` for B, which yields, letting the server finish A before B existed. It was
measuring the client's pacing. Connect both first, then write with no `await` between.

**2. The lost update is real, and it will not hold still.** The prose says *two requests
both check, both pass, both record*. Against `FileStore` with a 1000p limit and 600p per
request, that happens **sometimes**, and how often is not a number this book can print.
Three runs of the identical 40-trial experiment:

| Concurrency | run 1 | run 2 | run 3 |
| --- | --- | --- | --- |
| 2 | 11 / 40 | 10 / 40 | 4 / 40 |
| 3 | 32 / 40 | 20 / 40 | 7 / 40 |
| 4 | 39 / 40 | 17 / 40 | 27 / 40 |

Not even monotonic in concurrency — run 1 breaches *less* at four callers than at three.
**The unreproducibility is the finding**, and the ratios above are printed only to show
that it is real; none of them is a fact about the program.

The first draft of this section published run 1 alone, as three measured facts, in the
same commit that corrected the book for writing counts from impression. Before that, six
consecutive clean runs at concurrency two nearly established "two callers are safe" as a
rule. **So study 40 cannot assert a breach from concurrency alone** — a flaky test in a
book about testing is not a trade this book makes.

**The mechanism is narrower than "concurrency", and this is study 40's real thesis.** A
lost update needs a suspension **between the decision and the write** — not merely a
suspension somewhere:

| Where the store suspends | Concurrency 2 | Concurrency 3 |
| --- | --- | --- |
| in the **read** (`all`) | 1 recorded, **30/30** | 1 recorded, **30/30** |
| in the **write** (`record`) | 2 recorded, **30/30** | 3 recorded, **30/30** |

A suspension before the decision is harmless: every request resumes with the same answer,
and the first to resume runs decision-and-write to completion because nothing after the
read yields. **Put the suspension in the write and the breach is deterministic** — 90
trials per configuration across three passes, identical every time — which is how study 40
gets a reproducible transcript and a test that is not a coin.

*"`FileStore` breaches only because `record` touches a disk"* started as an inference from
that table and is now measured: a store that reads from a real file and records into
memory — genuine disk I/O before the decision, none after it — recorded **one expense in
40 trials** at two and three callers. The disk read is not what breaks the rule.

**3. Hand-rolled against `shelf`.** Same endpoint, both analyzing clean: **18 lines** of
`dart:io` against **11** of `shelf` + `shelf_router`, counting imports and discounting
blanks and comments. **State the asymmetry with the number or do not print it**: the
`shelf` side returns a `Handler` and still needs an `io.serve(…)` call the raw side already
contains, and the raw side hand-writes the 404 that `Router` gives away. Roughly one line
back to `shelf`, and a saving that is real but smaller than 18-against-11 sounds. A line
count comparing two things that do not do quite the same thing is the kind of number this
book has been wrong with before. On the wire, `shelf` adds `date` and
`x-powered-by: Dart with package:shelf`; `poweredByHeader: null` drops the second and
nothing else. `x-frame-options`, `x-xss-protection` and `x-content-type-options` come from
`dart:io` and are present either way.

**One difference here was a confound, and the corrected version is the better lesson.**
The hand-rolled server sent `transfer-encoding: chunked` where `shelf` sent
`content-length`, and a first draft called that something `shelf` does to `dart:io`. It is
not: measured, a raw `HttpResponse` sends `content-length` as soon as you set
`contentLength` yourself, and chunks only because the hand-rolled version never did. So
the honest claim is about **who computes it** — `shelf` buffers the body and works the
length out for you, and the eighteen-line version quietly shipped a different wire format
because nobody told it to. That is a better argument for the dependency than a header
count, and it is the kind of thing only a comparison on the wire finds.

**4. `sqlite3` transactions, and a trap worth a section.** `BEGIN` / `COMMIT` / `ROLLBACK`
are plain `db.execute` — there is no transaction helper. A failing statement throws
`SqliteException` carrying `message`, `extendedResultCode` (275 for a `CHECK` violation)
and `causingStatement`, and **leaves the transaction open** (`db.autocommit` is `false`).
**It does not roll back for you**: measured, catching the exception and committing anyway
commits the partial write. A nested `BEGIN` fails with *cannot start a transaction within
a transaction*.

**5. The C-toolchain question was the wrong question.** See the facts table: the hook
downloads a prebuilt library, so the prerequisite is **network on first build**. Book III
prints that instead.

**6. The counting double works.** A `CountingStore` proves study 37's bound is cosmetic in
one green test: `limit=1` and `limit=1000` both make the store hand over **1000 expenses in
1 read**. The response differs and the work does not.

**7. Thirty `<Practice>` hrefs are already spent** across 34 studies — 34 Practice blocks
for 34 pages, so the one-per-study rule holds and four carry no attribution. Book III needs
six outside that set.

**And the exclusion list is not the `<Practice>` hrefs.** Study 35 followed the command this
row originally gave — `grep -rhoE 'href="[^"]+"' web/content/docs/ | sort -u` — chose the
guideline it cleared, wrote the Practice, and then found study 27 citing the same guideline
as a plain markdown link in its prose. Thirty hrefs, **34** distinct `dart.dev` URLs. The
standing requirements now carry the wider sweep; use that one:
`grep -rhoE 'https://dart\.dev/[^")>[:space:]]+' web/content/docs/ | sed 's/[.,)]*$//' |
sort -u`.

### The debt Book III takes on purpose

The spike opened one structural question and it is now settled: **the server serves from
`FileStore` from study 35**, and the lost update is a debt study 40 pays.

`FileStore` interleaves, and the budget check lives in the add path — `limitOn`, then
`Budget.of`, then `store.record` — so the first route that adds an expense carries a race.
The alternative was an `InMemoryStore` until study 38, and it fails on the thing the CLI
was kept for: the CLI writes a file, so an in-memory server shares **nothing** with it. A
reader who runs `dart run bin/expenses.dart add 4.50 coffee` and then calls
`GET /expenses` would get an empty list, which contradicts "reusing the CLI's domain
package" at the level a reader actually notices. It would also cost study 38 its free
second writer.

So Book III has one debt where Book II had three, and it is declared the same way ADR 0003
declares those: **a sentence in the earlier study, never a silent handover.** From the
first study with a write route, the page says that two callers can both pass the budget
check, that the program can therefore record a breach, and that study 40 is where it is
fixed. The reader is told before they can be surprised.

Two things make this honest rather than convenient. The race is **not** reachable in a
study that only reads — a `GET` has no read-decide-write — so it begins exactly when the
first write route does, and the page can name the study it began in. And what study 40
fixes is not "concurrency": it is the suspension between the decision and the write, which
is measurable, deterministic and small enough to state in one sentence.

### 35 — A server that answers · `a-server-that-answers` · `ch35_expenses` — **WRITTEN**

Shipped: 181 green, 3 challenges at 8 failing, 6 transcripts. Opens Book III.

Stand up `HttpServer` from `dart:io` by hand, feel what it costs, then take `shelf` in the
same study. One study and not two, because `shelf_io.serve` **returns** an `HttpServer`:
`shelf` is `dart:io` plus a function type, not a replacement for it, and that is one
lesson rather than two.

The seam is free. `Handler` is `FutureOr<Response> Function(Request)`, so study 27's
argument — a seam is a parameter, and only one of them wants an interface — applies with
nothing to build. A test constructs a `Request` and calls the handler. No socket, no port,
no `setUp` that binds anything.

Pays `files.mdx:50`, which promised a server behind `Store`, and settles study 28's bet:
`Store`'s members were made `Future` on the argument that *a server that blocks on a disk
stops answering everybody*, and this is the study that could not have been written if they
had not been.

The server answers at one path with no routing at all. That is deliberate — study 36 is
what lets it answer about expenses, and 37 is what gives it a surface.

**The line count came out even, and the outline's number was for a different comparison.**
The spike measured **18 against 11**, warning in the same breath that the two sides were not
doing the same work. Written out, they are: `bin/by_hand.dart` is **15** code lines and
`lib/src/server.dart` plus `bin/serve.dart` is **15** too, counting imports and discounting
blanks and comments. The spike's asymmetry is the whole difference — its `shelf` side omitted
the `serve` call and its raw side hand-wrote a 404 that `Router` gives away, and study 35 has
no routing on either side, so neither term applies. `test/server_test.dart#counting` asserts
all three numbers, so this one cannot rot the way the counts this book has been wrong about
did.

**The better sentence was there once the number stopped being the argument**: `shelf` costs
the same lines and puts a different proportion of them where a test can reach — **6** of the
15, against none. Every line of the hand-written server is behind a socket.

**Confirmed on the wire, and sharper than "shelf adds two headers".** The hand-rolled server
sends **no `date` and no `x-powered-by` at all**; `shelf` sends both, plus the
`content-length` it computed by buffering the body. `x-frame-options`, `x-xss-protection` and
`x-content-type-options` come from `dart:io` and are on both. The `poweredByHeader: null`
claim is asserted as a **difference between two responses** rather than as an absence, because
an absence would also pass if it had dropped five other headers.

**The first file this package keeps out of its own barrel, and study 34's test found it
before the prose did.** `lib/src/server.dart` answers a `Handler`, which is a `shelf` type, so
exporting it would put somebody else's major version inside this package's. `surface_test`'s
`onDisk.difference(offered)` failed the moment the file existed, with the reason study 34 had
written for exactly this moment — *which is the point, but it should be a decision*. It gains
a `withheld` set, and a third test asserting that **nothing the barrel offers so much as
mentions `package:shelf`**. Captured as `undecided.txt`, which is the failure itself.

**Version `1.1.0`.** A second entrypoint and a new dependency are things added with nothing
removed, which study 34's table calls a minor. `surface_test`'s existing check that
`pubspec.yaml` and `CHANGELOG.md` agree is what makes that a claim rather than a habit.

**`tool/capture_server.dart` exists, and ADR 0005's rule was necessary but not sufficient.**
That record says the server logs nothing time-varying, which covers the server's own output —
a fixed port, no timestamps — and does not cover HTTP's own `date:` header, which no rule of
this repository's can remove. So the tool's scenarios pipe through a `sed` that elides that
one value, **on line 1 of the transcript**, where the reader can see it and run it. That keeps
the transcript real captured output of a real command rather than something normalised behind
their back. Proved both ways: alter a captured line and `--check` names it; delete a
transcript and it says so; an empty scenario list exits 1 rather than reporting green.
`check_transcripts` defers any transcript containing a `curl` command to it and counts those
as checked rather than skipped.

### 36 — A second edge finds what the first one hid · `a-second-edge` · `ch36_expenses` — **WRITTEN**

Shipped: 197 green, 3 challenges at 11 failing, 5 transcripts.

The server cannot reach `_add`. It is private to `command.dart`, and so are `_setLimit`,
`_list` and `_record` — every use case the tracker has. The CLI never needed them public
because it was the only edge.

`Outcome` is the other half. It is `({int code, String out, String err})`: a shell's exit
code and text written for a person. An API needs a status and a document. The record that
made the CLI testable is precisely the thing the second edge cannot reuse, and saying that
plainly is the study.

Extract `Tracker`, holding the `Store`, with the use cases as methods. **The signatures
barely move** — `_add` already takes a `Store` and a `Day`, because study 27 cut those
seams to avoid mocks. Four studies later a second edge arrives and the seams turn out to
have been the application layer. That is the payoff, and the diff being small is the
evidence.

`CONTEXT.md` gains **Tracker** and nothing else. Avoid: Service, Manager, Facade,
Controller, UseCase, Interactor.

**ADR 0002 settles the constructor form, and it is the header one.** That ADR's rule is
*when a type must check something, the check goes on a constructor with a body to put it
in* — and `Tracker` checks nothing. A `Store` and a `Day` are already-valid values by the
time they reach it, so `class Tracker(final Store store, final Day today)` is correct, and
the measured-facts table already records that a primary constructor on a mutable class is
legal. Study 38 replaces `today` with a `Day Function()`; a function in a header parameter
changes none of this. Do not re-open this at construction time — the choice is the
analyzer's, not a matter of taste.

`Tracker` is exported from the barrel; the server is not. `Tracker` names no `shelf` type,
and study 34 measured what a dependency's types in a public API cost. `surface_test.dart`
is what catches it if that slips.

**Ships a bug on purpose.** `Tracker` holds `today`, which is correct for a process that
lives for milliseconds and wrong for one that runs for days. Study 38 breaks it.

The CLI passes untouched, and that is an assertion, not a claim.

**The prediction about the signatures held, and construction found a sharper way to say it.**
Every private use case took a `Store` and a `Day`; every one now takes a `Tracker`, and the
only line left in `command.dart` naming either is `run`'s own — asserted in
`test/tracker_test.dart#moved`, by reading the file with its comments stripped. A second
assertion says no `store.record`, `store.all`, `store.limits` or `store.setLimit` survives at
the edge, because a layer the caller can go around is decoration. `untouched.txt` is
`diff ch35/test/command_test.dart ch36/…` printing **one** line, and it is the package name.

**One place got worse, and it is the study's most useful sentence.** The refusal message says
*budgeted at £20.00*, and `Breach` carries only how far over. `Breach` is right — *money over*
is a thing the domain can say and *budgeted at* is a sentence — so the edge goes back for the
limit on the refusal path only. Named on the page rather than hidden, and study 37 is where it
stops being friction, because an API answers the limit as data.

**`bin/` is a contract and nothing was checking it.** Study 35's `bin/by_hand.dart` had done
its job, so this study deletes it — the same move study 27 made with `asserting.dart`. But
`dart run ch35_expenses:by_hand` was something a caller could do, so the removal is a
**breaking change**: `2.0.0`, and a new `#runnable` group in `surface_test` holding `bin/` to a
list the way study 34 held the barrel. Study 34's contract test protected exactly the surface
study 34 was about, which is the general lesson and was not predicted anywhere.

**The audit after construction found the real defect, and it is the study's third section
now.** The first draft had `Tracker.record` and `command.dart` each writing
`verdict is Breach && !acknowledged` — the layer deciding whether to write, the edge deciding
what to say. Green both ways, invisible to every checker, and study 37 would have made three
copies. Extracted as `refuses`, an extension on `Verdict?` — nullable on purpose, because a
plain method would have made every caller write `?? false` and that is the same duplication
one layer down. Measured on Dart 3.13.2: `none.refuses(expense)` on a `Verdict?`
that is `null` compiles and answers `false`, because extension methods are dispatched
statically rather than looked up on the receiver. The general form is now a
standing requirement: **extracting a layer does not remove a duplicated rule, it creates the
second copy**, so the moment a second caller arrives is the moment to sweep.

The same pass removed `Tracker.budgets`'s optional `Period` — no caller ever passed one —
and tightened `record` to six lines with the read, the decision and the write each on their
own, which is the shape study 40 has to talk about.

**No write route yet, so the declared debt does not begin here.** ADR 0005 says the lost-update
sentence belongs in the first study with a write route; study 36's server still answers `GET`
at every path. Study 37 is where routing, status codes and a `POST` arrive together, and where
that sentence is owed.

### 37 — The caller is a stranger · `the-caller-is-a-stranger` · `ch37_expenses`

`shelf_router`, and the HTTP surface. The CLI's caller was the person at the keyboard;
the server's caller sends anything.

Study 26's taxonomy becomes status codes, which is the best forward payment in the book: a
*returned* refusal is the client's fault and is a 4xx, and a *thrown* `Error` is the
program's fault and is a 500 the client must never read the text of. Middleware is where
that mapping lives, which is also how `Pipeline` gets taught rather than merely used.

The shared key. It authenticates a **caller, not a user** — `CONTEXT.md` says there is no
Account, one person and one file — and the page says so in those words rather than
letting "authentication" cover both readings.

**A bound on `list` that is a lie.** Slicing after `all` returns means `FileStore` read the
whole file and threw most of it away, and a counting double asserts the store did identical
work for `limit=1` and `limit=1000`. Principle 3: the reader meets the bad choice and sees
it fail. Study 39 is where a bound can be kept.

### 38 — The server holds on · `holding-on` · `ch38_expenses`

`FileStore.all` opens the file every time it is asked, and study 28's own Gloss already
admitted this would not do for a server. Hold the expenses instead, and measure the
difference.

Then falsify it, and the falsifier is free: `dart run bin/expenses.dart add 4.50 coffee`
in another terminal, against the same file. Not concurrency — a second **process** — and
the held copy is simply wrong. That is `files.mdx:119` paid in the words it was promised
in: it needs a reason to believe what it holds is still true.

**The second thing it is holding is a date.** `Tracker`'s `today` was captured at startup,
so a server started yesterday files today's expenses under yesterday. One transcript. The
fix is a clock, and study 28's *a signature is a promise about time* is the argument,
arriving where something depends on it.

Two kinds of stale state, one mechanism: a value read once is a bet that nothing else can
change it.

### 39 — The transaction that does not roll back · `transactions` · `ch39_expenses`

**Titled by the spike, which is what it was for.** `sqlite3` 3.5.2 brings durability, a
schema and a store that can keep a bound — and one measured trap that is better than all
three as a thesis.

`BEGIN`, `COMMIT` and `ROLLBACK` are plain `db.execute`; there is no transaction helper to
hide behind. A failing statement throws `SqliteException` carrying `message`,
`extendedResultCode` — 275 for a `CHECK` violation — and `causingStatement`, and it
**leaves the transaction open**: `db.autocommit` is `false` afterwards. It does not roll
back for you. Measured: catch the exception, commit anyway, and the partial write is
committed. That is a program that looks like it handled an error and did the opposite,
which is study 26's argument arriving with a database behind it.

It also sets up study 40 exactly: a transaction is the fix for the lost update, and a
reader who has just watched one fail to roll back will not take that fix on trust.

The parts that are already known: the build hook **downloads a prebuilt 3.53.4**, so it is
the same on every reader's machine and the prerequisite is **network on first build, not a
C compiler** — Book III prints that rather than letting study 39 discover it, and the
outline's earlier guess at a toolchain requirement is what the spike corrected.
`SqliteStore implements Store`. The
reader's existing `.jsonl` moves into a table, once; a schema that evolves twice is not in
this book. Study 38's cache is **deleted**, and why is the lesson — it existed because
reading a file meant reading all of it, and a database reads what you ask for. A cache you
can delete is the best ending a caching study can have.

And the bound becomes real. `Store` grows a bounded read, five implementations pay study
32's bill in public, and study 37's counting double now measures a difference.

**This entry is over budget on purpose.** Six subjects against a five-section envelope.
The spike decides what moves — `Store`'s growth into study 40 is the likeliest candidate,
since 40 is already arguing about what shape reads want.

### 40 — A second writer · `a-second-writer` · `ch40_expenses`

Name the machinery first, because everything else follows from it: an `await` on an
already-completed future resumes on the **microtask** queue, and that queue drains
completely before the event loop dequeues the next socket event. Concurrency in a
single-isolate server is not "two callers"; it is a real suspension in the middle of a
request. Parallelism is a different thing and is Book IV's — that is a promise this study
makes and the promise table will hold it to.

Then break something with it — and be exact about *what*, because the spike measured this
entry's first draft to be wrong. That draft said two requests both read the budget, both
find room, both record. Against `FileStore` that happens **11 times in 40** at concurrency
two, which is not a fact, it is a coin. The lesson is narrower and better:

**a lost update needs a suspension between the decision and the write.** A suspension
before the decision is harmless — every request resumes with the same answer, and the
first to resume runs decision-and-write to completion because nothing after the read
yields. Measured 30/30 both ways: suspend the *read* and one expense is recorded; suspend
the *write* and every concurrent request records. `FileStore` breaches only because
`record` touches a disk.

That is also what makes the study testable. A test that fires N requests at `FileStore`
and asserts a breach is flaky — 11/40, 32/40, 39/40 at two, three and four callers. A
store that suspends in `record` breaches every single time, so the transcript reproduces
and the test is not a coin. Study 32's aggregate is still the victim; a transaction is
still the fix; and `Tracker` is where a transaction boundary can be spoken about at all,
which is what study 36 was for.

**Then weigh CQRS and units of work, and expect to decline them**, the way study 34
declined `public_member_api_docs` after measuring it. ADR 0003 kept them out of Book II
because the tracker had no concurrency and promised the argument here, with a real
concurrent writer on the page. The argument is the study; the adoption is not the point.
If measurement says the tracker needs a unit of work, ADR 0005's *Predicted* list is what
was wrong, and it gets amended.

Closes Book III by returning to study 28: every member of `Store` is a `Future` because a
promise you can only keep in a CLI is a promise you should not have made in a CLI.

### Deliberately not in Book III

- **Isolates and real parallelism.** Book IV (41–45), per `PRODUCT.md`. Study 40 names the
  distinction and promises it, so this is a debt the promise table tracks.
- **Codegen** — `json_serializable`, OpenAPI generation. Book IV. The domain already has
  hand-written `toJson`/`fromJson` from study 29 and they are the better teaching artifact.
- **An ORM** (`drift`). Codegen, and it hides the schema study 39 exists to show.
- **Versioned schema migrations.** The one-time move of the reader's data is in; a schema
  that changes twice is a topic and nothing in these six studies changes it twice.
- **Deployment**, Docker, a hosting provider. Not Dart.
- **CORS and a browser client.** `PRODUCT.md` rules out in-browser execution.
- **WebSockets and server-sent events.** The tracker has nothing to push.
- **Authenticating a user.** `CONTEXT.md`'s *Deliberately absent* says there is no Account
  — one person, one file — so a user to authenticate does not exist. Study 37's shared key
  authenticates a caller and says so.

### Book III's inherited promises

Three sentences already printed on published pages bound this outline before it was
written. A fresh reader of `OUTLINE.md` alone would not find them.

| Printed at | The promise | Paid by |
| --- | --- | --- |
| `PRODUCT.md:66` | `dart:io` → `shelf` with `sqlite3`, reusing the CLI's domain package | 35, 39 |
| ADR 0004, *"inherits this decision"* | Packages carry the domain forward **by copy**, not by a `pubspec.yaml` dependency | 35 onward |
| `writing-good-dart/files.mdx:50` | Book III puts a server behind this same `Store` | 35 |
| `writing-good-dart/files.mdx:119` | The server reads once and holds on, and needs a reason to believe what it holds is still true | 38 |
| `writing-good-dart/budgets.mdx:219` | Book III puts a concurrent writer on the page | 40 |
| ADR 0003, *"Study 32 is where a real aggregate arrives"* | If Book III's API needs CQRS, units of work or transaction boundaries, that is where the argument gets made | 40 |
| `OUTLINE.md` (study 34) | `test/surface_test.dart` carries into Book III | 35 onward |
| ADR 0004, *"One consequence this record did not anticipate"* | A book whose packages are read as packages carries a `.pubignore` | 35 onward |

### Promises Book III makes to itself

Filled in from the written prose, never from this outline — the table exists to be
checked by `check_promises`, and Book II's had three rows that were fiction.

| Owed by | Made in | The reader is promised |
| --- | --- | --- |
| 37 | 36 | Routing, what an HTTP status *means* (study 26's taxonomy over a wire), and the refusal answering the limit as **data** so the edge stops going back for it |
| 38 | 36 | `bin/serve.dart` reads `Day.on(DateTime.now())` once in a program that does not exit, and a value read once is a bet that nothing else can change it |
| 39 | 36 | `Expense.toJson` survives the move into a database, which is why it is an extension on `Expense` rather than something `FileStore` owns |

`check_promises` distinguishes an empty table from a missing one and fails on the second.

Paid: 36←35 (the server could say only `recorded: N`, because every use case was private to
`command.dart` and `run` answered an `Outcome`; study 36 extracted `Tracker` and the server
answers the expenses).

**But nothing checks this table, and that must be fixed before study 35 ships.**
Measured while writing this section: `tool/check_promises.dart` hardcodes the heading
`### Promises Book II makes to itself` and reads pages only from
`web/content/docs/writing-good-dart/`. So the table above is invisible to it, and so will
Book III's prose be. It reports green today for a reason that will not last: Book II's
pages say *"Book III puts a server behind this same type"*, and the tool's pattern matches
`study 35`, not `Book III`, so no forward reference to this book has ever been counted.

This was the failure the tool's own comments describe — a check quietly switching itself
off — arriving by a route those comments did not anticipate.

**Fixed.** `check_promises` now finds tables by their **header row** rather than by a
heading somebody has to spell exactly, and reads every page under `web/content/docs/`;
study numbers are unique across books, which is what makes one page map enough. It went
from one table and 12 pages to **three tables and 34**, and both failure modes were proved
rather than assumed: delete every header row and it exits 1 saying nothing is being
checked; add a row naming a promise no page makes and it exits 1 naming the table and the
row. An empty table still reads differently from a missing one.

Finding all three tables immediately paid for itself. Book I's table was never read either,
and it held a genuine promise recorded only in prose — `extension-types.mdx` says *"Study
23 will show how to hide a constructor"*, which study 23 pays. It is now written `19→23`
where the tool can see it. Two notations had to be understood to do that: Book I writes
`15→16` and Book II writes `26←24`, and both mean the same thing with the arrow pointing
from the study that made the promise.

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
- **Book III adds a transcript of a program that does not exit**, and it is the
  one kind a person must not capture by hand. The command a reader types is
  `curl`, in a second terminal, against a server that is still listening, so
  there is no single command a checker can repeat. `tool/capture_server.dart`
  owns the whole scenario instead — entrypoint, seeded store, the commands to
  run — and starts the server, waits for a fixed readiness line, runs them, and
  writes the file. `--check` re-runs and compares; `check_transcripts` defers
  every transcript containing a `curl` command to it and counts those as
  checked rather than skipped.

  Two rules make that possible and both were earned. ADR 0005's *the server logs
  nothing time-varying* covers the server's own output — a fixed port, no
  timestamps. It does **not** cover HTTP's `date:` header, which is on every
  response and which nothing in this repository can switch off, so each header
  scenario's command ends in a `sed` that elides that one value. **The `sed` is
  on line 1 of the transcript, where the reader can see it and run it.** Eliding
  it inside the tool would produce the same bytes and a worse artifact: line 1
  is a command the reader can type, and a transcript normalised behind their
  back stops being one.

  A store is seeded as JSON lines rather than by running the CLI, because
  `expenses add` files an expense under *today*.

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
- **A test must pass on the reader's machine, not only on this one.** The transcript rule
  has always said output must reproduce; assertions are held to the same standard and were
  not. Study 29 shipped `expect(local.toUtc()…, isNot(local…))` — that `local.toUtc()`
  lands on a different *date* — which is true only where the offset from UTC is
  positive. At UTC itself and everywhere west of it the suite failed, from the day it was
  published. Sweep with
  `TZ=UTC dart test` and `TZ=Pacific/Kiritimati dart test`; exactly one test in 915 was
  machine-dependent when this was first run. Where a fact genuinely depends on where you
  stand, assert **the dependence** — the local form lacks the `Z` the UTC form carries,
  which is true everywhere — rather than the answer. The same applies to anything read off
  the host: a locale, a path separator, a clock.

- **`Also met:` is a list of claims, and it was written from intention.** The same defect
  as the promise table, found the same way and one audit later: study 8 told the reader
  they had met `values` and `entries`, and neither appears in `ch08_tally`, in any code
  on the page, or anywhere but that sentence. `dart run tool/check_also_met.dart` now
  checks every item against the study's package plus the **code** on its own page —
  backticks and fences with `//` comments stripped, because `// 2 — pairs, not values` is
  not the reader meeting `Map.values`, and because a claim cannot be its own evidence. It
  found two false claims in 116 across 31 lines.

- **A section reference like `19.5` is a claim that the section exists.** Swept once:
  `ch19_pence/lib/pence.dart` said "19.5 measures what it hands away" in a region shown on
  study 19's page, and study 19 stops at 19.4. Exactly one in the book, so this is a sweep
  rather than a tool — collect every `## N.M` heading and grep prose and `.dart` comments
  for `N.M` that is not one of them, discounting money (`12.5`) and versions.

- **An optional parameter no caller passes is a guess about a caller.** Study 36 shipped
  `Tracker.budgets([Period? period])` in its first draft, and nothing in the package, the
  tests or the exercises ever passed one — while `Tracker.expenses([Period? period])` beside
  it is passed one twice, which is what a parameter that has earned its place looks like.
  The cost of *not* having it is measured and near zero: an optional parameter can be added
  to a shipped signature without a single caller moving, which is the same mechanism ADR
  0002 records for a check arriving after a type ships. Sweep with
  `grep -rnoE '\[[A-Za-z<>?, ]+ [a-z][A-Za-z]*\]' code/*/lib`, which also matches **list
  patterns** — `('list', [final month])` in `command.dart` — so read the hits rather than
  counting them, and check each real parameter against a call site that passes one.
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
- **The sweep that finds a spent `<Practice>` was itself blind to four citations.** This
  file told Book III to regenerate the exclusion list with
  `grep -rhoE 'href="[^"]+"' web/content/docs/`. That finds the `<Practice href=…>` blocks —
  **30** of them across Books I and II — and it does not find a guideline cited in ordinary
  prose as a markdown link, `[**TEXT**](url)`, which carries no `href=`. Counting the URLs
  instead gives **34**. Four guidelines were therefore invisible to the sweep, and one of
  them cost a rewrite: study 27 cites *AVOID defining a one-member abstract class when a
  simple function will do* in prose, which is the single most apt guideline for study 35's
  argument, and study 35 chose it, verified it against the exclusion list, wrote the whole
  Practice, and only then found it spent.

  Sweep on the URL rather than on the attribute:
  `grep -rhoE 'https://dart\.dev/[^")>[:space:]]+' web/content/docs/ | sed 's/[.,)]*$//' |
  sort -u`, and after adding one, `sort | uniq -d` to prove no duplicate. The general form
  is worth more than the fix: **a sweep is only as wide as the syntax it greps for**, and
  a citation in this book has two spellings.
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
  `check_promises` never look at one. So the audit at `97f639e` — the pass that added
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
- **A checker that finds nothing must say whether there was anything to find.**
  `check_promises` printed *no promise table found* and exited 0, which was the same
  answer for a table with every promise paid and for a table somebody had deleted. Book
  II ended with the first, so the difference finally mattered. It now distinguishes them
  and fails on the second — proved both ways. Ask this of every new checker: what does it
  print when its corpus is empty, and is that different from what it prints when its
  corpus has gone missing?
- **A new snapshot starts by copying the last one, and `transcripts/` must not come with
  it.** Every other directory carries forward by design; `transcripts/` does not — each
  study holds only the runs it captured, and `check_slices` skips the directory on purpose,
  so an inherited transcript is invisible to every checker. Study 33 was copied from study
  32 and arrived holding `interface.txt`, `mock.txt` and `refused.txt`, all of them study
  32's evidence for study 32's claims. Delete them before writing the first new one, and
  compare `ls chNN/transcripts` against the previous study's if in doubt.
- **A rule enforced at two edges belongs on the type between them.** `Limit` refused a
  zero amount in the `budget` command and again in `limitFromJson`, and permitted it
  itself, so the program could construct and store a limit it could not read back. When
  the same condition is written in two places, neither of them is the owner — ask which
  single type can see the whole condition, and put it there. Adding the check later is
  free: a factory takes the unnamed constructor slot and no caller moves. This is the
  companion to the `==` requirement above; both are questions to ask of a value type the
  moment it exists.

  **It recurred in study 36 with a layer rather than a second edge, and an audit found it
  rather than construction.** `Tracker.record` decided whether an unacknowledged breach
  stops the write, and `command.dart` decided the same thing again to decide what to
  report: two copies of `verdict is Breach && !expense.acknowledged`, one in the layer and
  one at the edge, and study 37 would have written a third to choose a status code. Neither
  copy was wrong and the suite was green both ways, which is why no checker saw it. The fix
  is `refuses`, an **extension on `Verdict?`** — nullable on purpose: extension methods are
  dispatched statically, so a `null` verdict reaches it and no caller writes `?? false`. A
  plain method on `Verdict` would have pushed that decision back out to every call site,
  which is the same duplication one layer down.

  **The general form is worth more than either instance: extracting a layer does not remove
  a duplicated rule, it creates the second copy.** The rule was written once in study 35
  because there was one caller. Adding a caller is precisely the event that turns a
  single-use condition into a shared one, so the moment to sweep for this is the moment a
  second caller arrives — not later, when there are three.
- **Book II only — the domain never holds a `DateTime`.** Measured: for one
  instant `local == utc` is `false` while their hash codes are equal,
  `toIso8601String()` drops the offset, and `DateTime(2026, 2, 31)` is the 3rd of
  March. `Expense` carries a `Day`. Instants live at the edges only.
- **A count of *studies* is a claim, and the count sweep has never read the corpus that
  proves it.** The existing count requirement above sweeps for lines, exports, types and
  members — things that live in `code/`, where a grep can settle them. A sentence that
  counts *studies* is settled by the pages instead, and nothing was reading them. Both
  instances were in studies 33 and 34, the two the audits had never reached: "study 1's
  argument, arriving at its conclusion **twenty-three** studies later" on study 34's page,
  where 34 − 1 is thirty-three; and "`package:args` replaced a parser **three** studies had
  apologised for", where two did — study 24, which wrote it, and study 32, which built on
  it and said so twice. Study 28 mentions the parser and is not a third: it says the parser
  *did not have to be rewritten* to go async, which is praise. Sweep by grepping the pages
  for the thing being counted, not by remembering it — an apology and a mention read the
  same from memory and do not read the same on the page.
- **A measurement of a race is a sample, not a fact, and this book's whole method is built
  on the opposite assumption.** Every other requirement here says *run it and write down
  what happened*. That is sound because everything measured so far has been deterministic:
  a lint fires or it does not, `DateTime(2026, 2, 31)` is the 3rd of March every time. A
  race is not like that, and the method quietly breaks.

  Found in Book III's spike, which measured a lost update against `FileStore` at 11/40,
  32/40 and 39/40 for two, three and four concurrent callers, and wrote all three into this
  file as measured facts. Re-running the identical experiment twice more gave 10/40, 20/40,
  17/40 and then 4/40, 7/40, 27/40 — not even monotonic in concurrency. Before that, six
  consecutive clean runs at two callers had nearly established "two callers are safe" as a
  rule. The same trap one level down: the *verdict* of an interleaving test was stable 5/5,
  and the *trace* was not, because which request wins varies — and a trace had been printed
  as the result.

  So: **a number sampled from a racy process may only be published as evidence that the
  variance exists, never as the answer.** Before writing any measurement down, ask whether
  re-running it could give a different number. If it could, either find the deterministic
  version of the experiment — the spike's was moving the suspension from the read to the
  write, which went from a coin to 30/30 across 90 trials — or print the variance and say
  plainly that the rate is not a property of the program. A transcript of a race is a
  transcript that fails on somebody's second run, which is the one thing
  `check_transcripts` exists to prevent and cannot catch here.

- **A comparison is only as honest as what it leaves out.** The same spike printed
  *18 lines against 11* for a hand-rolled server against `shelf`, and the two were not
  doing the same work: the `shelf` version returned a `Handler` and still needed the
  `serve` call the raw one already contained, while the raw one hand-wrote a 404 that
  `Router` gives away. The number was not wrong; the sentence around it was. State what the
  losing side had to do that the winner did not, in the same breath as the count.

- **A line number into a record that gets amended is a citation that rots, and an ADR is
  designed to be amended.** Found while outlining Book III, and self-inflicted: the Book III
  section cited `docs/adr/0004:134-140` for the `.pubignore` commitment, then an amendment
  to that same ADR — nine lines, added in the same session — pushed the paragraph to 146 and
  left the citation pointing at the amendment itself. `0004:124-127` survived only because
  the insert happened to land below it, which is luck rather than method. Cite an ADR by a
  distinctive phrase from the paragraph instead, and check the phrase matches exactly once:
  the first attempt here quoted *"Book III inherits this decision"* and matched nothing,
  because the real sentence reads *"Book III (studies 35–39) inherits this decision"* — a
  range the amendment deliberately left stale. Line numbers into `.mdx` pages are a smaller
  risk and are kept, because a published page is frozen in a way a record is not.

- **`OUTLINE.md`'s own `Shipped:` lines are claims, and no checker has ever read them.**
  The count requirements above sweep `code/` with a grep and the pages with another; this
  file is the corpus neither of them looks at, and it is the one every session reads first.
  Swept for the first time while outlining Book III: nine `Shipped:` lines, and **six
  carried a wrong number**. Git separates two different faults, and the distinction is the
  useful part:

  Five were **wrong on the day they were written** — studies 25 and 26 claimed eight
  transcripts over seven, 31 claimed five over six, and 33 and 34 each claimed seven over
  nine. Every transcript in those packages was added in the single commit that wrote the
  study, so nothing was added afterwards; the number was written from an impression of the
  work while doing it. Corrected.

  Four **drifted after publication**, which is the opposite fault and has a cause worth
  stating exactly: **every one of them drifted because the book audited itself.** Study
  23's transcripts went from eight to ten when `4528c90` — *two claims with no run behind
  them* — added `generative.txt` and `offer.txt`. Studies 24, 25 and 26 gained tests from
  `25ecdfa`, `f6df067` and `ab840c9`, three audit passes whose whole purpose was to make
  unasserted claims executable. Not one of these was a mistake being repaired; each made
  the book more true and falsified a `Shipped:` line as a side effect. Also corrected.

  These are **not** the three retroactive fixes ADR 0004 records — those are a false doc
  comment spanning three snapshots, a machine-dependent test spanning one, and an inverted
  sentence in `Report.of` spanning two, all from the studies 30-32 era. An earlier draft of
  this requirement asserted that linkage from plausibility rather than from the log, which
  is the same fault it was written to describe.

  **A `Shipped:` line describes the package as it stands, not the commit that wrote it.**
  That is the ruling, and it is the reading that makes the line checkable: count the files
  in `transcripts/`, run `dart test test/`, compare. The historical reading would have been
  defensible — these entries are called the record of what construction measured — but it
  makes a stale number and a correct one indistinguishable without running `git`, and the
  drift is worth seeing rather than excusing. A snapshot is supposed to be written once and
  never edited; where a `Shipped:` count has moved, this file is recording the one rule the
  layout has actually broken, and that is information rather than noise.

  The fix was a seventh checker rather than a sweep, and it exists:
  `dart run tool/check_shipped.dart` counts the files in each study's `transcripts/` and
  runs that package's own suite. It reports **9 lines agreeing and 20 entries stating no
  count**, because a study that states no number cannot have a stale one — studies 27, 28
  and 29 among them, so that case was never hypothetical. Finding *no* lines at all fails,
  which is the difference between an empty corpus and a missing one. Both proved: removing
  every `Shipped:` line exits 1 saying nothing is being checked, and re-introducing study
  34's original wrong number reproduces the defect exactly — *claims 7 transcripts,
  `ch34_expenses` holds 9*.

  It is slow, for the same reason `check_transcripts` is: it runs a suite per claim.

- **An ADR's "therefore" is a separate claim from its premises, and it decays on its own.**
  ADR 0003 said `avoid_slow_async_io` is not in the lint set and argues the opposite for
  `exists` — both still true, re-measured — and concluded that study 28's `<Practice>`
  therefore carries no attribution. The shipped page cites *DO use `Future<void>` as the
  return type of asynchronous members that do not produce values*, which is about a return
  type rather than about async versus sync. The record had reasoned from *no lint for this
  argument* to *nothing to cite* while the study was still unwritten, and writing it found a
  different guideline. Check an ADR's consequences against the artifact, not against its own
  premises: a consequence written before the work is a prediction, and this book's method is
  to prefer the measurement.
- Deliberately-broken code that fails to **compile** cannot live in `lib/`: it
  would put the workspace analyze above zero and contradict study 1's Practice.
  Capture its transcript from a temporary state and inline the code in the MDX
  (study 8 does this). Code that fails at **run time** may stay as a real file
  (study 7's `bin/frozen.dart`, study 9's `bin/bang.dart`), which is better —
  the transcript stays reproducible by just running it.
