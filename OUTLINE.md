# Outline — Book I: Foundations (studies 1–22)

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
| 19 | `generics.mdx` | a type that exists for the compiler and disappears before the program runs |
| 20 | `control-flow.mdx` | errors as the run-time answer to bad input, against `assert` for programmer mistakes |

Paid and verified: 2→6 (enum kills the stringly-typed parameter), 3→7
(`final` list vs `const` list), 7→12 (the shorter way to sum, needing
closures), 8→9 (the question mark), 10→11 and 10→12 (functions named, then
the loops deleted), 12→13 and 12→14, 13→14, 3→15 (`const` constructors),
13→15 (name, methods, invariants), 6→16 (enums with fields and methods),
14→16 (`sealed` closes exhaustive switching).

---

## To write

Studies 4-18 are written and committed; their entries below are kept as the
record of what was intended, and each study's own commit message records what
construction actually measured. **Study 19 is next.**

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
- **Operator overloading.** Book IV.
- **Isolates, FFI, codegen, performance.** Book IV (40–44), per PRODUCT.md.
- **Enhanced enums.** Folded into 16, once classes exist.
- **`package:checks`.** Mentioned once, never taught, per PRODUCT.md.

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
- **File names by role**: `undefined.txt` (red, nothing exists yet), `pass.txt`
  (first green), `all.txt` (the study's full suite), `challenges.txt` (the
  deliberately-failing exercises). Topical ones are named for what they show —
  `const-runtime.txt`, `generated.txt`, `hello.txt`.

## Standing requirements for every study

- Prose in `web/content/docs/foundations/<slug>.mdx`; code in a real package at
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
- Add the slug to `web/content/docs/foundations/meta.json`. A study that is not
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
- One `<Practice>` per study. When it carries an attribution it must be a real
  link the writer has opened: `<Practice source="Effective Dart — Usage"
  href="https://dart.dev/…">`. The candidate rules named above are starting
  points, not citations. A Practice with no citable source omits both props
  rather than inventing one — study 2 does exactly that.
- Deliberately-broken code that fails to **compile** cannot live in `lib/`: it
  would put the workspace analyze above zero and contradict study 1's Practice.
  Capture its transcript from a temporary state and inline the code in the MDX
  (study 8 does this). Code that fails at **run time** may stay as a real file
  (study 7's `bin/frozen.dart`, study 9's `bin/bang.dart`), which is better —
  the transcript stays reproducible by just running it.
