# SAFF for editors

The colour scheme the book uses for its code cards and terminal slabs, as an
IntelliJ scheme, a Zed theme and a Ghostty theme.

| File | For |
| --- | --- |
| `SAFF-theme-1.0.0.jar` | **IntelliJ IDEA, GoLand, WebStorm, PhpStorm, Android Studio** — the whole IDE: frame and editor |
| `SAFF-Light.icls` / `SAFF-Dark.icls` | the editor colours alone, if you want to keep your current IDE frame |
| `saff.json` | Zed — a theme family holding both SAFF Light and SAFF Dark |
| `ghostty/SAFF Light`, `ghostty/SAFF Dark` | Ghostty — the terminal's 16 ANSI slots plus ground, ink, caret and selection |
| `intellij-keys.json` | every IntelliJ colour key and the SAFF role it takes |
| `generate.mjs` | writes all of the above from one palette |

## Installing

**Zed** — copy the theme into your config, then pick it from the theme list:

```bash
cp editor-themes/saff.json ~/.config/zed/themes/
```

Then `cmd-k cmd-t`, or Settings → Theme, and choose **SAFF Light** or **SAFF Dark**.
Zed watches that directory, so re-running `generate.mjs` and copying again updates
a live editor without a restart.

**IntelliJ-based IDEs** — Settings → Plugins → the gear → **Install Plugin from Disk**
→ pick `SAFF-theme-1.0.0.jar`, then restart. SAFF Light and SAFF Dark appear in
Settings → Appearance → Theme, and change the toolbar, tool windows, tabs and
status bar as well as the editor.

A `.icls` on its own **cannot** change the IDE frame — it is an editor colour
scheme and nothing more. Import one (Settings → Editor → Color Scheme → gear →
Import Scheme) only if you want SAFF's code colours inside somebody else's IDE
theme.

**Ghostty** — copy both files into Ghostty's theme directory and name them in
your config:

```bash
mkdir -p ~/.config/ghostty/themes && cp editor-themes/ghostty/SAFF\ * ~/.config/ghostty/themes/
```

```
theme = dark:SAFF Dark,light:SAFF Light
```

### The terminal's ground is not the book's console ground

Every terminal surface — Ghostty, the IntelliJ Terminal tool window and Run/Debug
console, and Zed's terminal — sits on the **page** rung (`--porcelain`), not on
the console slab the book uses. In the book that slab is *recessed* against a visible page, a measured
1.28:1 step below the code card. Full screen there is no page for it to sit below,
so the step is inherited logic rather than a decision — and in dark it landed on
`oklch(11% …)`, where the sRGB chroma ceiling is **0.023**. At that lightness the
green cannot be seen no matter what chroma is asked for; the ground just reads
black. The page rung doubles the ceiling to 0.042.

|  | ground | fg | dim (slot 8) | selection ΔE |
| --- | --- | --- | --- | --- |
| dark | `#0E1C17` `oklch(21% 0.022 170)` | 12.0:1 | 3.45:1 | 14.2 |
| light | `#EFF5F2` `oklch(96.4% 0.007 165)` | 13.9:1 | 4.77:1 | 11.7 |

In an editor the terminal is a bordered panel, so the border does the separating
and the step falls to 1.10:1 (dark) and 1.05:1 (light); in Ghostty there is no
editor to step away from at all.

**In dark the book came with it.** Its console could not simply be lifted — at
the old page of `oklch(21%)` the two would have merged — so the whole dark ladder
moved up and the console rose ten points to meet it:

| | was | now | |
| --- | --- | --- | --- |
| `--console` | `oklch(11% 0.018 172)` | `oklch(21% 0.022 170)` | = every terminal |
| `--porcelain-2` | `oklch(25% 0.024 168)` | unchanged | = every editor |
| page | `oklch(21% 0.022 170)` | `oklch(29% 0.024 168)` | |
| stone / muted | `oklch(29.5% …)` | `oklch(37% …)` | |
| stone-2 | `oklch(35% …)` | `oklch(42% …)` | |
| ink-3 | `oklch(67% …)` | `oklch(70% …)` | |
| `--color-fd-card`, `--color-fd-popover` | `oklch(25% …)` | `oklch(33% …)` | UI chrome, still raised |

Only the prose page moved, and it moved *up* — so in dark the stack now reads by
how machine-made the content is, with the card recessed rather than raised:

```
console  21%   dart test output   Ghostty, IDE terminal, Zed terminal
card     25%   authored source    IntelliJ editor, Zed editor
page     29%   prose
stone    37%   panels
```

`--color-fd-card` and `--porcelain-2` had only ever shared a value by
coincidence; a popover floating above the page and a code block sunk into it
want opposite directions once the page sits between them.

