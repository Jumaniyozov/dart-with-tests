---
name: Learn Dart with Tests
description: A practice manual in Edition Peters livery — numbered études, engraved marks, plate ink on manuscript white.
colors:
  ground: "#F4F5F1"
  plate-ink: "#101512"
  rail-green: "#1F4A3D"
  green-ink: "#16352C"
  correction-red: "#C0392B"
  marked-ochre: "#F2D06B"
  plate: "#FBFBF7"
  rule: "#C9CEC6"
  grey: "#56605A"
  muted: "#E7E9E1"
  muted-ink: "#5C665E"
  console: "#161B18"
  console-ink: "#CBD4CD"
  rail-ink: "#E4EBE5"
  rail-mute: "#A9C2B5"
typography:
  display:
    fontFamily: "Archivo, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(2.4rem, 7vw, 4.2rem)"
    fontWeight: 700
    lineHeight: 0.98
    letterSpacing: "-0.035em"
  numeral:
    fontFamily: "Archivo, ui-sans-serif, system-ui, sans-serif"
    fontSize: "3.4rem"
    fontWeight: 700
    lineHeight: 0.82
    letterSpacing: "-0.045em"
    fontVariant: "tabular-nums"
  headline:
    fontFamily: "Archivo, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.72rem"
    fontWeight: 600
    lineHeight: 1.08
    letterSpacing: "-0.022em"
  title:
    fontFamily: "Archivo, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.4rem"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.02em"
  section-head:
    fontFamily: "Archivo, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.28rem"
    fontWeight: 600
    letterSpacing: "-0.012em"
  subsection-head:
    fontFamily: "Archivo, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.05rem"
    fontWeight: 600
    letterSpacing: "-0.012em"
  subtitle:
    fontFamily: "Archivo, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.02rem"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: "-0.012em"
  body:
    fontFamily: "Literata, Georgia, 'Times New Roman', serif"
    fontSize: "1.02rem"
    fontWeight: 400
    lineHeight: 1.72
    letterSpacing: "normal"
  direction:
    fontFamily: "Literata, Georgia, 'Times New Roman', serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.5
    fontStyle: "italic"
  code:
    fontFamily: "JetBrains Mono, ui-monospace, 'SFMono-Regular', monospace"
    fontSize: "0.82rem"
    fontWeight: 400
    lineHeight: 1.7
  label:
    fontFamily: "JetBrains Mono, ui-monospace, 'SFMono-Regular', monospace"
    fontSize: "0.72rem"
    fontWeight: 400
    lineHeight: 1.2
    letterSpacing: "0.02em"
    fontVariant: "tabular-nums"
rounded:
  none: "0px"
  engraved: "2px"
  pill: "99px"
spacing:
  hair: "3px"
  xs: "6px"
  sm: "12px"
  md: "20px"
  lg: "28px"
  xl: "48px"
  gutter: "24px"
  gutter-wide: "56px"
components:
  chapter-head:
    textColor: "{colors.plate-ink}"
    typography: "{typography.headline}"
    rounded: "{rounded.none}"
    padding: "0 0 10px"
  chapter-numeral:
    textColor: "{colors.rail-green}"
    typography: "{typography.numeral}"
  prescription:
    textColor: "{colors.rail-green}"
    typography: "{typography.direction}"
    width: "60ch"
  direction-fail:
    textColor: "{colors.correction-red}"
    typography: "{typography.direction}"
  direction-pass:
    textColor: "{colors.rail-green}"
    typography: "{typography.direction}"
  section-head:
    textColor: "{colors.plate-ink}"
    typography: "{typography.section-head}"
    rounded: "{rounded.none}"
    padding: "18px 0 0"
  subsection-head:
    textColor: "{colors.plate-ink}"
    typography: "{typography.subsection-head}"
    rounded: "{rounded.none}"
    padding: "11px 0 0"
  toc-entry-active:
    textColor: "{colors.rail-green}"
  gloss:
    backgroundColor: "{colors.ground}"
    textColor: "{colors.plate-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.none}"
    padding: "14px 0"
  code-plate:
    backgroundColor: "{colors.plate}"
    textColor: "{colors.plate-ink}"
    typography: "{typography.code}"
    rounded: "{rounded.engraved}"
  code-console:
    backgroundColor: "{colors.console}"
    textColor: "{colors.console-ink}"
    typography: "{typography.code}"
    rounded: "{rounded.engraved}"
  rail:
    backgroundColor: "{colors.rail-green}"
    textColor: "{colors.rail-ink}"
    rounded: "{rounded.none}"
  rail-entry:
    textColor: "{colors.rail-ink}"
    typography: "{typography.label}"
    padding: "0"
  rail-entry-active:
    textColor: "#FFFFFF"
  cta-primary:
    backgroundColor: "{colors.marked-ochre}"
    textColor: "{colors.green-ink}"
    rounded: "{rounded.none}"
    padding: "12px 24px"
  worked-toggle:
    textColor: "{colors.grey}"
    typography: "{typography.subtitle}"
    padding: "0"
  worked-toggle-marked:
    textColor: "{colors.rail-green}"
