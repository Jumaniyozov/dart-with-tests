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

Reordering after several of these studies are written is expensive, because the
studies carry forward references to each other by number — a published Gloss
that says "Study 7" is a contract with the reader. One such promise was already
found pointing at the wrong study and corrected. Every promise still outstanding
is now tabulated in `OUTLINE.md`, so the cost of a reorder can at least be read
off rather than rediscovered.
