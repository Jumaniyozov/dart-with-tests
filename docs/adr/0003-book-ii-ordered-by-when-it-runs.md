# Book II is ordered by when the reader can run it

Book I's order was forced by the language: iterables cannot precede functions, null
safety cannot precede maps. ADR 0001 is a record of hard dependencies.

Book II has almost none. By study 23 the reader has the whole language, so nothing in
studies 23–34 is pinned by a missing feature. What orders them instead is **when the
reader first has a program they can run**, and every later study changes a program that
already works.

The reader types `dart run` and sees output in study 24 — the second study of the book.

| # | Title | The mechanism to name |
| --- | --- | --- |
| 23 | Libraries, imports and privacy | Privacy is a property of the file |
| 24 | A program that runs | Exit code and stderr are the CLI's return value |
| 25 | Values and entities | Equal hash codes do not mean equal objects |
| 26 | Errors: thrown or returned | `assert` is stripped; typed input needs a throw |
| 27 | Testing without mocks | A seam is an interface you own |
| 28 | Files | Reading a file is a Future, and sync is the exception you argue for |
| 29 | JSON | A local `DateTime` serialises without its offset |
| 30 | Dates, times and periods | `DateTime` is an instant; a calendar day is not |
| 31 | Reports | `Comparable` and `operator +`, earned by totalling |
| 32 | Budgets | A rule no single object can check |
| 33 | Taking a dependency | What a caret constraint promises you |
| 34 | Being a dependency | What a caret constraint promises your callers |

Studies 33 and 34 are the same idea from both ends, and 34 closes Book II by returning
to study 23: `lib/` against `lib/src/` is a package's public surface, and a version
number is the promise made about it.

## Three debts taken on purpose

Book I's method — show the worse tool, name the study that replaces it — is how Book II
keeps a runnable program from study 24 without lying about it. Each of these is a
sentence in the earlier study, not a silent handover.

- Study 24's argument parser is hand-rolled. Study 33 replaces it with `package:args`.
  **Amended: study 32 added to it rather than only waiting.** `--anyway` cannot be matched
  by the list patterns without being swallowed by `...final note`, so it is stripped
  first, in a `_flagged` function that exists to be deleted. The debt got larger before it
  got paid, and study 32 says so on the page.
- Study 28 writes one expense per line. Study 29 replaces it the first time a note
  contains a comma.
- Study 25's `Store` is a concrete class. Study 27 turns it into an interface so a fake
  can stand in for it.

The third is the one to watch, because it is an abstraction arriving late rather than a
tool being upgraded. It is deliberate: an interface introduced in study 25, before any
second implementation exists, is machinery the reader cannot yet evaluate.

## Considered options

- **Domain first, I/O last** — the whole domain modelled and tested, then `dart:io`,
  JSON and the CLI shell at 31–34. This mirrors Book I's nouns-first spine and keeps the
  domain airtight before it touches a disk. Rejected: ten studies before the reader can
  invoke anything. For a book whose stated purpose is building real software, that is a
  long time holding a library nobody can run, and it gives up the before-and-after
  transcript that this book's format is built on.
- **Persist early** — `args`, then `dart:io`, then JSON, then the domain. Fastest route
  to a genuinely useful tool. Rejected: the reader writes serialisation against a model
  that the domain studies then change underneath it, so the JSON study is stale by the
  time it matters.
- **One study per CLI command** — `add`, `list`, `report`, `budget`. Rejected for the
  reason ADR 0001 gives for rejecting the classic type tour: it lets feature order
  dictate teaching order, which is how the v1 book put iterables before closures.

## Consequences

**Book II is the reader's first contact with `dart:io` and `dart:convert`.** Verified:
no package in studies 1–22 imports either. Everything about files and JSON is new
ground, which is why they get two studies rather than one.

**`async` returns after five studies away.** Studies 21 and 22 taught futures and
streams; nothing in 23–27 needs them, and `grep -rl 'async\|await'` over their packages
returns nothing. Study 28 brings them back, because `dart:io`'s file API is asynchronous
first and the synchronous forms are the exception. That gap is acceptable — but the study
must reintroduce rather than assume. **Amended: this said "eleven studies away" while the
same sentence named the five that skip it. Measured, the gap is 23, 24, 25, 26 and 27.**

**Study 28 cannot cite a lint for preferring async I/O.** `avoid_slow_async_io` is not
in `package:lints/recommended.yaml`, and it argues the opposite for `exists` and `stat`.
That study's `<Practice>` therefore carries no attribution, the way study 2's does.

**Amended when the study was written: the premises held and the conclusion did not.**
Both halves of the sentence above re-measured true — `avoid_slow_async_io` is still absent
from `package:lints/recommended.yaml`, and its own documentation still resolves the
diagnostic by replacing `exists` with `existsSync`. What was wrong was the step between:
*no lint for preferring async I/O* was read as *nothing to cite*, and those are different
questions. Study 28 cites **DO use `Future<void>` as the return type of asynchronous members
that do not produce values** (Effective Dart — Design), which is not about async versus sync
at all. `record` produces nothing; the reason it is not `void` is that the caller might need
to `await` it, and with plain `void` the caller could not.