---

# Design System: Learn Dart with Tests

## Overview

**Creative North Star: "The Étude Book"**

This is a practice manual in the livery of an engraved music edition, not a documentation
site. The reader works with an editor and a terminal open and types along; the page is
built for that posture. Each chapter is a numbered étude: a large green numeral beside the
title over a double rule, an italic performance direction beneath it, then drills bracketed
by drawn repeat signs. Nothing on the page is decorative — every mark is a music-engraving
convention doing a job the reader can name.

The material vocabulary is deliberately narrow: Peters green owns the full-height rail and
every chapter numeral, plate ink sits on manuscript white, and correction red appears only
where something is failing. Depth is carried by rules and material change, never by
shadow. The only images in the build are marks the code draws — SVG repeat dots, a fermata,
a pencil — because a rasterized illustration would break the engraved surface.

The system refuses the default docs arrangement of neutral sidebar plus neutral column. It
also refuses cards, colour bars, gradients, and shadowed elevation. Where a state matters,
it is engraved: a numeral, a drawn mark, a rule weight, a word. Colour reinforces state but
never carries it alone — PRODUCT.md's readers include red-green colour-blind readers, and
the failing/passing drill directions must read without hue.

**Key Characteristics:**
- Peters green rail owning a whole region, never a stripe or an accent bar
- Chapter numerals as display type, tabular and tight-tracked
- Double-rule chapter head borrowed from a score's system break
- Two distinct code materials: authored source on a plate, machine output on a console
- Marks over colour for every state; one authored motion in the entire build
- Flat surfaces, 2px corner engraving at most, no shadows anywhere

## Colors

A three-note palette on paper: engraver's green, plate ink, correction red, with one ochre
pencil for the reader's own marks.

### Primary
- **Peters Green** (`{colors.rail-green}`): The livery. It fills the full-height rail edge to
  edge, colours every chapter numeral, every repeat sign, the performance direction, the
  focus ring, and the selection highlight. It is a field colour and an ink colour, never a
  border accent.
- **Green Ink** (`{colors.green-ink}`): The darker green used for type set *on* green-adjacent
  surfaces — the label on the ochre CTA, secondary foregrounds.

### Secondary
- **Correction Red** (`{colors.correction-red}`): The colour of a bar that is not yet right.
  Used on failing drill directions and on the fermata that marks a gloss. It never appears
  as a background, a border, or a decoration.
- **Marked Ochre** (`{colors.marked-ochre}`): The reader's pencil. Only two uses: the drawn
  pencil mark on a worked study (in the rail and on the toggle) and the primary CTA field on
  the cover. It signifies *the reader did this*, not *the system wants attention*.

### Neutral
- **Manuscript White** (`{colors.ground}`): The page ground. Light is the default because the
  reader works long stretches at a lit desk.
- **Plate Ink** (`{colors.plate-ink}`): Body and heading type; also the 2px double rule under
  a chapter head and the 2px rule above the worked toggle.
- **Plate** (`{colors.plate}`): A half-step above the ground — the authored-source code plate.
  Its lift is tonal, not shadowed.
- **Rule** (`{colors.rule}`): Every hairline: gloss borders, code-plate borders, cover list
  dividers, scrollbar thumb.
