# Book III is ordered by when the reader can call it

ADR 0001 records Book I's order, which the language forced. ADR 0003 records Book II's,
which nothing forced except **when the reader first has a program they can run** — `dart
run` works in study 24 and every later study changes a program that already works.

Book III inherits that move and changes one word. Its spine is **when the reader can
call it**: study 35 answers `curl`, and every later study changes a server that already
answers.

The word matters because a server fails differently from a CLI. A CLI that is wrong
prints the wrong thing and exits. A server that is wrong keeps running, holding something
that stopped being true, answering a stranger who is still waiting. Every study in this
book is a thing the CLI was right to do and the server is not.

| # | Provisional title | The mechanism to name |
| --- | --- | --- |
| 35 | A server that answers | `shelf_io.serve` returns a `dart:io` `HttpServer`; a `Handler` is a function |
| 36 | A second edge finds what the first one hid | A seam cut for testing turns out to be a layer |
| 37 | The caller is a stranger | A thrown `Error` is a 500 — and `shelf_io` already answers one, so the middleware is about shape and reporting |
| 38 | The server holds on | Held state has two halves, and the date is the one you forget |
| 39 | The transaction that does not roll back | A failing statement leaves the transaction open, and does not undo it |
| 40 | A second writer | `await` on a completed future resumes on the microtask queue |

**The titles are provisional and the numbering is not.** Book II's two best studies —
33 and 34 — got their theses from measurement rather than from this file's ancestor:
study 33's argument appeared when `package:args` silently changed one test of 165, and
study 34 turned on `public_member_api_docs`, read 22 issues, and declined the lint on the
page. See *Consequences*, which says the same thing about this record's own claims.

**Study 39's row was left blank until the spike filled it in, and that worked.** Naming it
in advance would have been a prediction about `sqlite3` made before anyone ran it. What the
spike found is better than the two candidates this record would have guessed: `BEGIN` and
`COMMIT` are plain `db.execute`, and a failing statement throws while **leaving the
transaction open** — catch it, commit anyway, and the partial write is committed. A study
about a database that begins with an error-handler that did the opposite of what it looks
like is study 26's argument with something underneath it. The method is now used once and
worth repeating: leave a row blank rather than filling it from expectation.

## Book III costs a sixth study, and the sixth was bought rather than found

`PRODUCT.md` said five, 35–39. Outlining found six, so Book IV is now 41–45 and the book
is 45 studies. That is a real cost, and it was paid deliberately rather than by letting a
study run long. Every file that stated the old shape: `PRODUCT.md`, `HANDOFF.md`,
`OUTLINE.md`, `DESIGN.md`, ADR 0004, and `web/src/app/(home)/page.tsx`,
`web/src/app/layout.tsx` and `web/src/app/docs/layout.tsx` — the last two in comments,
which is where a stale number survives longest because no reader ever sees it.

Sweep for the next one with `grep -rnE "44|forty-four|35–39|40–44"` over `*.md`, `*.mdx`
and `*.tsx`, discarding `node_modules/`, lockfile hashes, SVG path data and hex colours,
all of which match the digits and state nothing.

What forced it was an arithmetic, not a preference. Every study in Book II is **4 or 5
numbered sections and 1535–2489 words**, twelve of twelve, which makes six studies a
budget of 24–30 sections. The subjects Book III already owes, before anything optional:
a server, an application layer, an HTTP surface, a cache, a database, and a concurrent
writer. Six subjects, and the fifth-study version of this book had two of them sharing.

The sixth study splits what was one: extracting the application layer (36) and putting an
HTTP surface on it (37) are different arguments, and merging them buried the first.

## Three commitments this book did not choose

Each is a sentence already printed on a published page. They bind Book III, and the
alternative to honouring them is amending the page that made them, not ignoring it.

- `writing-good-dart/files.mdx:50` — Book III puts **a server behind `Store`**, the same
  interface study 28 wrote. Study 28's argument for making every member a `Future` was
  explicitly that *a server that blocks on a disk stops answering everybody*, so this book
  is the thing that argument was made for. Paid at 35.
- `writing-good-dart/files.mdx:119` — the server **reads once and holds on**, and needs a
  reason to believe what it holds is still true. Paid at 38.
- `writing-good-dart/budgets.mdx:219` — Book III puts **a concurrent writer on the page**,
  and ADR 0003 adds that CQRS, units of work and transaction boundaries were kept out of
  Book II *because the tracker has no concurrency*, so this is where that argument gets
  made. Paid at 40.

