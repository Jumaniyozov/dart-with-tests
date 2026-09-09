---
name: Stonelight Press
description: >-
  Learn Dart with Tests, in the SAFF · Stonelight material world. Light stone,
  deep emerald, earned brass; the book as one continuous object. Colors are the
  canonical light (:root) values in OKLCH — see "After sunset" for the dark map.
derivedFrom: SAFF · Stonelight (/Users/islom/Projects/saff-scafold/DESIGN.md)
colors:
  # surfaces
  porcelain: "oklch(96.4% 0.007 165)"
  porcelain-2: "oklch(98.2% 0.004 165)"
  stone: "oklch(92.6% 0.010 160)"
  stone-2: "oklch(89.5% 0.012 158)"
  # ink
  ink: "oklch(24% 0.036 170)"
  ink-2: "oklch(36% 0.032 170)"
  ink-3: "oklch(46% 0.026 170)"
  # emerald — structure and action
  emerald: "oklch(38% 0.085 165)"
  emerald-strong: "oklch(33% 0.080 167)"
  emerald-deep: "oklch(21% 0.052 170)"
  emerald-night: "oklch(16% 0.040 172)"
  on-emerald: "oklch(97% 0.010 160)"
  # brass — earned
  brass: "oklch(58% 0.085 80)"          # material: rules, borders, focus ring
  brass-ink: "oklch(45% 0.090 72)"      # text-weight brass (the 4.09:1 fix)
  brass-bright: "oklch(74% 0.085 85)"
  brass-pale: "oklch(86% 0.045 88)"
  # lines
  hairline: "oklch(85% 0.025 95 / 0.65)"
  hairline-soft: "oklch(88% 0.020 110 / 0.45)"
  # the book's own addition
  correction: "oklch(47% 0.150 27)"     # a failing test; Stonelight has no red
  # materials that keep their colour in both themes
  console: "oklch(90% 0.016 162)"
  console-ink: "oklch(26% 0.030 170)"
  rail: "oklch(25% 0.045 168)"        # deep emerald, not near-black
  rail-ink: "oklch(95% 0.018 150)"
  rail-mute: "oklch(75% 0.028 155)"
  rail-line: "oklch(100% 0 0 / 0.11)"  # every rule drawn on the rail
  rail-wash: "oklch(100% 0 0 / 0.06)"  # hover, and any tray on the rail
  rail-active: "oklch(39% 0.085 165)"  # the pill under the current entry
  on-rail-surface: "oklch(96% 0.012 155)"
  on-rail-ink: "oklch(30% 0.075 167)"