- **Grey** (`{colors.grey}`) / **Muted Ink** (`{colors.muted-ink}`): Secondary prose and unmarked
  control states.
- **Muted** (`{colors.muted}`): Inline-code background inside prose.
- **Console** (`{colors.console}`) / **Console Ink** (`{colors.console-ink}`): The terminal slab
  and its output. A different material from the page, on purpose.
- **Rail Ink** (`{colors.rail-ink}`) / **Rail Mute** (`{colors.rail-mute}`): Type on the green
  rail. Inside the rail, every surface tint is a `color-mix` of white or black against the
  green — the rail never introduces a new opaque colour.

### Dark

Dark mode is not an inversion of these values; it is the same relationships restated in a
darker room. The page ground drops to `#131714`, the code plate rises **above** it to
`#1C211D` so authored source still lifts off the page exactly as the light plate does, and
the console falls **below** it to `#080B09` so machine output still recedes. Green goes to
`#6fbf9f`, red to `#e08175`, the pencil to `#e8c264`, grey to `#96a099`, the rule to
`#2c332d`, console ink to `#c6d0c8`. The rail alone does not move: Peters green is
`#1F4A3D` in both themes.

### Named Rules

**The Preserved-Relationships Rule.** Dark mode preserves the light-mode *relationships*,
never the light-mode arithmetic. The plate is always a step lighter than the page ground and
the console always darker than it, so the Two-Materials Rule reads in both themes. Audit
test: in dark mode, if the plate and the console are the same near-black, or if either sits
flush with the ground, the theme is wrong regardless of the individual values.

**The Same-Cloth Rule.** The livery does not change with the light. `--etude-rail` and its
ink are identical in `:root` and `.dark` — book cloth is the same cloth under any lamp. A
tinted or lightened dark-mode rail is a bug, not a refinement.

**The Whole-Region Rule.** Peters green owns an entire region — the rail, the mobile subnav,
the cover masthead — or it appears as ink. It is never a 4px stripe, a chip fill, a badge, or
a highlight bar.

**The Mark-Not-Hue Rule.** No state is carried by colour alone. A failing drill is red *and*
says so in words; a worked study is ochre *and* carries a drawn pencil; the active rail entry
is brighter *and* bolder *and* its numeral changes state. Audit test: greyscale the screen —
if you can no longer tell pass from fail or worked from unworked, the treatment is wrong.

**The Correction-Red Rule.** Red means a thing is failing or a thing must not be skimmed.
It is never used for emphasis, links, brand, or decoration, and never as a fill.

**The Remapped-Syntax Rule.** Syntax colour is not a Shiki theme. The build intercepts the
emitted `--shiki-light` / `--shiki-dark` custom properties by attribute selector and remaps
each github-light hex into this palette (keywords → green, strings → an ochre-brown, comments
→ grey). Swapping the Shiki theme, or letting the highlighter emit different hexes, silently
reverts the code plate to GitHub's palette. Extend the remap table; do not replace it with a
theme.

## Typography

**Display Font:** Archivo (with `ui-sans-serif`, `system-ui`)
**Body Font:** Literata (with Georgia, Times New Roman) — normal and italic
**Label/Mono Font:** JetBrains Mono (with `ui-monospace`, SFMono-Regular)

All three are self-hosted through `next/font/google` and exposed as `--font-display`,
`--font-body`, `--font-mono`. No system display face is ever used.

**Character:** Archivo is the engraver's hand — tight, grotesque, confident at large sizes with
negative tracking. Literata is the reading voice: a serif with real italics, set generously for
long stretches. JetBrains Mono is the machine's voice and the numbering system. The three
never blur: sans announces, serif explains, mono counts and executes.

### Hierarchy
- **Display** (700, `clamp(2.4rem, 7vw, 4.2rem)`, 0.98, −0.035em): The cover masthead only.
- **Numeral** (700, 3.4rem, 0.82, −0.045em, tabular): The chapter number beside the chapter
  title. Set in Peters green, baseline-aligned to the title, never boxed.
