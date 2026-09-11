# Handoff — Learn Dart with Tests

**This file is orientation only.** It holds no plan and no state, because both went
stale here before and cost a session. The living documents listed below are the source
of truth.

Last checked: 2026-09-11.

## Read these, in this order

| Path | What it holds |
| --- | --- |
| `PRODUCT.md` | The 45-study, four-book shape; the audience; the voice rules; the six principles |
| `OUTLINE.md` | Book I's written spine, Book II's outline, the transcript convention, and **the standing requirements for every study** |
| `CONTEXT.md` | The expense tracker's vocabulary. A glossary, nothing else |
| `docs/adr/` | Why the books are shaped as they are. Read 0002 before writing any class |
| `git log --oneline` | Each study's commit message records what construction actually **measured**, which is often not what was expected |
| `docs/colour-and-stack.md` | The SAFF colour system, the editor themes, and the web stack |

## State

Book I (studies 1-22) is written, audited and pushed. **Book II (23-34) is complete** —
all twelve snapshots exist, and its promise table is empty because every promise the prose
made has been paid. **Book III (35-40) is open: studies 35 to 38 are written**, and 39-40
have provisional titles and no code. ADR 0005 records the order and why it costs a sixth
study. Book IV (41-45) has no outline.

The next piece of work is study 39, `ch39_expenses`. Book III's promise table has **four**
rows and **three of them are study 39's**: `Expense.toJson` surviving the move into a
database, a bound a store can actually keep, and study 38's cache being **deleted** rather
than improved. Its entry in `OUTLINE.md` says it is over budget on purpose — six subjects
against a five-section envelope — and names `Store`'s growth as the likeliest thing to move
into study 40.

The lost-update debt ADR 0005 declares was **paid into print at 37**, in 37.3, beside the
first route that writes. Study 40 is now held to it by the table.

Counts are not restated here. `OUTLINE.md` and the git log carry them, and a number
copied into this file is a number that will be wrong within a week. That is exactly how
the previous version of this file came to claim the book was three studies long.

## First thing in a fresh worktree

`.dart_tool/` and `node_modules/` are gitignored, so a new worktree has neither.

```bash
cd code && dart pub get && cd ../web && npm install
```

Skipping the first makes `dart analyze` report about sixty phantom errors about
unresolved `package:` imports. It looks like the book is broken. It is not.

## The checks

```bash
cd code && dart analyze && dart format --output=none --set-exit-if-changed .
cd code && for d in ch*/; do [ -d "$d/test" ] || continue; (cd "$d" && dart test test/) || break; done
cd code && dart run tool/check_slices.dart      # a study changed only what its SLICE says
cd code && dart run tool/check_regions.dart     # every new or changed region is on a page
                                                # or exempted, with a reason, in its SLICE
cd code && dart run tool/check_shown.dart       # no shown region leans on an unshown name
cd code && dart run tool/check_promises.dart    # the promise table matches the prose
cd code && dart run tool/check_transcripts.dart # every green transcript still runs green
cd code && dart run tool/check_also_met.dart    # every `Also met:` item was actually met
cd code && dart run tool/check_shipped.dart     # OUTLINE.md's `Shipped:` counts match
                                                # the packages they describe
cd code && dart run tool/capture_server.dart --check   # the server transcripts still
                                                # re-run; check_transcripts runs this too
cd web && npx next build
```

`next build` is the only real check on the site; the dev server caches stale colour. If
colours look wrong in dev, `rm -rf .next/cache .source` before believing it.

`dart test` from `code/` does **not** run the suite. The root is a pub workspace whose own
package has no `test/`, so it exits with *No test files were passed* — the loop above is what
runs every study package. It runs `test/` only: `exercises/` is red on purpose in every study.

**The `[ -d "$d/test" ] || continue` guard is load-bearing, and it was missing.** Study 1
has no `test/` at all — the standing requirements say so, because the reader has not met
`test()` yet — so the previous version of this loop broke on the first package and ran
nothing. It printed a failure and stopped, which reads like a broken book rather than a
broken command. Corrected while outlining Book III: 33 packages have a `test/`, and they
held **1248 tests**, which is the number this file's predecessors quoted without a working
loop to produce it. Studies 35 and 36 make it 35 packages and **1626 tests**; re-run the loop
rather than trusting any of these numbers.

The seven `check_*` tools cover different halves and none subsumes another —
`OUTLINE.md`'s standing requirements say what each one can and cannot see.
**`check_transcripts` and `check_shipped` are the slow two**, because both run a suite per
claim; give them a minute or two each.

`capture_server` is not an eighth checker; it is the one tool that can re-run a transcript
of a program that does not exit, and `check_transcripts` delegates to it. Listed separately
above only because running it alone is much faster while you are capturing.

