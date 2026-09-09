# Colour, editor themes and stack

Moved verbatim out of `HANDOFF.md` on 2026-09-09, when the rest of that file had gone
stale enough to mislead. Nothing here was changed — it was accurate then, and nothing in
this session touched any of it.

## The SAFF colour system — done, don't reopen without reason

`web/src/lib/saff/palette.ts` is the single source of truth for colour.
`editor-themes/generate.mjs` builds the IntelliJ and Zed themes from it and
**refuses to run if the two disagree**, so the book and the editors cannot drift.

```bash
node editor-themes/generate.mjs   # rewrites both .icls, the JAR, saff.json, both Ghostty themes
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
installed from disk plus a restart. Ghostty reads `~/.config/ghostty/themes/`
(that path even on macOS, where its config file lives under Application Support)
and the filename *is* the theme name — `theme = dark:SAFF Dark,light:SAFF Light`.

### Terminals are their own surface

All three terminals — Ghostty, the IntelliJ Terminal tool window, Zed's terminal —
sit on the **page** rung. In dark the book joined them: its console was at
`oklch(11% …)`, where the sRGB chroma ceiling is 0.023 and no green can be seen,
and it could not be lifted alone because the old page was exactly where it needed
to go. So the whole dark ladder moved up (page 21→29%, card 25→33%, stone 29.5→37%,
stone-2 35→42%, ink-3 67→70%) and the console rose to `oklch(21% 0.022 170)`. The
book, the IDE, Zed and Ghostty now paint machine output on one colour, `#0E1C17`.

Two grounds are now defined as equalities, and a generator assertion enforces
them across the CSS/TS boundary: `--console` == the ground every terminal paints
on, `--porcelain-2` == the ground every editor paints on. Only the prose page
moved, so in dark the card is recessed below it rather than raised above it.

`--rail` did not move, on purpose: it is an unbordered floating panel whose edge is
only its colour difference from the page, it is shared with the light theme, and
`--on-rail-*` assumes it never flips. Light is unchanged and cannot converge — its
console is a slab inside a white page and its page rung is already near white.

Selection is matched light-to-dark as OKLab ΔE per surface (editor 10.2/10.7,
panels 5.3/6.3, terminal 11.7/14.2). Terminals carry a deeper light selection than
the editor because selected *code* has to stay readable and every syntax role sits
on top of the editor's. The measurements are in `editor-themes/README.md`.

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