`--rail` deliberately did **not** move. It is an unbordered floating panel whose
edge is nothing but its colour difference from the page, it is shared with the
light theme, and `--on-rail-*` is built on it never flipping. Lifting the page
around it keeps all three true and leaves light untouched. The alternative —
dropping the rail to `oklch(20%)` and lifting the page only to 25% — measured
worse where it counts: page-to-console fell to ΔE 3.7, and the console stopped
reading as its own material. `--ink-3` went up three points because muted text on
the new page measured 4.72:1, and 5.27:1 restores the headroom it had.

### The seam between global.css and palette.ts

`palette.ts` names its grounds after the tokens that paint them — `cardX.ground`
is `--porcelain-2`, `consoleX.ground` is `--console` — but for a long time
nothing checked that the tokens still *held* those values. Lifting the dark
ladder moved `--porcelain-2` eight points and split the book's code card from the
editor background it is defined to equal. Both files stayed internally
consistent. Every assertion passed. The only way to see it was to put the book
and the editor side by side.

`assertCssMatchesPalette()` now reads `global.css` directly and compares both
grounds in both themes, through a table of browser-measured values rather than a
conversion. It is verified to fail on exactly that regression.

Light does not converge and cannot. Its console is a slab recessed inside a white
page and its page rung is already near white, so there is nowhere for the two to
meet. `TERM.dark.ground` now equals `TERMINAL_GROUND.dark`; `TERM.light.ground`
still differs, and `assertMatchesBook` keeps both honest.

Slot 8 is what comments and dim output are drawn with, and it sets the dark floor:
one rung further up (`stone`, `oklch(29.5% …)`) drops it to 2.69:1. Light has no
such ceiling — every metric improves as the ground lifts — so light is chosen for
symmetry with dark rather than by a limit.

### Two selections, and why not one

Selection is measured as OKLab ΔE from whatever ground it lands on, and light was
uniformly weaker than dark. It is now matched surface by surface:

| surface | light | dark |
| --- | --- | --- |
| editor | 10.2 | 10.7 |
| panels, lists, completion | 5.3 | 6.3 |
| terminal | 11.7 | 14.2 |

**The shared value** (`UI[mode].selection`) went from `#C3E8D7` to `#BFE6D0`,
`oklch(89% 0.050 160)` — editor ΔE 9.2 → 10.2, panels 4.4 → 5.3.

**Terminals get a deeper one** (`TERMINAL_SELECTION`), `#B1DEC2` in light. This
is not an arbitrary second value: dark gets the same effect for free, because its
selection is lighter than both grounds and the page rung is further from it than
the editor rung, so dark reads 14.2 in the terminal against 10.7 in the editor.
In light the two rungs fall the other way round, so the terminal has to be given
explicitly what dark gets by geometry.

**Do not just use the deeper value everywhere.** Selected code still has to be
read: every syntax role sits *on* the selection, and the worst of them (comment)
measures 3.50:1 on `#BFE6D0` against 3.19:1 on `#B1DEC2`. Dark's equivalent is
3.61:1. The shared value is chosen to hold that line; the terminal's is free to
go deeper because nothing but plain output sits on it.

A pale ground also leaves no room *below* it, so a light selection buys its
visibility with chroma rather than lightness. There is room to spare — the
ceiling at L86 is 0.201 and `#B1DEC2` spends 0.060 — which is the exact opposite
of the syntax roles' problem at reading lightness.

### Hand-picked hexes do not move when the ground moves

Four block-terminal keys were literal hexes chosen a shade off the old near-black:
hovered, selected and inactive-selected block backgrounds. Nothing catches that —
the assertions check that a key is *named*, not that its value still makes sense —
and when the ground moved up a rung, the dark ones would have sat *darker* than
their ground while the selected block sat lighter, pointing hover and selection in
opposite directions. They are derived from the ladder now:

```
ground  #0E1C17 L21.2  ->  hover  #12201B L22.9  ->  selected  #16251F L24.9
ground  #EFF5F2 L96.5  ->  hover  #F3F7F5 L97.3  ->  selected  #F7FAF8 L98.2
```

Two things about that path. A Ghostty theme file has **no extension and no name
field** — the filename *is* the theme name, so `SAFF Dark` must stay spelled
exactly that way. And the theme directory is `~/.config/ghostty/themes` even on
macOS, where the config file itself lives somewhere else entirely
(`~/Library/Application Support/com.mitchellh.ghostty/config`).

Check it took with `ghostty +list-themes --plain --path | grep SAFF`, and check
the file parses with `ghostty +validate-config --config-file=<your config>` —
that reports an unknown key inside a theme, not just in the config.