## Considered options

**Ordered by what a second caller breaks.** Concurrency as the organising force rather
than the finale: each study takes something correct for a lone process and breaks it with
a second caller. Rejected because the reader cannot feel the problem until there is a
server worth calling twice, and because it front-loads the book's hardest argument.

**Ordered by how far the promise travels** — the widening gap between the code and a
caller who cannot be trusted. Rejected as a spine and **kept as study 37's thesis**, which
is where it was always strongest.

**A separate `api` package depending on the domain package.** The literal reading of
`PRODUCT.md`'s "reusing the CLI's domain package". Rejected because ADR 0004 rules out the
`pubspec.yaml` edge, and because the alternative is better: one package with two
entrypoints means `check_slices` *proves* the domain files are untouched, so the reuse
claim stops being narrative.

**Deleting the CLI at study 35.** Rejected twice over. It opens the book with a deletion,
and it throws away the demonstration — the same domain answering two edges with not one
line of it changing. It would also have cost study 38 its second writer, which is the CLI
writing the same file from another terminal: free, real, and reproducible in a transcript.

## Consequences

**Marked, because ADR 0003 was amended for exactly this.** That record reasoned from *no
lint supports this argument* to *study 28 will cite nothing*, and study 28 cites
something. A consequence written before the work is a prediction. The list below is split
on that line, and the second half is to be checked against the artifact rather than
against this record's premises.

**Decided.** These are choices, and changing them means amending this file.

- Packages are `ch35_expenses` … `ch40_expenses`, each a copy of the last plus its slice,
  per ADR 0004. `ch35_expenses` is `ch34_expenses` plus a server. The CLI survives.
- `.pubignore` and `test/surface_test.dart` carry forward from study 34. A contract nobody
  checks is one that drifts, and Book III adds a second thing to the surface.

  **Amended while writing study 36: the surface was bigger than the test.** This bullet
  assumed the only question was *what else gets exported* — `Tracker` does, the server does
  not, and `surface_test` reads the barrel. It does. But study 36 **deleted**
  `bin/by_hand.dart`, and `dart run ch35_expenses:by_hand` was something a caller could do,
  so that is a breaking change and nothing noticed. `surface_test` gained a `#runnable` group
  holding `bin/` to a declared list, and the package is `2.0.0`. The general form, recorded
  in ADR 0004 as well: a contract test protects exactly the surface it was written about.
- `CONTEXT.md` gains exactly one term, **Tracker**, and no others. If Book III needs a
  second domain word, something has leaked from the edge into the domain, and that is a
  defect to find rather than a glossary entry to write.
- `Tracker` is exported from the barrel; the server is not. `Tracker` names no `shelf`
  type, and study 34's whole lesson is what a dependency's types in a public API cost.
- **The server serves from `FileStore` from study 35, and the lost update is a declared
  debt paid at 40.** Decided after the spike. The alternative — an `InMemoryStore` until
  study 38 — shares no data with the CLI, so a reader who adds an expense on the command
  line and then calls `GET /expenses` gets an empty list, which breaks the demonstration
  the CLI was kept for and costs study 38 its second writer. Book III therefore has one
  debt where Book II had three, declared the way ADR 0003 declares those: a sentence in the
  study where it begins, never a silent handover. It begins with the first **write** route,
  because a read has no read-decide-write, so the page can name the study exactly.

  **Confirmed at 36: the study is 37.** Studies 35 and 36 both answer `GET` at every path and
  write nothing, so neither owes the sentence. Study 37 brings routing, status codes and a
  `POST` together, and owes it. `Tracker.record` is now six lines with the read, the decision
  and the write each on their own — which is the shape study 40 has to talk about, legible
  before it is a problem.

  **Paid at 37, in 37.3, beside the route that writes.** The page says that two callers can
  both be told there is room and both be recorded, that this is the first study in which that
  is possible, and that study 40 is where it is measured and closed. The promise table carries
  the row, so `check_promises` holds study 40 to it.
