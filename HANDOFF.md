# Handoff — Learn Dart with Tests, v2

Written 2026-09-09. The last several sessions went almost entirely into the SAFF
colour system. That work is finished and installed. **The book itself is three
studies out of forty-four.** Start there.

---

## Where to start

Write studies 4 onward. Everything below is context, not a queue of chores.

Three studies exist:

| File | Teaches |
| --- | --- |
| `web/content/docs/foundations/hello-dart.mdx` | the toolchain, first run |
| `web/content/docs/foundations/your-first-test.mdx` | `test()`, `expect()`, red→green |
| `web/content/docs/foundations/variables.mdx` | `var` / `final` / `const`, compile-time vs run-time |

Their runnable sources are in `code/ch01_hello`, `ch02_greeting`, `ch03_variables`.
Read all three before writing a fourth — they set the voice, the section rhythm,
and the transcript convention, and none of that is written down anywhere else.

## How a study is built

Prose lives in MDX under `web/content/docs/`. Code lives in `code/chNN_*/` as a
real Dart package that actually compiles and whose tests actually run. The MDX
pulls source and terminal output in by reference rather than by copy:

```mdx
<Console>
  <include lang="saff-console">../../../code/ch03_variables/transcripts/all.txt</include>
</Console>
```

Transcripts under `code/chNN_*/transcripts/*.txt` are captured from real `dart test`
runs. Do not hand-write them. If a transcript needs to change, change the code and
re-capture, or the book starts lying.

`lang="saff-console"` is required for terminal output — it selects the console
grammar. Plain ` ```bash ` will render with the wrong palette on the wrong ground.

### Components

- `web/src/components/worked.tsx` — the worked-example wrapper
- `web/src/components/press.tsx` — code card / console slab
- `web/src/components/rail.tsx` — the side rail
- `web/src/components/mdx.tsx` — registers all of the above for MDX

`etude.tsx` and `sidebar-item.tsx` were deleted in the v1→v2 cut. If you see them
referenced anywhere, that reference is stale.

## Two standing rules for the writing

From `~/.claude/projects/-Users-islom-Projects-darty/memory/`:

- **Name the machinery.** Explain the mechanism — compile time versus run time,
  what it costs, what it guarantees — not just the style habit. "Prefer `const`"
  is not a lesson; "`const` is computed once at compile time and canonicalised,
  so two identical `const` values are the same object" is.
- **Cite the practice.** Every study carries a best-practice note, and the
  Effective Dart or lint attribution must be *verified* before it is quoted.
  Do not attribute from memory.

The reader is a beginner and not a native English speaker. Short sentences.

## Open work on the book

- Studies 4–44.
- A reference / cheatsheet section (planned, not started).
- Favicon, OG metadata, 404 page, licence.
- Vercel deployment.
- GitHub links are placeholders — there is no repo yet. Re-wire once there is one.
- `.impeccable/surfaces/web-src-app-docs-slug-page-tsx.md` still describes the v1
  "Étude Book". Stale.
- `.impeccable/design.json` (31 KB) is the v1 sidecar. Stale. Regenerate or delete.

## Nothing is committed

Two commits exist, both from before v2. Every v2 change — the content rewrite, the
SAFF library, `editor-themes/`, the deletions — is uncommitted working tree. The
user has never authorised a commit or push. Ask before the first one.

---

## The SAFF colour system — done, don't reopen without reason

`web/src/lib/saff/palette.ts` is the single source of truth for colour.
`editor-themes/generate.mjs` builds the IntelliJ and Zed themes from it and
**refuses to run if the two disagree**, so the book and the editors cannot drift.

```bash
node editor-themes/generate.mjs        # rewrites both .icls, the JAR, and saff.json
```

Three things about this system are counterintuitive enough to be worth knowing
before touching it. All three are documented at length in `editor-themes/README.md`.

**Colour is measured, never converted.** Several light roles sit outside sRGB, and
Chrome resolves those by clipping each channel — not by the chroma reduction in
CSS Color 4. Converting instead of measuring produces visibly duller colour than
the page shows. If an OKLCH in `global.css` changes, paint it to a canvas in a real
browser and read the pixel back.

**The key table is extracted from the IDE, not written by hand.** Three successive
hand-written tables were all wrong in the same invisible way: an unnamed key does
not error, it inherits from `parent_scheme` — `Default` under light, `Darcula`
under dark — so the same token came out gold in one theme and black in the other.

```bash
node editor-themes/extract-keys.mjs /Applications/GoLand.app > editor-themes/ide-keys.txt
```

GoLand 2026.2 registers 842 keys. SAFF names all of them. The generator asserts it.

**Light cannot be as vivid as dark, and that is physics.** Every chromatic light
role already sits exactly on the sRGB gamut boundary for its lightness. On a white
ground a legible colour must sit near L 50, and at L 50 the sRGB ceiling for gold
is 0.10 and for teal 0.09 — the two flattest points on the whole hue circle, where
indigo and magenta offer 0.28. Brass and emerald have no vivid dark form. Light and
dark now match on every measurable axis (mean chroma 0.143 vs 0.142, salience ratio
1.83 vs 1.73, all WCAG AA); light still *looks* quieter, and no tuning changes that.
The user raised this three times. The measurements and rejected variants are in
`editor-themes/README.md`.

### Installing the editor themes

Zed picks up `~/.config/zed/themes/saff.json` live. IntelliJ needs the JAR
installed from disk plus a restart.

**Install the plugin or import the `.icls` — never both.** An imported `.icls`
lands in `~/Library/Application Support/JetBrains/<IDE>/colors/` and *shadows* the
identically-named scheme inside the plugin, so reinstalling the plugin changes
nothing. This cost two sessions. There is a second, separate override in
`options/laf.xml` (`<laf-to-scheme>`) that pins a scheme per theme and beats the
theme's own `editorScheme`. Both failure modes are written up in the README.

### A crash worth remembering, fixed

`CodeVisionThemeInfoProvider.foregroundColor` reads
`INLAY_TEXT_WITHOUT_BACKGROUND` and null-checks its foreground. The key's name
ends in the word BACKGROUND but it is a *foreground* key, and the auto-classifier
that filled the 480 new keys used `/_BACKGROUND$/` to decide which keys want a
ground — so it got a background and no foreground. The null-check threw inside
`EditorPainter.paint`, the paint aborted partway down the viewport, and every row
below the throw kept the previous frame's pixels. It looked like a frozen editor
with ghost text and out-of-order line numbers; it was one missing hex value.

Fixed and confirmed gone after restart. The heuristic now excludes
`WITHOUT_BACKGROUND`, and real background keys get both a ground and an ink.

The lesson generalises: when an IDE paints wrong, read
`~/Library/Logs/JetBrains/<IDE>/idea.log` for `Unhandled exception in EDT` and
look at what the `Caused by` frame asked the scheme for. A colour scheme can
crash the editor, and it does not announce itself as a colour problem.

---

## Stack

Fumadocs 16.15.8 · Next.js 16.3.4 · React 19 · Tailwind 4 · Shiki 4.4.3 · Biome · TypeScript.

`web/src/lib/source.ts` wires the SAFF themes and grammars into `rehypeCode` inside
`defineDocs`'s `mdxOptions`. That callback runs in fumadocs-mdx **macro mode** — the
whole call is erased from the app bundle at build time, which is why the dynamic
`import()` in there is safe. Don't "simplify" it to a static import.

```bash
cd web && npx next build     # the only check that matters; dev server caches stale colour
```

If colours look wrong in dev, `rm -rf .next/cache .source` before believing it.