The 16 ANSI slots are the same table the IntelliJ terminal and Zed are given, so
a `dart test` run is the same colours in the book, the IDE and the terminal.
In the light theme the *bright* colours are darker than their normal
counterparts, which looks backwards and is not: on a pale ground a lighter
colour reads as fainter, so bright has to mean more emphatic instead.

### Why terminal syntax highlighting is not SAFF, and is not meant to be

`ghostty +list-themes` previews a `bat` sample drawn with ANSI slot *indices*,
so a highlighter's slot conventions — not SAFF — decide which colour a keyword
gets. Monokai says keyword→magenta, so `const` renders purple in the terminal
and green in the book. Measured off the preview: `#8a2a7b` light, `#d58ecf`
dark, which is slot 5 exactly.

| Token | Slot it lands on | SAFF gives | Book gives |
| --- | --- | --- | --- |
| keywords, numbers | magenta | purple | green, orange-red |
| functions | green | green | teal-green |
| strings | yellow | brass | orange |
| types | cyan | teal | brass gold |

This is not fixable inside 16 slots: ANSI is a six-hue channel and SAFF is a
ten-role palette. Remapping the syntax-carrying slots to SAFF roles was
considered and **rejected** — it would make literal magenta green and literal
cyan gold for every CLI tool on the system, to fix a synthetic preview. The
right surface for terminal syntax is the highlighter's own theme in truecolor
(a `.tmTheme` for `bat` and `delta`, `LS_COLORS` for `ls`), the same split the
IDE already has: 16 ANSI keys for the terminal, 1,170 syntax keys for the editor.

Legibility was checked and is fine — worst chromatic slot is light yellow at
4.85:1 on its ground, the rest 5–16:1. Slots 0 and 8 sit low in dark on purpose;
that is what black and bright black are for.

## What the colours mean

Eight roles, the same eight the book distinguishes:

| Role | Light | Dark | Carries |
| --- | --- | --- | --- |
| keyword | `#006425` | `#36AC62` | `class`, `final`, `const`, `var`, `return` — **bold** |
| declared name | `#007C57` | `#4BC39F` | functions, methods, getters |
| type | `#936000` | `#EFCF59` | `String`, `int`, class references |
| string | `#AD4A00` | `#F4AF38` | literals |
| number | `#C34500` | `#F48E1F` | numeric constants |
| interpolation | `#C10002` | `#E57431` | `$name`, `${…}`, escapes |
| annotation | `#717500` | `#E1DC85` | `@override` and friends |
| comment | `#587A6C` | `#7C9A8E` | *italic* |
| identifier | `#2E493F` | `#DFE7E0` | everything you named |
| punctuation | `#5B6E67` | `#96A29A` | brackets, operators, terminators |

Emerald marks what the language decides; brass marks what you wrote down. Nothing
else gets a colour, which is why the cards read quietly at length.

Weakest contrast is 4.53:1 (light comment) and 5.21:1 (dark comment and
interpolation), both above WCAG AA for body text.

**Light is tuned for salience, not darkness.** Every chromatic light role sits
exactly on the sRGB gamut boundary for its lightness, so there is no saturation
left to add — light and dark carry near-identical mean chroma (0.143 against
0.142). What differed was weight: plain `identifier` used to carry 2.67x the
contrast of the median coloured role, against 1.73x in dark, so near-black text
won every glance and colour read as a tint. Lifting `identifier` from 14.5:1 to
9.3:1 — still past WCAG AAA — and spending `keyword`'s and `interpolation`'s
surplus contrast on chroma brings the ratio to 1.83.

More saturation is not available on a white ground. A legible dark colour has to
sit near L 50, and at L 50 the sRGB ceiling for gold is 0.10 and for teal 0.09 —
the two flattest points on the hue circle, where indigo and magenta offer 0.28.
Brass and emerald have no vivid dark form; dark mode gets vividness free because
bright saturated colour is high-contrast on a dark ground. Only abandoning the
two brand hues would change that.

## Two things worth knowing

**Both schemes name the identical key set — 1,171 of them.** This is not thoroughness
for its own sake. A scheme only decides the keys it names; every other key falls
through to `parent_scheme`, and light and dark inherit from two unrelated stock
palettes. The first version of this scheme set 75 keys, so `GO_PACKAGE` took its
colour from IntelliJ's own light scheme in one theme and Darcula in the other,
and the two themes stopped looking related. `generate.mjs` now refuses to write
if the two files name different keys.

The `DEFAULT_*` fallback chain covers most languages but not all of them, and a
hand-written table cannot be trusted to find the gaps: the first version named
75 keys, the second 484, and Go structs were still unnamed in both — `cobra.Command`
took its colour from `Default` under the light theme and `Darcula` under the dark
one, which is why objects looked coloured in dark and plain in light.

