# Handoff — Learn Dart with Tests

**This file is orientation only.** It holds no plan and no state, because both went
stale here before and cost a session. The living documents listed below are the source
of truth.

Last checked: 2026-09-09.

## Read these, in this order

| Path | What it holds |
| --- | --- |
| `PRODUCT.md` | The 44-study, four-book shape; the audience; the voice rules; the six principles |
| `OUTLINE.md` | Book I's written spine, Book II's outline, the transcript convention, and **the standing requirements for every study** |
| `CONTEXT.md` | The expense tracker's vocabulary. A glossary, nothing else |
| `docs/adr/` | Why the books are shaped as they are. Read 0002 before writing any class |
| `git log --oneline` | Each study's commit message records what construction actually **measured**, which is often not what was expected |
| `docs/colour-and-stack.md` | The SAFF colour system, the editor themes, and the web stack |

## State

Book I (studies 1-22) is written, audited and pushed. **Book II (23-34) is complete** —
all twelve snapshots exist, and its promise table is empty because every promise the prose
made has been paid. Books III and IV have no outline; that is the next piece of work.

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
cd code && for d in ch*/; do (cd "$d" && dart test test/) || break; done   # every package green
cd code && dart run tool/check_slices.dart      # a study changed only what its SLICE says
cd code && dart run tool/check_regions.dart     # every new or changed region is on a page
                                                # or exempted, with a reason, in its SLICE
cd code && dart run tool/check_shown.dart       # no shown region leans on an unshown name
cd code && dart run tool/check_promises.dart    # the promise table matches the prose
cd code && dart run tool/check_transcripts.dart # every green transcript still runs green
cd code && dart run tool/check_also_met.dart    # every `Also met:` item was actually met
cd web && npx next build
```

`next build` is the only real check on the site; the dev server caches stale colour. If
colours look wrong in dev, `rm -rf .next/cache .source` before believing it.

`dart test` from `code/` does **not** run the suite. The root is a pub workspace whose own
package has no `test/`, so it exits with *No test files were passed* — the loop above is what
runs every study package. It runs `test/` only: `exercises/` is red on purpose in every study.

The six `check_*` tools cover different halves and none subsumes another —
`OUTLINE.md`'s standing requirements say what each one can and cannot see.
`check_transcripts` is the slow one: it re-runs a test suite per green transcript and
per challenge count, so give it a minute or two.

## Open, not on the book

Reference/cheatsheet section, 404 page, licence, Vercel deployment. Two stale files:
`.impeccable/design.json` and
`.impeccable/surfaces/web-src-app-docs-slug-page-tsx.md`.

Done since this list was last written: favicon, OG metadata and the book's mark
(`fbfb51a`), and the GitHub links, which are no longer placeholders.
