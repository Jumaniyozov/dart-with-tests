# SAFF for editors

The colour scheme the book uses for its code cards and terminal slabs, as an
IntelliJ scheme and a Zed theme.

| File | For |
| --- | --- |
| `SAFF-theme-1.0.0.jar` | **IntelliJ IDEA, GoLand, WebStorm, PhpStorm, Android Studio** — the whole IDE: frame and editor |
| `SAFF-Light.icls` / `SAFF-Dark.icls` | the editor colours alone, if you want to keep your current IDE frame |
| `saff.json` | Zed — a theme family holding both SAFF Light and SAFF Dark |
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

Every hex in `generate.mjs` is what a browser paints for the OKLCH beside it, read
back off a canvas — measured, not converted. Five of the light roles fall outside
sRGB, and browsers resolve those by clipping each channel rather than by the
chroma reduction in CSS Color 4; converting instead of measuring produces visibly
duller colour. If a source value in `web/src/app/global.css` changes, measure the
new one rather than computing it.