- **The server logs nothing time-varying** — no timestamps, no elapsed times, no random
  ports. Not a style rule: a transcript carrying a clock reading cannot be re-run, and
  `check_transcripts` exists because a transcript nobody re-runs is one any later commit
  can falsify in silence. Note what that tool covers today: it re-runs `dart test`
  transcripts and compares the **count** matched by `\+(\d+): All tests passed!`. A server
  transcript is not a `dart test` transcript, so nothing re-runs it until the tool is
  taught — which is on `HANDOFF.md`'s open list, and is the reason this constraint has to
  be a rule rather than a habit.

  **Amended while writing study 35: the rule is necessary and it is not sufficient.** It
  governs what the server prints, and `bin/serve.dart` obeys it — port 8080, one fixed
  readiness line. It says nothing about what `shelf` puts on the *wire*, and every HTTP
  response carries a `date:` header that no rule in this repository can remove. So
  `tool/capture_server.dart` exists, `check_transcripts` defers every transcript with a
  `curl` command to it, and each header scenario's command ends in a `sed` that elides that
  one value — **on line 1 of the transcript**, where the reader sees it and can run it.
  Eliding it inside the tool would have been the same output and a worse artifact: a
  transcript normalised behind the reader's back is no longer real captured output of a
  command they can type.

  **Amended again while writing study 37: the rule is what made a middleware necessary, and
  this record's own row for study 37 was wrong about why.** That row said a thrown `Error` is
  *a 500 the client must never read*, as though something had to stop it. Measured: with
  nothing wrapping the handler, `shelf_io` answers `500` with the body `Internal Server Error`
  and puts the message in **its own log line on stdout, which carries a timestamp**. The
  client was never going to read it.

  So `faults` exists for two smaller reasons and the page states those: the plain-text body
  would be the only answer on this server that is not a JSON document, and the report would
  go wherever `shelf` sends it rather than where `bin/serve.dart` decided. Shelf's own 500 is
  asserted beside the middleware rather than assumed.

  **The timestamp is measured here and is deliberately not a claim on the page**, because it
  cannot be turned into an assertion. `shelf_io` writes that line straight to `stdout`: a
  `ZoneSpecification`'s `print` hook never sees it — measured, zero lines captured — and
  `IOOverrides.runZoned` wants a `Stdout`, which has no public constructor. A subprocess
  would do it and would need a third program under `bin/`, which `surface_test`'s `#runnable`
  group exists to refuse. A measurement a record can hold and a test cannot is exactly what
  this section is for, and the page saying less than this file is the correct direction for
  that gap to run.
- Deliberately not in Book III: isolates and codegen (Book IV), deployment, an ORM, CORS
  and a browser client, versioned schema migrations, and authenticating a *user* —
  `CONTEXT.md` says there is no Account, so the shared key in study 37 authenticates a
  caller and the page says so in those words.

**Predicted.** These are guesses this record is making before the work. Each is to be
re-read against the finished study and amended here if it was wrong.

- That study 40 will **weigh CQRS and units of work and decline them**, the way study 34
  declined `public_member_api_docs`. The tracker's API is small and a five-endpoint
  service rarely needs either. But declining is only honest after measuring, and if the
  concurrent writer turns out to need a unit of work, this bullet is what was wrong.
- ~~That the microtask queue draining before the next socket event means a handler awaiting
  an `InMemoryStore` **cannot** interleave with another request.~~ **Measured, and it holds.**
  Two requests on two already-open sockets: `InMemoryStore` gives `A enter, A exit, B enter,
  B exit`; `FileStore` and a bare `Future.delayed` both interleave. Book III's order stands.

  **But the same measurement opened something this record did not foresee, and it is now
  decided — see *Decided* above.** `FileStore` interleaves, so a server reading and writing
  a file has live concurrency from the first study that uses one, not from study 38 where
  this record put it.

  **And the lost update is probabilistic, which no prediction here allowed for.** Against
  `FileStore` it breaches *sometimes*, and the rate is not a property of the program: three
  runs of the identical 40-trial experiment gave 11/32/39, then 10/20/17, then 4/7/27 for
  two, three and four callers — not even monotonic. So the mechanism had to be narrowed to
  something that reproduces: a lost update needs a suspension **between the decision and
  the write**. Suspend the read and one expense is recorded; suspend the write and every
  caller records — 30/30 each, over three passes, and a store that reads from a real file
  but records in memory never breaches at all.

  This is now a standing requirement in its own right, because it breaks an assumption the
  rest of them share: every other measurement in this book is deterministic, so *run it and
  write down what happened* has always been safe. A race is the case where it is not.
- That study 39 is the overloaded one. Build hooks, a schema, `SqliteStore`, moving the
  reader's data, deleting study 38's cache and growing `Store` is six subjects against a
  five-section envelope. The spike should settle whether `Store`'s growth belongs in 40.
- That six studies is enough. Five was not, and the arithmetic that found six is the same
  arithmetic that would find seven.