Four studies in this book carry a `<Practice>` with no attribution — 2, 24, 30 and 32 — and
28 is not among them. The three in Book II each say on the page why they cite nothing, which
is the form this record should have predicted: a guideline *this record* could not find is
not a guideline *the study* could not find.

**Operator overloading moves from Book IV to Book II.** Study 25 overrides
`operator ==`, so the book teaches operator overloading whether or not it admits to it.
Study 31 owns it properly, where totalling makes `Money + Money` the obvious thing to
want. `OUTLINE.md`'s "Deliberately not in Book I" list is amended. **Amended again: it
takes two studies, not one.** `+` is total and lands in 31; `-` on a non-negative type is
partial, and a `Money?` whose `null` means nothing would teach the syntax and not the
lesson. It waits for study 32, where `null` is an overspend and the caller has a decision
to make about it.

**`DateTime` is kept out of the domain entirely.** Measured on Dart 3.13.2: for the same
instant, `local == utc` is false while `local.hashCode == utc.hashCode` is true;
`DateTime(2026, 9, 9).toIso8601String()` emits no offset; and `DateTime(2026, 2, 31)`
silently yields the 3rd of March. **Amended when study 30 was written: `DateTime.parse`
does not validate either** — `2026-02-31` parses to the 3rd of March — which is the
version of this that reaches a file, and the reason `Day.parse` answering `null` is
load-bearing rather than fastidious. An `Expense` therefore carries a `Day`, and instants
live only at the edges — `bin/expenses.dart` reads one, `Day.on` converts it, and study
30 explains why. **Amended: this said "study 27's injected clock", and study 27 does not
have one.** Writing it settled that a `Clock` interface, a `SystemClock` and a
`FixedClock` are three types where `run(args, store, today)` does the job, and that the
guideline against them is *AVOID defining a one-member abstract class when a simple
function will do*. The seam is the parameter.

**`Money` is non-negative, which breaks with study 19 on purpose.** The tracker records
money out, so every entry has the same direction and the number needs no sign. Study
19's `Pence` carried direction in its sign (`isDebit => isNegative`) because it had no
program to give direction a home; Book II has one. The gain is that `Money` gets an
invariant simple enough to state in a line — `pence >= 0` — which is what study 23's
hidden constructor exists to enforce and what study 26's thrown-versus-returned rule is
first spent on. A signed `Money` would leave study 23 with nothing worth hiding.
Refunds are therefore out of scope, and Book II says so rather than pretending.

**A budget refuses rather than warns, and that is what makes it an aggregate.** A
warning is a query over expenses: it computes a number and prints it, and nothing is
prevented. Only a refusal is an invariant, and only an invariant needs a consistency
boundary. Software that refuses to record what a person actually spent would be lying
about their money, so the escape is in the domain rather than in a flag the code
ignores: an acknowledged overspend is a distinct, representable thing, and only the
*unacknowledged* breach is refused. The rule holds and the program stays true.

**Study 32 is where a real aggregate arrives, and it is the only one.** Every other
invariant in the tracker belongs to a single object. A budget's limit is the one rule
that needs several objects at once, so it is the one place the book can teach a
consistency boundary as mechanism rather than as architecture folklore. Command and
query separation, units of work and transaction boundaries stay out of Book II: they
solve concurrency the tracker does not have. If Book III's API needs them, that is where
the argument gets made, with a real concurrent writer on the page.

**All three debts are paid, and the third one cost more than it looked.** Study 33 took
`package:args` 2.7.0 and deleted the hand-rolled parser, `_flagged` with it. Study 28's
`const` path in `bin/` became `--file`. Two of the three arrived exactly as promised.

The one that did not is study 24's word *abbreviations*. Measured on `args` 2.7.0: there are
single-letter abbreviations, declared with `abbr:`, and there is no unique-prefix
abbreviation at all — `--fi` for `--file` throws, and so does `--hel` for `--help`. The
promise was written before anyone had run the package. It is paid in the smaller sense and
study 33 names the gap rather than letting one word cover both readings.

**Taking the dependency changed the program's behaviour, and that is now part of Book II's
argument rather than a footnote.** `package:args` reads a leading `-` as an option, so
`add -5 food coffee` — study 24's example of a *refusal*, exit 1, as against a *misuse*,
exit 2 — became a misuse. Measured: exactly one test of 165 failed when the dependency went
in, and it was that one. There is no setting for it. `--` restores the old behaviour at the
cost of two characters the reader has to know about.

That is worth recording here because it is the first time an outside decision has reached
into this book's own teaching. Study 24's page is still true of `ch24_expenses`, which has
its own parser and always will; what changed is the program from study 33 onwards. A
snapshot layout (ADR 0004) is what makes that statement possible: the earlier study did not
become wrong, it became earlier.