- **Headline** (600, 1.72rem, 1.08, −0.022em, balanced): The chapter title, over the double rule.
- **Title** (600, 1.4rem, −0.02em): Section headings on the cover.
- **Section Head** (600, 1.28rem, −0.012em): In-prose `h2`, over its bar line.
- **Subsection Head** (600, 1.05rem, −0.012em): In-prose `h3`, over a single hairline.
- **Subtitle** (600, 1.02rem): In-prose h4 and gloss titles; Archivo at −0.012em.
- **Body** (400, 1.02rem, 1.72): All prose and list items, Literata, in a 68ch column.
- **Direction** (400 italic, 1rem/0.95rem, 1.5): Performance directions and prescriptions.
  Italic Literata is the *instruction* voice, distinct from explanation.
- **Code** (400, 0.82rem, 1.7): Both code materials.
- **Label** (400, 0.72rem, +0.02em/+0.06em, tabular): Code-plate filename bars, rail étude
  numbers, span notes on the cover.

### Named Rules

**The Three-Voice Rule.** Archivo announces, Literata explains, JetBrains Mono counts and
executes. A number that orders something (étude number, drill index, book span) is always mono
and tabular; a number that *is* the chapter's identity is Archivo display.

**The Instruction-Italic Rule.** Italic Literata is reserved for performance directions — how to
work this drill. Never use it for emphasis inside prose; emphasis is a semantic `<strong>`.

## Layout

A two-region model: a full-height green rail on the left and a reading column on the right.
The rail is a region, not a nav strip — its background, its ink, its borders, its muted
foreground and its hover tints are all re-declared inside `#nd-sidebar` so nothing neutral
leaks in. Below 768px the rail disappears and the livery moves wholesale to the top subnav;
the mobile bar takes the same green field and the same re-declared token set. There is no
intermediate "half rail" state.

The reading column is capped at **68ch** for prose. Prescriptions cap tighter at **60ch**
because a one-line instruction should not run the full measure. The cover is a centred
`max-w-4xl` column inside full-bleed sections.

Vertical rhythm is coarse and consistent: drills sit on a 1.5rem block gap, glosses on
1.75rem with 0.875rem internal padding, the worked toggle 3rem below the last drill.
Section padding on the cover is 24px horizontal / 56px at `md`, with 64–96px vertical bands.

The drill is a two-column grid — a fixed 26px mark gutter and a `minmax(0, 1fr)` content
column — so repeat signs align down the page like a barline. The rail entry is a three-column
grid (`1.35rem` number / flexible name / `0.95rem` mark) baseline-aligned, so numbers form a
right-aligned tabular column and marks form a right margin. Both grids use `minmax(0, 1fr)`
for the flexible column; content never widens the gutters.

Browser chrome belongs to the system: `scrollbar-gutter: stable`, an 11px scrollbar with a
rule-coloured thumb inset 3px against the ground, selection in Peters green on the ground
colour, and a 2px green focus ring at 2px offset.

## Elevation & Depth

**There are no shadows in this build.** `box-shadow` is explicitly zeroed on the code plate,
and nothing else declares one. Depth is entirely tonal and linear, which is what an engraved
page does: a plate sits a half-step lighter than the ground, the console sits far darker, and
hierarchy is drawn with rules of three weights.

### Rule Vocabulary
- **Hairline** (`1px solid {colors.rule}`): Gloss top/bottom, code-plate border, cover list
  dividers. Separates peers.
- **Structural** (`1px solid {colors.plate-ink}`): The lower line of the chapter double rule.
- **Terminal** (`2px solid {colors.plate-ink}`): The upper line of the chapter double rule and
  the line above the worked toggle. Opens and closes a study.
- **Bar line** (`border-top: 2px` + `box-shadow: 0 -5px 0 -4px`, both in the foreground ink):
  The section head's double rule — a 2px line with a hairline 5px above it, drawn with a
  spread-negative shadow because an element has only one top border. Opens an `h2` (3.25rem
  above, 1.15rem below).

### Named Rules

**The No-Shadow Rule.** Nothing in this world casts a shadow — no cards, no popovers, no
hover lift, no offset. If a surface needs to read as separate, change its material (plate,
console) or draw a rule. A hard offset shadow would import a neobrutalist idiom this world
does not speak.

