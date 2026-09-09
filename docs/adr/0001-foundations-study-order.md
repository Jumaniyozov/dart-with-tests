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

There is no arithmetic study until 4 and no numbers depth until 11, which is
unusual for a beginner book. Accepted: `int` and `count++` appear from study 3.

Reordering after several of these studies are written is expensive, because the
studies carry forward references to each other by number — a published Gloss
that says "Study 7" is a contract with the reader. One such promise was already
found pointing at the wrong study and corrected.
