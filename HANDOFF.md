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

Book I (studies 1-22) is written, audited and pushed. Book II (23-34) is outlined and
not written. Books III and IV have no outline.

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
cd code && dart analyze && dart test && dart format --output=none --set-exit-if-changed .
cd code && dart run tool/check_slices.dart
cd web && npx next build
```

The last one is the only real check on the site; the dev server caches stale colour. If
colours look wrong in dev, `rm -rf .next/cache .source` before believing it.

`check_slices` has nothing to compare until Book II's second package exists.

## Open, not on the book

Reference/cheatsheet section, 404 page, licence, Vercel deployment. Two stale files:
`.impeccable/design.json` and
`.impeccable/surfaces/web-src-app-docs-slug-page-tsx.md`.

Done since this list was last written: favicon, OG metadata and the book's mark
(`fbfb51a`), and the GitHub links, which are no longer placeholders.
