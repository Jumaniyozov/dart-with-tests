# Book I study order follows dependencies, not the classic type tour

Book I teaches the language in a "nouns first" order — numbers, strings, enums,
collections, then flow, then objects, then async — but two studies sit where a
reader of other Dart books would not expect them, and both placements are
deliberate.

**Null safety is study 9, after maps, not with the types.** Numbers, strings,
enums and lists can all be taught with no nullable type on the page.
`map['missing']` returns `V?` and cannot be dodged. The analyzer is a character
in this book — study 1's whole argument is *read the error* — so the study where
its message first says `int?` is the study that must explain it. Teaching null
earlier means teaching a tool before the reader has felt the problem; teaching
it later means four studies of code written to avoid its own honest shape.

**Iterables are study 12, after functions, not with the collections.**
`list.map((x) => x * 2)` needs function literals. The v1 book put the Iterable
pipeline in the collections group and closures two sections later, which is
backwards. This is a hard dependency, not a preference.

## Considered options

Two orderings were rejected, and both will be suggested again by anyone reading
the outline cold.

- **The classic tour** (v1's shape, and most Dart books'): all the types, then
  flow, then functions, then objects. Rejected because it inherits the iterables
  inversion and pushes null safety to ~12, behind four studies that would have
  to dodge it.
- **Functions first, at study 4.** Rejected because the reader has no
  interesting data yet, so every example collapses to `int add(int a, int b)`.
  The argument for it — that studies 2 and 3 already use `=>` and named
  parameters without teaching them — does not hold: light-use-then-deepen is the
  book's established method, not a debt.

## Consequences

Studies 6 and 7 use `switch` and `for-in` before study 10 formalises them. This
is accepted and consistent with how studies 2 and 3 already work.

Functions are not taught until study 11, although the reader has been writing
them since study 2 and meets `=>`, named parameters and defaults in passing long
before that. This is the cost of choosing nouns first, and it was the rejected
spine's strongest argument. Accepted: light-use-then-deepen is how studies 2 and
3 already work, and a functions study at slot 4 would have had no interesting
data to work on.

Studies 4 to 9 have since been written against this order, and two things
confirmed it. Maps really cannot be taught without `int?` — and more sharply
than expected, because `containsKey` does not promote, so the obvious workaround
fails with the same error one line lower. Study 8 does borrow `??` from study 9
for a single line, flagged in the prose; that is the largest forward loan in the
book so far and the place to look first if this ordering is ever revisited.

Studies 10 to 14 have since been written too, and the second decision held up
under load. Study 12 cannot be moved before study 11: `fold`, `where` and
`firstWhere`'s `orElse` all take function literals, and `firstShared` reaches
for a method tear-off, which is study 11's machinery by name. Study 14 cannot
be moved before 13 either — its `Command` *is* a record, and its switch
destructures one.

A new structural dependency arrived with study 12 that is stronger than a
forward reference. Its opening transcludes study 10's own loop out of
`ch10_ledger/lib/ledger.dart` and sets `fold` beside it, so the two studies are
joined by an include path rather than by a sentence. That makes the deletion
impossible to fake and impossible to let drift — and it means moving either
study breaks a build, which is the good kind of coupling.

Studies 10 to 14 added no new forward loans. Study 8's borrowed `??` is still
the largest in the book.

Studies 15 to 18 have since been written, and the object block held together in
the order the outline pinned. Study 16 genuinely needs both 15 and 14 — its
subclasses are primary-constructor classes and its switch uses object patterns.
Study 17 needs 16 to contrast against, and its `on` clause is only explicable
once `extends` is. Study 18 needs 15, and it also reaches back to 9: the reason
an unbounded `T` cannot be compared is that `T extends Object?` is nullable, so
the error is study 9's and not a generics error at all.

One decision inside that block grew large enough to deserve its own record.
Primary constructors as the default class syntax is now ADR 0002.

Study 19 has since been written, and it turned out to be pinned harder than the
outline guessed. It needs 18, but not for generics machinery: 18.3 proves a
generic class carries its type argument into run time, and 19.3 is the same
question asked of an extension type with the opposite answer. Read apart they
are two facts; read in order they are one argument, and the order is the
argument. It needs 15 for the class it is measured against and for the rule
that a declaration with no initialiser list cannot check anything — a rule
first drawn for primary constructors and reused unchanged for a second
declaration form. It needs 4, whose "hold pence in an int" is the convention it
finally makes enforceable. And its `Iterable<Pence>` extension is study 12's
`fold` given a receiver.

Study 19 also makes the first forward reference into Book II: hiding a
constructor needs privacy, which opens at study 23. That is recorded as a debt
rather than paid, because nothing in Book I can pay it.

Study 20 has since been written and paid three promises at once — from 10, 15
and 19 — which were all the same promise made three times: bad input is a
run-time fact and needs a run-time answer. That they converged is a point in
the spine's favour. It also confirmed the dependency the outline recorded, but
by a route the outline did not guess: study 20 needs 15 not only to define an
exception type but because its own toy is built out of study 14's switch, study
13's record and study 9's `tryParse`, and the interesting sentence in the study
is that `tryParse`'s `null` and a thrown `FormatException` are the same
decision made two ways. A study 20 placed before 9 would have had nothing to
compare against.

Study 21 has since been written and is the strongest confirmation of the
20-before-21 order in the book. Its central lesson is not that async code
needs new error handling — it is that study 20's error handling is *unchanged*
and still works, because `await` puts the failure back inside the `try`. That
sentence cannot be written before study 20 exists, and the study that follows
it is left with only one thing to teach: what happens when the `await` is
missing. Reversing the two would turn one lesson into two weaker ones.

Study 22 has since been written and Book I is complete. The spine held. The
last study needed three earlier ones at once and got all three where it wanted
them: study 12 for the verbs (`where`, `take`, `fold` mean the same over a
stream), study 21 for the waiting, and study 20 for the failure. Its own new
material reduced to a single rule — one pass, only once — which is what a
closing study should look like.

The one ordering claim this ADR made and never tested is now testable and
holds: nothing in studies 15-22 wanted a nullable type before study 9, a
function literal before 11, or a class before 15. No study was moved after
being written, and study 3's mis-aimed forward reference (corrected early) is
still the only promise in the book that ever pointed at the wrong number.

Reordering after several of these studies are written is expensive, because the
studies carry forward references to each other by number — a published Gloss
that says "Study 7" is a contract with the reader. One such promise was already
found pointing at the wrong study and corrected. Every promise still outstanding
is now tabulated in `OUTLINE.md`, so the cost of a reorder can at least be read
off rather than rediscovered.