typography:
  display:   { fontFamily: "Fraunces", fontSize: "clamp(2.5rem, 7vw, 4.4rem)", fontWeight: 600, lineHeight: 0.98, letterSpacing: "-0.028em" }
  numeral:   { fontFamily: "Fraunces", fontSize: "3.4rem", fontWeight: 400, lineHeight: 0.85, letterSpacing: "-0.03em" }
  title:     { fontFamily: "Fraunces", fontSize: "2.1rem", fontWeight: 600, lineHeight: 1.06 }
  section:   { fontFamily: "Fraunces", fontSize: "1.45rem", fontWeight: 600 }
  body:      { fontFamily: "Literata", fontSize: "1.02rem", lineHeight: 1.72 }
  direction: { fontFamily: "Manrope", fontSize: "0.92rem", fontWeight: 500 }
  label:     { fontFamily: "Manrope", fontSize: "0.72rem", fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase" }
  code:      { fontFamily: "JetBrains Mono", fontSize: "0.82rem", lineHeight: 1.7 }
rounded:
  chip: "0.75rem"
  card: "1rem"
  panel: "1.5rem"
  pill: "999px"
---

# Stonelight Press — Design System

The visual language of **Learn Dart with Tests**. Derived from SAFF · Stonelight: the same
light stone, deep emerald and earned brass, cut for reading rather than tapping. Source of
truth: `web/src/app/global.css`.

Where the app treats itself as one continuous room, the book treats itself as one
continuous object. Same materials, different job.

## What the book changes on purpose

Two departures from Stonelight, both forced by the job:

1. **Literata carries the prose.** Stonelight runs a serif display over a Manrope UI, and
   that is right for a phone app where nothing is read for an hour. Forty-four chapters
   are. Manrope stays, but only for chrome: directions, labels, the prescription, the
   table of contents. Fraunces replaces Fiorina Title as the display face — Fiorina is
   licensed to SAFF, and Fraunces is open.
2. **The book adds a red.** Stonelight has no red at all; its anti-references name
   aggressive red CTAs. But a book about tests must show a failing test, so `correction`
   exists. It is never a fill, never a border, never emphasis — only the word "failing"
   and the direction above a red drill.

## Color

Emerald carries structure and action. Stone and porcelain carry surface. Brass is the
earned metal, and in this book it means exactly one thing: **a study the reader has
worked**. That is the book's only earned state, and it maps onto the role brass plays in
the app (membership, ceremony).

### After sunset (`.dark`)

Stonelight's own dark map, not an inversion.

| token | dark value |
|---|---|
| porcelain | `oklch(21% 0.022 170)` |
| porcelain-2 | `oklch(25% 0.024 168)` |
| stone | `oklch(29.5% 0.026 168)` |
| ink | `oklch(93% 0.012 150)` |
| ink-2 | `oklch(81% 0.018 155)` |
| ink-3 | `oklch(67% 0.02 158)` |
| emerald | `oklch(79% 0.10 158)` |
| brass | `oklch(70% 0.085 82)` |
| brass-ink | `oklch(80% 0.09 85)` |
| correction | `oklch(72% 0.13 30)` |
| console | `oklch(11% 0.018 172)` |

Every `rail-*` token, plus `console-ink`, `on-rail-surface` and `on-rail-ink`, is
**identical in both themes**.

### Legibility (measured, both themes)

Ratios computed in the browser by painting each OKLCH token to a canvas and reading back
sRGB, so the engine does the conversion. Every text pair passes **AA**; most reach AAA.

| pair | light | dark | use |
|---|---|---|---|
| ink / porcelain | 14.66 | 14.30 | headings, strong |
| ink-2 / porcelain | 9.65 | 9.82 | body |
| ink-3 / porcelain-2 | 6.68 | 5.37 | prescription, citations |
| emerald / porcelain | 8.63 | 9.43 | links, passing direction |
| correction / porcelain | 6.65 | 6.70 | failing direction |
| on-emerald / emerald | 8.76 | 10.34 | drill pill |
| brass-ink / porcelain-2 | 7.18 | 8.51 | Best-practice label |
| brass / porcelain | 3.89 | 6.50 | **rules and borders only** |
| rail-ink / rail | 16.22 | 16.22 | rail entries |
| rail-mute / rail | 7.27 | 7.27 | rail numerals |
| brass-bright / rail | 8.30 | 9.61 | worked mark |
| on-rail-ink / on-rail-surface | 11.62 | 11.62 | cover CTA |
| console-ink / console | 11.40 | 13.90 | terminal output |

### Named Rules

**The Earned-Brass Rule.** Brass marks what the reader has earned and nothing else: the
worked mark, the study number of a worked entry, the best-practice note. It is never a
brand accent, never a fill, and never body text. The one exception is the focus ring,
which is brass because a ring must be visible on porcelain, emerald and console alike.

**The Two-Brasses Rule.** `brass` is a *material* at 3.89:1 on porcelain — legal for a
rule, a border or a ring, illegal for text. Label text takes `brass-ink`. Reaching for
`brass` on a text node is the single easiest accessibility regression in this system, and
it is the one this build already made once.

**The Same-Cloth Rule.** The rail keeps its colour under any lamp — identical in `:root`
and `.dark`, the way book cloth is the same cloth in any light. It follows that anything
sitting *on* it must also be theme-stable: the cover CTA uses `on-rail-surface` /
`on-rail-ink` rather than `porcelain-2`, which read 1.67:1 after sunset when it flipped
with the theme. The console is **not** cloth — it is a material the page recesses into,
and it turns with the lamp.

**The Equal-Step Rule.** A material's distance from its neighbour is the same under either
lamp. The card sits 1.28:1 from the console in dark; the light console's ground is chosen
so it sits 1.28:1 from the card too, rather than at whatever value looked right. Audit:
measure the step in both themes — if they differ, one theme has a flatter page than the
other, and the reader will feel it as the theme being worse rather than different.

**The Preserved-Relationships Rule.** Dark preserves relationships, not arithmetic. The
card lifts off the page, the console sinks below it. Audit: in dark, if the card and the
console are the same near-black, or the card sits flush with the page, the theme is wrong.

**The Mark-Not-Hue Rule.** No state is carried by colour alone. A failing drill is
`correction` *and* says so in words; a worked study is brass *and* carries a drawn pencil;
the active rail entry is a filled pill *and* bolder *and* its numeral changes colour.
Audit: greyscale the screen — if pass and fail are no longer distinguishable, it is wrong.

**The Own-Theme Rule.** Syntax colour is a real theme with real scopes — `saff-light` and
`saff-dark` in `web/src/lib/saff/`, built from one structure so the two can differ in
colour but never in which scope means what. This replaced a remap of GitHub's emitted
hexes, which could not work: github-light gives `String` and `1_000_00` the same hex, and
by the time a hex exists the meaning has already been discarded. Scopes are the semantic
layer; hex is only presentation. Audit: if two roles must differ and share a hex upstream,
the answer is a scope, never a selector.

**The Chroma-Over-Ladder Rule.** Light takes its chroma to the sRGB edge and keeps
its lightness ranking. Five of the ten roles — type, string, number, interpolation,
annotation — share one hue arc, and light gives them 0.111 of lightness where dark
gives 0.200, so hue carries five roles alone and the closest pair sits at ΔE 3.2.
A lightness ladder was built and measured at ΔE 6.4; it was rejected on sight
because it turns numbers and interpolation into deep rust. The flatness is a
chosen cost, recorded here rather than hidden. Audit: do not "fix" the ΔE by
re-ranking lightness without putting the rust back in front of a reader first.

**The Measured-Colour Rule.** Every hex in the theme is what a browser paints for the
OKLCH beside it, read back off a canvas — never converted. Five of the light roles fall
outside sRGB, and browsers resolve those by clipping each channel, not by the chroma
reduction of CSS Color 4; converting instead of measuring desaturates them by up to
11/255 per channel, which is visible. Re-measure when a source value changes.

**The Grammar-Corrections Rule.** Where a bundled grammar is wrong for the book, correct it
in an injection, not in CSS. Dart's files `var` under `storage.type.primitive` beside
`void`, which would print the three words of Study 3 in two different roles; it leaves
brackets unscoped; and its call rule swallows the `(` after a name. All of it lives in
`saff.injection.dart`, with the reason written next to each pattern.

## Typography

Four faces, and each earns its place.

- **Fraunces** — display. Chapter numerals, titles, section heads, the cover. `--font-display`.
- **Literata** — the reading face. All prose and list text. `--font-body`.
- **Manrope** — UI chrome. Directions, labels, prescription, table of contents, rail entries. `--font-ui`.
- **JetBrains Mono** — code, terminal output, and any number that orders something. `--font-mono`.

**The Reading-Face Rule.** Prose is Literata and only Literata. Manrope may never take a
paragraph the reader is expected to read for more than a sentence; that is what separates
this from the app it came from.

## Shape

| radius | value | used by |
|---|---|---|
| chip | `0.75rem` | rail entries, search |
| card | `1rem` | code card, note cards, cover CTA, page foot, book cards |
| panel | `1.5rem` | reserved |
| pill | `999px` | drill numeral |

**The Card-or-Nothing Rule.** A thing is a card, a pill, or plain text on the page. There
is no third container and no tinted row: a surface that needs to read as separate becomes
a card, and a surface that does not stays on the page. Cards carry `1px` hairline and a
1px-blur shadow at 5% and nothing heavier — Stonelight's own lift, not a drop shadow.

## Layout

| band | width | note |
|---|---|---|
| rail | `228px` (`--fd-sidebar-width`, ≥768px) | holds a numeral, a name and a mark, nothing else |
| page container | `1100px` cap | `#nd-page`, overriding fumadocs' 900 |
| reading column | `82ch` | code cards, consoles and note cards take this full width |
| running text | `72ch` | `.prose > p`, `> ul`, `> ol`, `> blockquote` |
| table of contents | `268px` | fumadocs default, unchanged |

**The Fixed-Column Rule.** Collapsing the rail hides the panel and moves nothing else.
Fumadocs sets `--fd-sidebar-col: 0px` inline when collapsed, dropping the grid column so
the reading column slides left; the column stays reserved instead, so every line of text
is in the same place whether the rail is shown or hidden. Measured shift on toggle: `0px`
for the page, the prose, the heading and the table of contents.

**The Two-Measures Rule.** The column is wide and the text is not. Code, terminal output
and note cards run to `82ch` because a wrapped line of Dart is a lie about the code's
shape; paragraphs stop at `72ch` because that is what a reader can follow for an hour.
Both start at the same left edge, so the page still reads as one column. Widening the
paragraph cap to match the column would undo the reason the column is wide.

## Elevation

Effectively flat. The only shadow in the system is `0 1px 2px oklch(24% 0.03 170 / 0.05)`
on cards, which reads as a sheet resting on stone rather than floating above it.

## Components

### Chapter Head (signature)
Fraunces numeral at 3.4rem in emerald, title at 2.1rem beneath it. No rule, no double rule
— the head separates by scale and air. The numeral is omitted on pages with no study number.

### Prescription
Manrope 0.98rem in `ink-3`, max 56ch, under the head. How to work this study.

### Drill (signature)
`1.75rem` emerald pill carrying the step number in Manrope 600, `on-emerald`. Content in
the second column. The pill is the app's circular control doing a book's job.

### Direction
Manrope 0.92rem/500. `correction` while the bar fails, `emerald` once it passes — and the
words always say which.

### Gloss
A porcelain-2 card, hairline border, `1rem` radius, bookmark mark in emerald, title in
Fraunces 600. A note that must not be skimmed.

### Practice (best-practice note)
A card whose left edge is `1px` of `brass` where the other three sides are `hairline`, over
a brass-pale gradient falling into porcelain-2. Label in Manrope uppercase 0.72rem/0.08em
tracking, `brass-ink`. Citation in mono `ink-3`, dotted-underlined when it links out. An
uncited note visibly claims less.

**The Hairline-Accent Rule.** The brass edge is a hairline, never a tab. A coloured border
thicker than 1px on one side of a card is the most recognisable tell of a generated UI, and
the note does not need it: the gradient wash, the brass label and the citation already say
what this block is. Three cues carry it; the fourth was only shouting.

### Code Card (authored source)
`figure.shiki` on porcelain-2, hairline border, `1rem` radius, filename bar in Manrope
0.72rem. Source **scrolls horizontally**; a line is never rewrapped, because wrapping
falsifies the code's shape.

### Console (machine output) — signature
Recessed stone under a light lamp, a near-black slab under a dark one, border the same
colour as the fill. The nine roles are the same in both; only their lightness flips,
because emphasis on a pale ground is darkness and on a dark ground is light. Output is
**not** uncoloured
and **not** shell script: transcripts carry `lang="saff-console"`, a grammar of this book's
own that knows the nine things a reader looks for — the `$` prompt in brass, the command
bright, the elapsed clock dim, `+N` green, `-N` and `[E]` and `Error:` red, `file:line:col`
gold, quoted paths soft green, the `^` caret lit. Its root scope carries the console ink, so
untokenised output cannot fall through to the code card's foreground. Nothing in CSS may set
a colour on a console token. Output **wraps** — it must never be clipped. The `<pre>` carries `w-max`, so `pre-wrap` alone does nothing; the width has to be
constrained on `pre`, `code` *and* `.line`, and `overflow-x: hidden` on the scroller
removes the escape hatch, so a future rule reinstating `white-space: pre` here would clip
silently.

### Rail
Deep emerald owns the entire region — and the region is **two elements**: `#nd-sidebar`
on desktop and `#nd-sidebar-mobile` in the drawer. Every rail rule names both with
`:is(#nd-sidebar, #nd-sidebar-mobile)`; scoping to the desktop id alone leaves the drawer
in stock neutrals below 768px, which is exactly the bug this pass found.

The rail is a book's contents page, not a docs tree. It answers three questions at a
glance — which study you are in, how far through the book you are, which studies you have
worked — in four parts:

- **Progress** (banner, above everything): the word "Worked", the count in tabular mono,
  and a 2px track whose fill is `brass-bright`. The count is the signal; the rule only
  makes it easier to feel. The total counts studies that **exist**, never the 44 planned.
- **Front matter**: no numeral column, `rail-mute`, followed by a hairline. A page that is
  not a chapter stops occupying a chapter's grid.
- **Book**: a full-width trigger — roman numeral in mono, name in Manrope 600, worked
  count (`2/3`) in mono, chevron rotated `-90deg` when shut. A closed book still reports
  its count, so the rail answers "where am I in the whole thing" without expanding.
- **Study**: `chip`-radius pill, `0.4rem 0.55rem` padding, three-column grid of mono
  numeral, name and worked mark. The active entry is a filled `emerald-deep` pill. Open
  books hang their studies off a 1px spine at 11% white.

**The Open-Book Rule.** The book you are reading is open; the others are shut. On a page
inside no book — the front matter — the book holding study 1 opens instead, because a
contents page with no contents is not a contents page.

**The Panel Rule.** The rail is a panel resting on the page, not a wall bounding it:
`0.5rem` inset on all three outer sides, `card` radius, no end border. Fumadocs ships that
form only for the collapsed-and-hovered state and goes flush with a hard border when
pinned; both states take the panel here, because the reader should not get a different
object depending on whether they pinned it.

**The Rail-Tints-Its-Own-Chrome Rule.** Anything sitting on the rail takes its colours from
`rail-*`, never from the page tokens. The stock search hint is `bg-fd-background`, which
inside the rail resolves to the *page* colour — pale pills carrying pale text, unreadable
in light mode. Any borrowed component gets the same treatment: tray backgrounds become
`rail-wash`, rules become `rail-line`, text becomes `rail-ink` or `rail-mute`.

**The Separator-Outside-The-Box Rule.** A rule that divides two rows is positioned
absolutely into the margin between them, never drawn as a flow child of either. Drawn
inside the link, the front-matter separator sat on the link's own background and the hover
fill ran straight through it.

**The Active-Is-Not-Earned Rule.** The active entry's numeral is `oklch(84% 0.03 155)`,
never brass. Active is where you are standing; brass is what you finished. Spending brass
on the current row destroys the only colour in this system that carries a fact.

### Rail Progress
The one place a meter exists. It is legible without it — the count is written out — so the
rule is reinforcement, not the reading. `role="progressbar"` with real `aria-valuenow` /
`aria-valuemax`. Fill transitions over 460ms on the house ease and is collapsed by
`prefers-reduced-motion`.

### Worked Toggle (signature interaction)
Hairline above, a drawn pencil that animates its stroke in on first mark, and the state
in words. Worked is `brass`; unworked is `ink-3`.

### Theme Switch
Three states — light · system · dark (`themeSwitch: { mode: 'light-dark-system' }`), because
"system" is a real choice and a two-state toggle makes a reader who follows their OS keep
re-picking. Rendered as a `rail-wash` track of round buttons with the current state filled
in `rail-active`. Fumadocs wraps it in a bordered tray and then strips three of the
switch's own four borders, leaving one stray rule beside the sun; both the tray chrome and
that edge are removed.

### Motion
One authored animation: `sl-draw-on`, 460ms on `cubic-bezier(.22, 1, .36, 1)` — Stonelight's
own `--ease-out`. Collapsed by `prefers-reduced-motion`.

## Do's and Don'ts

### Do
- **Do** let emerald-night own an entire region — the rail, the mobile subnav, the cover.
- **Do** spend brass only on what the reader earned, and take `brass-ink` when it is text.
- **Do** keep authored source on the porcelain card (scrolls) and machine output on the
  emerald-night console (wraps).
- **Do** pair every colour state with a mark or a word; the page must survive greyscale.
- **Do** define every new token in both `:root` and `.dark`, and set the dark value by the
  relationship it preserves rather than by inverting the light value.
- **Do** keep anything that sits on the rail theme-stable, because the rail is.
- **Do** extend the `--shiki-light` remap table when a new token colour appears.

### Don't
- **Don't** set prose in Manrope. Literata reads; Manrope labels.
- **Don't** use `brass` for text. That pair is 3.89:1 and it fails.
- **Don't** invent a third container. Card, pill, or nothing.
- **Don't** add a heavier shadow, a hover lift, or a hard offset shadow.
- **Don't** use `correction` as a fill, a border, or an emphasis colour.
- **Don't** use a glyph icon font; every mark here is drawn SVG with `currentColor`.
- **Don't** add a double rule, a bar line or an engraved mark. Those belonged to the
  étude world this replaced, and reintroducing one makes the page speak two languages.

## Prior art

The **Étude Book** — Edition Peters livery, Archivo over Literata, square geometry, the
double rule at three scales, repeat signs and fermatas — was this project's design system
until this replacement, and is recorded in git history. It is prior art and an
anti-reference, not a constraint. Nothing here should be a compromise between the two.