**The Double-Rule Rule.** The double rule is the score's system break, and it exists at two
scales and no others: the chapter head takes it full weight (2px with a 1px line 3px beneath,
once per page), and an `h2` takes the bar-line restatement of the same device (2px with a
hairline 5px above). An `h3` takes a single hairline in the rule colour. These are three
steps of one device — a section head is not a new divider, and no fourth weight may be
invented for a fourth level.

## Shapes

Square by default. The only radius in the system is **2px** — the "engraved" corner — applied
to the code plate, the console slab, inline code, and the rail's search control (pulled
down from the pill fumadocs ships). Buttons, the CTA, the rail, glosses, and
the chapter head are all fully square (0px). The one exception is the scrollbar thumb, a pill
(99px), which is browser furniture rather than page geometry.

Marks are drawn geometry, never glyphs from a font or an icon set: the repeat sign is a 3px
bar, a 1px bar and two SVG dots; the fermata is a 1.5px stroked arc with a filled centre; the
pencil is a two-path stroked SVG. Every mark inherits `currentColor`, so a mark takes the
colour of the state that owns it.

## Components

### Chapter Head (signature)
The identity of a study. A baseline-aligned grid of the green chapter numeral and the chapter
title, over the double rule. The numeral is omitted for non-numbered pages and the title
simply takes the whole width — the head never renders an empty slot or a placeholder.

### Prescription
An italic Literata line in Peters green directly under the head, capped at 60ch. It is the
tempo marking: how to work this study. One per page, authored as MDX frontmatter, never more
than two lines.

### Drill (signature)
- **Shape:** two-column grid, 26px mark gutter, 14px gap, square.
- **Gutter:** a bold mono numeral (0.8rem, tabular) above a drawn repeat sign, both in Peters
  green. The repeat sign stretches to the drill's height with a 2.25rem minimum, so it reads as
  a barline at any content length.
- **Content:** first and last children have their margins collapsed so the drill sits flush.

### Direction
An italic Literata paragraph inside a drill, in correction red while the bar is failing and
Peters green once it passes. **The text must state the state in words** — the tone prop
changes hue, the sentence carries the meaning.

### Gloss
- **Shape:** square, hairline rule top and bottom, 14px vertical padding, no background fill.
- **Mark:** a red fermata in the left cell — hold here, do not skim.
- **Title:** Archivo 600 at 0.94rem; body drops to 0.95rem/1.62.
It is not a card and must never grow a fill, a radius, or a left accent bar.

### Code Plate (authored source)
- **Style:** plate background, hairline rule border, 2px corners, no shadow.
- **Header:** a mono filename bar at 0.72rem with +0.02em tracking, divided by a hairline.
- **Behaviour:** source **scrolls horizontally**; a line is never rewrapped, because wrapping
  falsifies the code's shape.
- **Syntax:** the remapped Shiki custom properties (see The Remapped-Syntax Rule).

### Console (machine output) — signature
- **Style:** near-black console slab, border the same colour as the fill (no visible edge), 2px
  corners; all spans forced to console ink so syntax colour is suppressed entirely.
- **Header:** the filename bar at 62% ink, divided at 18% ink.
- **Behaviour:** output **wraps** (`pre-wrap` + `overflow-wrap: anywhere`, with the `<pre>`,
  `<code>` and `.line` constrained to 100% width and the scroller's overflow hidden, because the
  block otherwise sizes to `max-content` and wrapping never engages). Verbatim machine output is
  never clipped and never scrolls sideways.

**The Two-Materials Rule.** Authored source and machine output are different materials and must
stay different: source is a light plate that scrolls, output is a dark slab that wraps. This is
a product principle — the reader must be able to tell at a glance what they type from what the
machine said — not a style preference. Never render a transcript on a plate or source on the
console.

### Rail Entry
- **Style:** a three-column baseline grid — étude number (mono, tabular, right-aligned, 60%
  opacity), name (`text-wrap: pretty`), mark slot.
- **Active:** white, weight 600, and the number goes to full opacity in marked ochre.
- **Worked:** an ochre pencil mark in the third column. Unworked entries render an empty span so
  the columns never shift.