The table is now read out of the IDE instead of written by hand:

```bash
node editor-themes/extract-keys.mjs /Applications/GoLand.app > editor-themes/ide-keys.txt
```

`extract-keys.mjs` walks every jar in the IDE, decompiles the classes that call
`createTextAttributesKey` or `createColorKey`, and prints the external name of
each key with the section it belongs in. GoLand 2026.2 registers 842. The
generator refuses to write if any of them goes unnamed, and refuses again if a
key is listed in `intellij-keys.json` but never emitted — the earlier silent
failure, where 19 `chrome`/`vcs`/`diagnostic` keys had no emitter at all.

Point it at whichever IDE you use; a different one registers a different set.

**The Terminal tool window is not the console.** IntelliJ's reworked terminal reads
its own `BLOCK_TERMINAL_*` keys and ignores `CONSOLE_*` entirely, and the background
it uses is `BLOCK_TERMINAL_DEFAULT_BACKGROUND`, not `TERMINAL_BACKGROUND`. Setting
the console keys alone left the tool window on the parent scheme's black under SAFF
Light. `generate.mjs` now asserts all 14 terminal colour keys and 20 terminal
attribute keys — the list read out of `com/intellij/terminal/BlockTerminalColors` —
and refuses to write if any is unnamed.

**The terminal is not purely SAFF.** SAFF is a green-and-brass world with one red,
and ANSI needs eight hues whatever the brand thinks. Black, red, green, yellow and
white come straight from the book's console palette. Blue, magenta and cyan are
chosen at the same lightness and chroma as the rest of the palette so they sit in
the family — but they are additions, not colours the book itself uses.

## If the colours don't change, look for a shadowing import

Installing the plugin **and** importing the `.icls` puts two schemes with the
same name on the machine, and the user copy wins. IntelliJ records the selection
by name only:

```xml
<global_color_scheme name="SAFF Light" />
```

A scheme imported through Settings → Editor → Color Scheme → gear → Import is
written to `~/Library/Application Support/JetBrains/<IDE>/colors/SAFF Light.icls`,
and that file shadows the identically-named scheme inside the plugin. Reinstalling
the plugin then changes nothing, however many times you restart — the IDE never
reads it.

The symptom is a scheme that is *partly* SAFF: syntax colours look right, because
the import carries them, while the Terminal tool window, the VCS gutter and most
language-specific keys stay on the parent scheme. Check the sizes — a shadowing
import is a few hundred lines against the plugin's several thousand:

```bash
ls -l ~/Library/Application\ Support/JetBrains/*/colors/
```

To remove it: Settings → Editor → Color Scheme, pick **SAFF Light**, then the gear
→ **Delete**. That deletes the user copy, not the plugin, and the bundled scheme
of the same name takes over. Repeat for SAFF Dark. Use the settings dialog rather
than deleting the file by hand — a running IDE rewrites that directory on exit.

Either install the plugin or import the `.icls`. Never both.

## If the IDE chrome is SAFF but the editor is not

IntelliJ remembers, per theme, which colour scheme you last had active with it,
and that memory **overrides the theme's own `editorScheme`**. It lives in
`options/laf.xml`:

```xml
<laf-to-scheme laf="uz.saff.light" scheme="_@user_Default" />
```

That line means: whenever the SAFF Light theme activates, force the editor onto
`Default`. The theme's declared scheme is ignored. The symptom is a correctly
themed toolbar, tabs and status bar wrapped around an editor painted in stock
IntelliJ colours — green strings, blue keywords — and `options/colors.scheme.xml`
reading `<global_color_scheme name="Default" />`.

It gets recorded by accident. Deleting a shadowing user scheme drops the editor
back to `Default`, and IntelliJ writes that pairing down as your preference.

To clear it: with the SAFF theme active, Settings → Editor → Color Scheme, pick
**SAFF Light**. That rewrites the pairing. Do the same under the dark theme for
SAFF Dark, since the two are remembered separately.

## Regenerating

```bash
node editor-themes/generate.mjs
```

It refuses to write if the syntax colours have drifted from
`web/src/lib/saff/palette.ts`, so the editor and the book cannot disagree.
One run rewrites both `.icls`, the JAR, `saff.json` and both Ghostty themes.

Every hex in `generate.mjs` is what a browser paints for the OKLCH beside it, read
back off a canvas — measured, not converted. Five of the light roles fall outside
sRGB, and browsers resolve those by clipping each channel rather than by the
chroma reduction in CSS Color 4; converting instead of measuring produces visibly
duller colour. If a source value in `web/src/app/global.css` changes, measure the
new one rather than computing it.