**That delegation had a hole and now does not.** `check_transcripts` skips any transcript
holding a `$ curl` line entirely and counts it as covered here; this tool used to iterate
only its own scenario registry. A server transcript no scenario named was therefore re-run
by nothing while both printed green — planting one moved no number in either. It now also
scans `code/ch*/transcripts/` and fails on any `curl` transcript it does not own, so the
summary line ends *and no server transcript without a scenario*. If you capture a server
transcript by hand, this is what will stop you.

**`check_shipped` is the newest, and it exists because `OUTLINE.md` was the one corpus no
checker read.** Nine `Shipped:` lines, six carrying a wrong number when first swept by
hand. It counts the files in each study's `transcripts/` and runs that package's own suite,
against the ruling that a `Shipped:` line describes the package **as it stands** rather
than the commit that wrote it. Studies 27, 28 and 29 state no count, which it reports
rather than failing on — a study that states no number cannot have a stale one — while
finding *no* lines at all fails, because that is the check switching itself off.

**`check_promises` was Book II-only until Book III was outlined.** It hardcoded one heading
and read one directory, so Book I's table and Book III's were both invisible, as would
every page either book ever shipped. It now finds tables by their header row and reads
every page under `web/content/docs/`; study numbers are unique across books, which is what
makes one page map enough. Finding all three tables immediately surfaced a real promise
Book I had paid only in prose — `extension-types.mdx` says *"Study 23 will show how to hide
a constructor"* — now recorded as `19→23` so the tool can see it.

## Open, on the book

- Nothing. `tool/capture_server.dart` was the one item here and it landed with study 35,
  which is exactly what this entry said to do: it was deliberately not written while the
  server it had to start did not exist, and writing it against the real `bin/serve.dart`
  cost no guesses. It owns the scenario — entrypoint, seeded store, commands — and
  `check_transcripts` defers any transcript containing a `curl` command to it.

  **One thing ADR 0005's rule did not cover, found by building it.** *The server logs
  nothing time-varying* is about the server's own output. HTTP's `date:` header is not the
  server's output and no rule here can remove it, so each scenario's command pipes through
  a `sed` that elides that one value — **on line 1 of the transcript**, where the reader
  can see it and run it. Anything else would be a transcript normalised behind the
  reader's back.

## Open, not on the book

Reference/cheatsheet section, 404 page, licence, Vercel deployment.

`.impeccable/` now tracks **only** `config.json` and `design.json`; the nine review PNGs,
`questions/` and `surfaces/` were untracked and `.gitignore` keeps them out, which settles
the second of the two stale files this list used to name. `design.json` is the one left,
and it is still stale — the design hook reports `DESIGN.md` is newer than it, fixed by
`/impeccable document`.

## The history was rewritten on 2026-09-10

`.impeccable/review/`, `questions/` and `surfaces/` were purged from **all** history with
`git filter-repo`, not merely untracked. They entered in the repo's second commit, so
every commit from there on has a new SHA — 61 commits, all of them.

**Any clone or worktree made before that date is incompatible** and must be re-cloned, or
reset to the new refs. `git pull` will not reconcile them.

Three worktrees went with it — `book-logo-design-aa252d`, `dart-book-handoff-50bb50` and
`dart-book-outline-next-c23635`, each confirmed merged into `main` before removal.

**Six commit references in this book's prose were remapped**, and the operational fact
behind that is worth keeping: `git filter-repo` rewrites SHA references inside **commit
messages** automatically, and does **not** touch **file contents**. So the log healed
itself and the prose did not. Every one of these had to be found and replaced by hand:

| Cited as | Now | The commit |
| --- | --- | --- |
| `efa9fb6` | `97f639e` | Correct three false claims, and a stale consequence |
| `fbfb51a` | `968ad86` | Give the book a mark, and the metadata that carries it |
| `ff350b1` | `4528c90` | Audit study 23: two claims with no run behind them |
| `69727fb` | `25ecdfa` | Audit the Book II code: two silent wrongs |
| `69c05df` | `f6df067` | Audit the promise ledger |
| `645eaf7` | `ab840c9` | Audit study 27: a transcript nobody was checking |

The left column is kept here on purpose, and only here: it is what a stale clone will
show, and this table is the only thing that can translate it. Everywhere else the new SHA
is the one written. Every citation is also identified by what the commit did, which is why
none of them was lost — **a SHA is a citation that rots, so never let one be the only
identification of a commit.**

Sweep for a stale one with: for each 7-hex token in `*.md`, `git merge-base --is-ancestor
<sha> main`. A token that resolves but is not an ancestor of `main` is reachable only from
a stale `origin/*` ref and dies at the next prune.

Done since this list was last written: favicon, OG metadata and the book's mark
(`968ad86`), and the GitHub links, which are no longer placeholders.