- **Hover:** a 9% white `color-mix` tint from the rail's re-declared accent token.

### Worked Toggle (signature interaction)
A borderless button above a 2px terminal rule at the end of a study. Unworked: grey, pencil at
45% opacity, label "Mark this study worked". Worked: Peters green, pencil at full opacity, and
the label reads "**Worked.** The mark stays in the margin." Marking it draws the pencil path in
and broadcasts to the rail, which draws its own mark in the margin. State persists in
`localStorage`; blocked storage degrades to an unmarked but working page. Hover is opacity only.

### Table of Contents
The reading position, set in the book's own hand: Archivo throughout, with the active entry
in Peters green at weight 600. It carries no rail, no indent bar, and no fill — position is
marked by ink alone, since the entry's own text already names where you are.

### Page Foot
The previous/next pair is a ruled entry, not a card: the fumadocs card chrome is stripped
back to a single hairline on top, square corners, transparent fill, no shadow, no inline
padding. It reads as the last two lines of the page rather than two boxes under it.

### Cover CTA
Square (0px), marked ochre field, green ink label, Archivo 600 at 0.94rem, 12px/24px padding.
Its companion is a plain underlined text link at the same size — there is no second filled
button, no outline variant.

### Motion
**The One-Motion Rule.** This build authors exactly one animation: `etude-draw-on`, a
34-unit `stroke-dashoffset` sweep over **460ms** on `cubic-bezier(0.16, 1, 0.3, 1)`, which draws
the pencil mark in when a study is first marked worked. It is fully disabled under
`prefers-reduced-motion: reduce`, with the stroke resolved to its final state. Everything else
that moves is an opacity fade on hover. Do not add entrance animations, scroll reveals, or
transitions on colour.

## Do's and Don'ts

### Do:
- **Do** let Peters green own an entire region — rail, mobile subnav, cover masthead — or use it
  as ink on numerals, repeat signs and directions.
- **Do** pair every colour state with a mark or a word (The Mark-Not-Hue Rule); the page must
  survive greyscale.
- **Do** keep authored source on the light plate (scrolls) and machine output on the dark
  console (wraps).
- **Do** draw marks as inline SVG with `currentColor` and 1.5–1.6 stroke weights.
- **Do** extend the `--shiki-light` remap table when a new token colour appears in the emitted
  output, rather than swapping the Shiki theme.
- **Do** re-declare `--color-fd-*` tokens inside any region that takes the green field, so no
  neutral surface colour leaks in.
- **Do** define every new token in both `:root` and `.dark`, and set the dark value by the
  relationship it must preserve — plate above the ground, console below it, livery unchanged —
  not by inverting the light value.
- **Do** open an `h2` with the bar line and an `h3` with a single hairline, so a long chapter
  keeps the world going after the head.
- **Do** set numbers that order things in tabular mono, and the chapter's own number in Archivo
  display.

### Don't:
- **Don't** add a `box-shadow` anywhere, including a hard offset shadow — this world has no
  light source and no neobrutalist idiom.
- **Don't** introduce a card: no filled, rounded, bordered container for prose. Glosses use two
  hairlines and nothing else.
- **Don't** add a kicker or eyebrow line above a heading. The chapter numeral is the label,
  and standing facts (the study count, the Dart version) belong in the opening sentence.
- **Don't** invent a fourth rule weight or a new divider device for a heading level. The
  double rule has three steps: chapter head, `h2` bar line, `h3` hairline.
- **Don't** let a dark-mode surface collapse onto its neighbour: the plate, the ground and the
  console must stay three distinguishable materials in both themes.
- **Don't** use a glyph icon font or an icon package; every mark in this system is drawn SVG.
- **Don't** use a system display face — Archivo, Literata and JetBrains Mono are self-hosted and
  are the only three faces.
- **Don't** exceed 2px of corner radius on page geometry; buttons and regions are square.
- **Don't** use correction red as a fill, a border, or an emphasis colour, or marked ochre for
  anything the reader did not do themselves.
- **Don't** author a second animation. The 460ms draw-on is the only authored motion.
- **Don't** ship a raster. This build contains no photographs, illustrations, textures or
  generated plates, and an imported image would break the engraved surface.
