#!/usr/bin/env node
/**
 * Generates the SAFF editor themes from the book's own palette.
 *
 * Every hex here is what a browser paints for the OKLCH written beside it, read
 * back off a canvas. It is not computed: several light roles fall outside sRGB,
 * and Chrome resolves those by clipping each channel rather than by the chroma
 * reduction of CSS Color 4, which produces visibly duller colour. If a source
 * OKLCH in web/src/app/global.css changes, re-measure — do not convert.
 *
 * Run: node editor-themes/generate.mjs
 */
import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const VERSION = '1.4.0';

// ── The syntax palette ───────────────────────────────────────────────────────
// Mirrors web/src/lib/saff/palette.ts, which is asserted against below.

const SYNTAX = {
  light: {
    ground: '#F7FAF8', //        oklch(98.2% 0.004 165)
    keyword: '#006425', //       oklch(44% 0.127 148)
    fn: '#007C57', //            oklch(52% 0.111 164)
    type: '#936000', //          oklch(53% 0.113 73)
    string: '#AD4A00', //        oklch(53% 0.147 47)
    number: '#C34500', //        oklch(56% 0.173 41)
    interpolation: '#C10002', // oklch(51% 0.209 29)
    annotation: '#717500', //    oklch(54% 0.120 112)
    comment: '#587A6C', //       oklch(55% 0.045 167)
    field: '#6F530A', //         oklch(46% 0.090 85)
    identifier: '#2E493F', //    oklch(38% 0.037 169)
    punctuation: '#5B6E67', //   oklch(52% 0.025 171)
  },
  dark: {
    ground: '#16251F', //        oklch(25% 0.024 168)
    keyword: '#36AC62', //       oklch(66% 0.150 152)
    fn: '#4BC39F', //            oklch(74% 0.120 170)
    type: '#EFCF59', //          oklch(86% 0.140 94)
    string: '#F4AF38', //        oklch(80% 0.150 76)
    number: '#F48E1F', //        oklch(74% 0.165 60)
    interpolation: '#E57431', // oklch(68% 0.160 48)
    annotation: '#E1DC85', //    oklch(88% 0.110 106)
    comment: '#7C9A8E', //       oklch(66% 0.038 168)
    field: '#CFBE7E', //         oklch(80% 0.085 95)
    identifier: '#DFE7E0', //    oklch(92% 0.012 150)
    punctuation: '#96A29A', //   oklch(70% 0.018 158)
  },
};

const UI = {
  light: {
    page: '#EFF5F2', surface: '#F7FAF8', stone: '#E1E9E4', stone2: '#D6DFD9',
    ink: '#0B251D', ink2: '#2C433A', ink3: '#4A5D56',
    emerald: '#005037', accent: '#00422C',
    brass: '#95753C', brassBright: '#C3A76B', brassInk: '#744C0E',
    correction: '#9E2D28', ok: '#006432', info: '#0059A2',
    selection: '#BFE6D0', caretRow: '#F0F5F2', hairline: '#E0DDD1',
    edge: '#BFCBC4', // oklch(83% 0.016 162)
    onAccent: '#FFFFFF',
  },
  dark: {
    page: '#0E1C17', surface: '#16251F', stone: '#20312A', stone2: '#2D3F38',
    ink: '#E2EAE4', ink2: '#B8C5BC', ink3: '#8C9991',
    emerald: '#81CEA2', accent: '#81CEA2',
    brass: '#B9995F', brassBright: '#D1B473', brassInk: '#D8BA79',
    correction: '#EB8373', ok: '#6EEEAB', info: '#5EB6E6',
    selection: '#144433', caretRow: '#1C2D26', hairline: '#3A3F30',
    edge: '#2D3F38', // the stone2 rung, which already measures right
    onAccent: '#0E1C17',
  },
};

/**
 * The terminal.
 *
 * SAFF is a green-and-brass world with one red, and ANSI needs eight hues no
 * matter what the brand thinks. Black, red, green, yellow and white come from
 * the book's console. Blue, magenta and cyan are chosen at the same lightness
 * and chroma discipline so they sit in the family without pretending the
 * palette contains them. On a pale ground "bright" cannot mean lighter — that
 * would read as fainter — so bright is darker and more saturated there.
 */
const TERM = {
  light: {
    ground: '#D5E1DB', ink: '#142922', dim: '#52645D',
    prompt: '#744C0E', command: '#021911', pass: '#006432', fail: '#9E2D28',
    ref: '#7A5800', path: '#1A6444', caret: '#005E29',
    ansi: {
      black: '#1E332B', red: '#9E2D28', green: '#006432', yellow: '#7A5800',
      blue: '#0059A2', magenta: '#8A2A7B', cyan: '#006670', white: '#616F68',
      brightBlack: '#52625B', brightRed: '#860009', brightGreen: '#004D1C',
      brightYellow: '#683D00', brightBlue: '#00408E', brightMagenta: '#730065',
      brightCyan: '#004F5A', brightWhite: '#25312B',
    },
  },
  dark: {
    ground: '#0E1C17', ink: '#CDD8CE', dim: '#909C93',
    prompt: '#C3A76B', command: '#F1F7F2', pass: '#6EEEAB', fail: '#F17166',
    ref: '#E8C67D', path: '#A4D1AC', caret: '#76E5AD',
    ansi: {
      black: '#2D3F38', red: '#F17166', green: '#6EEEAB', yellow: '#E8C67D',
      blue: '#5EB6E6', magenta: '#D58ECF', cyan: '#6AC9CE', white: '#CFDBD1',
      brightBlack: '#5E7369', brightRed: '#FF8B7E', brightGreen: '#83FFBE',
      brightYellow: '#FDD990', brightBlue: '#78D0FF', brightMagenta: '#F0A7E9',
      brightCyan: '#85E3E8', brightWhite: '#F1F7F2',
    },
  },
};

/**
 * Where machine output is painted, on every surface.
 *
 * The console used to sit at `oklch(11% …)` in dark, and that is why it read as
 * plain black: the sRGB chroma ceiling at that lightness is 0.023, so no amount
 * of chroma could make the green visible. It is a ceiling, not a choice. The
 * page rung doubles it to 0.042 and the green reads.
 *
 * Dark now agrees exactly — the book's whole dark ladder was lifted so its
 * console could come up to this value, so `TERM.dark.ground === TERMINAL_GROUND
 * .dark`. Light still differs: its console is a slab recessed inside a white
 * page, and its page rung is already near white, so there is nowhere for the two
 * to meet. `assertMatchesBook` keeps `TERM[mode].ground` honest either way.
 */
const TERMINAL_GROUND = { light: UI.light.page, dark: UI.dark.page };


/**
 * The block ladder, all of it brighter than the ground in both modes.
 *
 * These were hand-picked hexes sitting a shade off the old near-black ground.
 * A hand-picked hex does not move when the ground moves: with the terminal on
 * the page rung the dark ones would have gone *darker* than their ground while
 * the selected block went lighter, so hover and selection pointed opposite ways.
 * Derived from the ladder now, so they follow the ground wherever it goes.
 */
const TERMINAL_BLOCK = { light: UI.light.surface, dark: UI.dark.surface };
const TERMINAL_HOVER = {
  light: '#F3F7F5', // oklch(97.3% 0.005 165)  midway page -> surface
  dark: '#12201B', //  oklch(23% 0.023 169)    midway page -> surface
};

/**
 * And the terminal's selection is not the book's selection either.
 *
 * `UI.light.selection` sits 3.0 OKLab units from the console slab — against the
 * dark theme's 14.2 it is barely a wash at all, and on the page ground it only
 * reaches 7.5. This is a light-specific problem: a pale ground leaves almost no
 * room below it, so the selection has to buy its visibility with chroma rather
 * than lightness. There is plenty to spend — the ceiling at L86 is 0.201 and
 * this uses 0.060 — which is the opposite of the syntax roles' predicament at
 * reading lightness. Measured, like everything else here.
 */
/** src over dst at `a`. `dim` is a composite, so it belongs to a ground. */
const composite = (src, dst, a) => {
  const ch = (h, i) => Number.parseInt(h.slice(1 + i * 2, 3 + i * 2), 16);
  return `#${[0, 1, 2]
    .map((i) => Math.round(a * ch(src, i) + (1 - a) * ch(dst, i)).toString(16).padStart(2, '0'))
    .join('')
    .toUpperCase()}`;
};
const DIM_ALPHA = 0.68;
const TERMINAL_DIM = Object.fromEntries(
  ['light', 'dark'].map((m) => [m, composite(TERM[m].ink, TERMINAL_GROUND[m], DIM_ALPHA)]),
);

const TERMINAL_SELECTION = {
  light: '#B1DEC2', // oklch(86% 0.060 158)  dE 11.7 from the ground
  dark: UI.dark.selection, //                dE 14.2, already correct
};

// ── Guard: the themes may not drift from what the book renders ───────────────

function assertMatchesBook() {
  const src = readFileSync(join(HERE, '../web/src/lib/saff/palette.ts'), 'utf8');
  const section = (name) => {
    const i = src.indexOf(`export const ${name}`);
    return src.slice(i, src.indexOf('};', i));
  };
  const problems = [];
  const check = (block, mode, source, roles) => {
    const text = section(block);
    for (const role of roles) {
      const m = text.match(new RegExp(`\\b${role}:\\s*'(#[0-9A-Fa-f]{6})'`));
      if (!m) problems.push(`${block}.${role} not found in palette.ts`);
      else if (m[1].toUpperCase() !== source[mode][role]) {
        problems.push(`${block}.${role}: book has ${m[1]}, themes have ${source[mode][role]}`);
      }
    }
  };
  const card = Object.keys(SYNTAX.light);
  // `dim` is deliberately absent: it is a composite, so it belongs to whichever
  // ground it is painted on, and the book's console slab is not the terminals'
  // ground. Comparing the literals would only assert that one of them is wrong.
  const term = ['ground', 'ink', 'prompt', 'command', 'pass', 'fail', 'ref', 'path', 'caret'];
  check('cardLight', 'light', SYNTAX, card);
  check('cardDark', 'dark', SYNTAX, card);
  check('consoleLight', 'light', TERM, term);
  check('consoleDark', 'dark', TERM, term);
  // Stronger than comparing hexes: prove the book's `dim` really is its own ink
  // composited over its own ground, so a hand-edit that breaks the rule is caught.
  for (const [block, mode] of [['consoleLight', 'light'], ['consoleDark', 'dark']]) {
    const want = composite(TERM[mode].ink, TERM[mode].ground, DIM_ALPHA);
    const got = section(block).match(/\bdim:\s*'(#[0-9A-Fa-f]{6})'/)?.[1];
    if (got?.toUpperCase() !== want) {
      problems.push(`${block}.dim: book has ${got}, ink at ${DIM_ALPHA} over its ground is ${want}`);
    }
  }
  if (problems.length) {
    console.error(`The editor themes have drifted from the book:\n  ${problems.join('\n  ')}`);
    process.exit(1);
  }
  console.log('palette matches web/src/lib/saff/palette.ts');
}

/**
 * The CSS custom properties must agree with the palette they claim to be.
 *
 * `palette.ts` names its two grounds after the tokens that paint them —
 * `--porcelain-2` for the card, `--console` for the slab — but nothing checked
 * that the tokens still held those values. Lifting the dark ladder moved
 * `--porcelain-2` eight points and split the book's code card from the editor
 * background it is supposed to be identical to; both files stayed internally
 * consistent and every existing assertion passed. This closes that seam.
 */
function assertCssMatchesPalette() {
  const css = readFileSync(join(HERE, '../web/src/app/global.css'), 'utf8');
  // `:root` carries light; `.dark` overrides it. Read each block on its own.
  const block = (name) => {
    const i = css.indexOf(name);
    return css.slice(i, css.indexOf('\n}', i));
  };
  const value = (text, token) =>
    text.match(new RegExp(`--${token}:\\s*(oklch\\([^)]*\\));`))?.[1];

  const problems = [];
  for (const [mode, scope] of [['light', ':root {'], ['dark', '.dark {']]) {
    for (const [token, hex, what] of [
      ['porcelain-2', SYNTAX[mode].ground, 'the editor ground'],
      ['console', TERM[mode].ground, 'the terminal ground'],
    ]) {
      const declared = value(block(scope), token);
      if (!declared) {
        problems.push(`${scope} --${token} not found in global.css`);
      } else if (measured(declared) !== hex) {
        problems.push(
          `${scope} --${token} is ${declared} = ${measured(declared) ?? '?'}, but ${what} is ${hex}`,
        );
      }
    }
  }
  if (problems.length) {
    console.error(
      `global.css and palette.ts disagree about a ground:\n  ${problems.join('\n  ')}`,
    );
    process.exit(1);
  }
  console.log('global.css grounds match the palette');
}

/**
 * OKLCH strings are compared through a table of values measured in a browser,
 * never converted — several roles fall outside sRGB and Chrome clips per channel
 * rather than reducing chroma, so converting would disagree with the page.
 */
const MEASURED = {
  'oklch(98.2% 0.004 165)': '#F7FAF8',
  'oklch(25% 0.024 168)': '#16251F',
  'oklch(90% 0.016 162)': '#D5E1DB',
  'oklch(21% 0.022 170)': '#0E1C17',
};
const measured = (s) => MEASURED[s.replace(/\s+/g, ' ').trim()];

// ── IntelliJ colour scheme (.icls) ───────────────────────────────────────────

const BOLD = 1;
const ITALIC = 2;
const BOLD_ITALIC = 3;
const bare = (hex) => hex.replace('#', '').toLowerCase();

/**
 * Every key a complete scheme names, with the SAFF role each takes.
 *
 * This table is the whole point of the file. A scheme only decides the keys it
 * names; anything else falls through to `parent_scheme`, and the light and dark
 * parents are unrelated stock palettes. Leaving `GO_PACKAGE` unset is how
 * package names ended up a different colour in each theme — the `DEFAULT_*`
 * fallback chain does not reach every language's own keys.
 */
const KEYS = JSON.parse(readFileSync(join(HERE, 'intellij-keys.json'), 'utf8'));

const SYNTAX_ROLES = new Set([
  'keyword', 'fn', 'type', 'string', 'number', 'interpolation',
  'annotation', 'comment', 'field', 'identifier', 'punctuation',
]);

function syntaxAttributes(mode) {
  const s = SYNTAX[mode];
  const out = {};
  for (const [key, role] of Object.entries(KEYS.attributes)) {
    if (role === 'base') {
      out[key] = { FOREGROUND: s.identifier, BACKGROUND: UI[mode].surface };
    } else if (SYNTAX_ROLES.has(role)) {
      out[key] = {
        FOREGROUND: s[role],
        ...(role === 'keyword' ? { FONT_TYPE: BOLD } : {}),
        ...(role === 'comment' ? { FONT_TYPE: ITALIC } : {}),
      };
    }
  }
  return out;
}

/** Console and log output, mapped role by role rather than by pattern. */
function terminalAttributes(mode) {
  const t = TERM[mode];
  const a = t.ansi;
  const tg = TERMINAL_GROUND[mode];
  const td = TERMINAL_DIM[mode];
  const pairs = {
    CONSOLE_NORMAL_OUTPUT: t.ink, CONSOLE_USER_INPUT: t.command,
    CONSOLE_SYSTEM_OUTPUT: td, CONSOLE_ERROR_OUTPUT: t.fail,
    CONSOLE_BLACK_OUTPUT: a.black, CONSOLE_RED_OUTPUT: a.red,
    CONSOLE_GREEN_OUTPUT: a.green, CONSOLE_YELLOW_OUTPUT: a.yellow,
    CONSOLE_BLUE_OUTPUT: a.blue, CONSOLE_MAGENTA_OUTPUT: a.magenta,
    CONSOLE_CYAN_OUTPUT: a.cyan, CONSOLE_GRAY_OUTPUT: a.white,
    CONSOLE_DARKGRAY_OUTPUT: a.brightBlack, CONSOLE_WHITE_OUTPUT: a.brightWhite,
    CONSOLE_RED_BRIGHT_OUTPUT: a.brightRed, CONSOLE_GREEN_BRIGHT_OUTPUT: a.brightGreen,
    CONSOLE_YELLOW_BRIGHT_OUTPUT: a.brightYellow, CONSOLE_BLUE_BRIGHT_OUTPUT: a.brightBlue,
    CONSOLE_MAGENTA_BRIGHT_OUTPUT: a.brightMagenta, CONSOLE_CYAN_BRIGHT_OUTPUT: a.brightCyan,
    LOG_ERROR_OUTPUT: t.fail, LOG_WARNING_OUTPUT: a.yellow, LOG_INFO_OUTPUT: t.ink,
    LOG_DEBUG_OUTPUT: td, LOG_VERBOSE_OUTPUT: td, LOG_EXPIRED_ENTRY: td,
    LOGCAT_ASSERT_OUTPUT: t.fail, LOGCAT_ERROR_OUTPUT: t.fail,
    LOGCAT_WARNING_OUTPUT: a.yellow, LOGCAT_INFO_OUTPUT: t.ink,
    LOGCAT_DEBUG_OUTPUT: td, LOGCAT_VERBOSE_OUTPUT: td,
    // The Terminal tool window is not the console. It reads its own
    // BLOCK_TERMINAL_* keys, so CONSOLE_* alone leaves it on the parent scheme.
    BLOCK_TERMINAL_BLACK: a.black, BLOCK_TERMINAL_BLACK_BRIGHT: a.brightBlack,
    BLOCK_TERMINAL_RED: a.red, BLOCK_TERMINAL_RED_BRIGHT: a.brightRed,
    BLOCK_TERMINAL_GREEN: a.green, BLOCK_TERMINAL_GREEN_BRIGHT: a.brightGreen,
    BLOCK_TERMINAL_YELLOW: a.yellow, BLOCK_TERMINAL_YELLOW_BRIGHT: a.brightYellow,
    BLOCK_TERMINAL_BLUE: a.blue, BLOCK_TERMINAL_BLUE_BRIGHT: a.brightBlue,
    BLOCK_TERMINAL_MAGENTA: a.magenta, BLOCK_TERMINAL_MAGENTA_BRIGHT: a.brightMagenta,
    BLOCK_TERMINAL_CYAN: a.cyan, BLOCK_TERMINAL_CYAN_BRIGHT: a.brightCyan,
    BLOCK_TERMINAL_WHITE: a.white, BLOCK_TERMINAL_WHITE_BRIGHT: a.brightWhite,
    BLOCK_TERMINAL_COMMAND: t.command,
    BLOCK_TERMINAL_GENERATE_COMMAND_PROMPT_TEXT: t.prompt,
    TERMINAL_COMMAND_TO_RUN_USING_IDE: t.prompt,
  };
  // Search hits are a background wash, so they cannot come from `pairs`.
  const highlights = {
    BLOCK_TERMINAL_SEARCH_ENTRY: { BACKGROUND: TERMINAL_SELECTION[mode], FOREGROUND: t.ink },
    BLOCK_TERMINAL_CURRENT_SEARCH_ENTRY: { BACKGROUND: t.ref, FOREGROUND: tg },
  };
  const out = { ...highlights };
  for (const [k, v] of Object.entries(pairs)) if (k in KEYS.attributes) out[k] = { FOREGROUND: v };
  for (const [k, role] of Object.entries(KEYS.attributes)) {
    if (role === 'terminal' && !(k in out) && !/BACKGROUND|_BG$/.test(k)) out[k] = { FOREGROUND: t.ink };
  }
  return out;
}

/**
 * Diagnostics, search and the editor's own marks.
 *
 * These want an effect colour or a background rather than a foreground, so they
 * are written out by hand — a foreground-only rule would make a search hit
 * invisible instead of highlighted.
 */
function editorMarkAttributes(mode) {
  const u = UI[mode];
  const wave = (color) => ({ EFFECT_COLOR: color, EFFECT_TYPE: 2 });
  return {
    ERRORS_ATTRIBUTES: wave(u.correction),
    WARNING_ATTRIBUTES: wave(u.brassInk),
    WEAK_WARNING_ATTRIBUTES: wave(u.brass),
    INFO_ATTRIBUTES: wave(u.info),
    GENERIC_SERVER_ERROR_OR_WARNING: wave(u.brassInk),
    TYPO: wave(u.brass),
    BAD_CHARACTER: { BACKGROUND: u.correction, FOREGROUND: u.onAccent },
    WRONG_REFERENCES_ATTRIBUTES: wave(u.correction),
    RUNTIME_ERROR: wave(u.correction),
    DEPRECATED_ATTRIBUTES: { EFFECT_COLOR: u.ink3, EFFECT_TYPE: 3 },
    MARKED_FOR_REMOVAL_ATTRIBUTES: { EFFECT_COLOR: u.correction, EFFECT_TYPE: 3 },
    NOT_USED_ELEMENT_ATTRIBUTES: { FOREGROUND: u.ink3 },
    TEXT_SEARCH_RESULT_ATTRIBUTES: { BACKGROUND: u.selection },
    SEARCH_RESULT_ATTRIBUTES: { BACKGROUND: u.selection },
    WRITE_SEARCH_RESULT_ATTRIBUTES: { BACKGROUND: u.selection },
    IDENTIFIER_UNDER_CARET_ATTRIBUTES: { BACKGROUND: u.caretRow },
    WRITE_IDENTIFIER_UNDER_CARET_ATTRIBUTES: { BACKGROUND: u.caretRow },
    MATCHED_BRACE_ATTRIBUTES: { BACKGROUND: u.selection, FONT_TYPE: BOLD },
    UNMATCHED_BRACE_ATTRIBUTES: { BACKGROUND: u.correction, FOREGROUND: u.onAccent },
    FOLDED_TEXT_ATTRIBUTES: { FOREGROUND: u.ink3, BACKGROUND: u.stone },
    TODO_DEFAULT_ATTRIBUTES: { FOREGROUND: u.brassInk, FONT_TYPE: BOLD_ITALIC },
    HYPERLINK_ATTRIBUTES: { FOREGROUND: u.brassInk, EFFECT_COLOR: u.brassInk, EFFECT_TYPE: 1 },
    FOLLOWED_HYPERLINK_ATTRIBUTES: { FOREGROUND: u.brass, EFFECT_COLOR: u.brass, EFFECT_TYPE: 1 },
    INACTIVE_HYPERLINK_ATTRIBUTES: { FOREGROUND: u.ink3 },
    CTRL_CLICKABLE: { FOREGROUND: u.brassInk, EFFECT_COLOR: u.brassInk, EFFECT_TYPE: 1 },
    BREADCRUMBS_DEFAULT: { FOREGROUND: u.ink3 },
    BREADCRUMBS_HOVERED: { FOREGROUND: u.ink },
    BREADCRUMBS_CURRENT: { FOREGROUND: u.ink },
    BREADCRUMBS_INACTIVE: { FOREGROUND: u.ink3 },
    // Also `hint` in the table, but this emitter runs last and claims them, so
    // the slant has to be repeated here or three of the five hints stay upright.
    INLINE_PARAMETER_HINT: { FOREGROUND: u.ink3, BACKGROUND: u.stone, FONT_TYPE: ITALIC },
    INLINE_PARAMETER_HINT_CURRENT: { FOREGROUND: u.ink, BACKGROUND: u.stone2, FONT_TYPE: ITALIC },
    INLINE_PARAMETER_HINT_HIGHLIGHTED: { FOREGROUND: u.ink, BACKGROUND: u.stone2, FONT_TYPE: ITALIC },
    DIFF_INSERTED: { BACKGROUND: mode === 'light' ? '#DEEFE3' : '#17331F' },
    DIFF_DELETED: { BACKGROUND: mode === 'light' ? '#F6E0DE' : '#3A1F1D' },
    DIFF_MODIFIED: { BACKGROUND: mode === 'light' ? '#E6E7F5' : '#1E2A3A' },
    DIFF_CONFLICT: { BACKGROUND: mode === 'light' ? '#F7E9CF' : '#3A2E17' },
  };
}

/**
 * Roles the three specific emitters do not claim.
 *
 * Without this every `chrome`, `vcs` and `diagnostic` key in the table was
 * dropped on the floor — named in intellij-keys.json, absent from both schemes,
 * and therefore taking its colour from `parent_scheme`. The assertion below now
 * refuses to write if any table key goes unemitted.
 */
function fallbackAttributes(mode) {
  const u = UI[mode];
  const byRole = {
    diagnostic: { EFFECT_COLOR: u.correction, EFFECT_TYPE: 2 },
    vcs: { FOREGROUND: u.ink3 },
    chrome: { FOREGROUND: u.ink3 },
    // Inlay hints are the compiler talking, not the author, and italic is how
    // this palette already says that - it is what comments wear. They were part
    // of `chrome` before, which also holds matched braces, search results and
    // the rainbow indent guides; none of those wants a slant.
    hint: { FOREGROUND: u.ink3, FONT_TYPE: ITALIC },
  };
  const out = {};
  for (const [key, role] of Object.entries(KEYS.attributes)) {
    if (!(role in byRole)) continue;
    // A key whose name ends in BACKGROUND wants a ground as well as an ink —
    // except INLAY_TEXT_WITHOUT_BACKGROUND and its kind, which are foregrounds
    // whose names merely end in the word. Getting that wrong is not cosmetic:
    // CodeVisionThemeInfoProvider does a Kotlin null-check on this key's
    // foreground, so a missing one throws inside EditorPainter and aborts the
    // paint, leaving the previous frame's pixels on screen.
    const wantsGround = /_BACKGROUND$|_BG$/.test(key) && !/WITHOUT_BACKGROUND$/.test(key);
    out[key] = wantsGround
      ? { FOREGROUND: u.ink3, BACKGROUND: u.stone }
      : byRole[role];
  }
  return out;
}

function allAttributes(mode) {
  return {
    ...fallbackAttributes(mode),
    ...syntaxAttributes(mode),
    ...terminalAttributes(mode),
    ...editorMarkAttributes(mode),
  };
}

/**
 * Nothing the IDE registers may go unnamed.
 *
 * `ide-keys.txt` is what GoLand's own bytecode declares, read out by
 * extract-keys.mjs. Checking against it is the only way to catch the failure
 * that produced this file's whole design: an unnamed key does not error, it
 * inherits from `parent_scheme` — Default under light, Darcula under dark — so
 * Go structs came out gold in one theme and plain black in the other, and every
 * check we had still passed.
 */
function assertIdeKeysAreNamed(mode, attributes, colors) {
  let declared;
  try {
    declared = readFileSync(join(HERE, 'ide-keys.txt'), 'utf8');
  } catch {
    return; // the reference list is optional; regenerate it with extract-keys.mjs
  }
  const missing = declared
    .split('\n')
    .filter(Boolean)
    .map((line) => line.split('\t'))
    .filter(([, key]) => !(key in attributes) && !(key in colors))
    .map(([kind, key]) => `${kind} ${key}`);
  if (missing.length) {
    console.error(
      `SAFF ${mode} leaves ${missing.length} IDE keys to the parent scheme:\n  ${missing.join('\n  ')}`,
    );
    process.exit(1);
  }
}

/** No key may be listed in the table and then quietly left out of the scheme. */
function assertTableIsFullyEmitted(mode, attributes, colors) {
  const missing = Object.keys(KEYS.attributes).filter((k) => !(k in attributes) && !(k in colors));
  if (missing.length) {
    console.error(
      `SAFF ${mode} lists ${missing.length} keys it never writes, so they fall through to the parent scheme:\n  ${missing.join('\n  ')}`,
    );
    process.exit(1);
  }
}

function iclsAttributes(mode) {
  const merged = allAttributes(mode);
  return Object.keys(merged)
    .sort()
    .map((key) => {
      const body = Object.entries(merged[key])
        .map(([k, v]) => `        <option name="${k}" value="${typeof v === 'number' ? v : bare(v)}" />`)
        .join('\n');
      return `    <option name="${key}">\n      <value>\n${body}\n      </value>\n    </option>`;
    })
    .join('\n');
}

/**
 * The `<colors>` section — single values rather than text attributes.
 *
 * These are as load-bearing as the attributes and were the second half of the
 * same mistake: naming 18 of the 86 keys a complete scheme names left
 * TERMINAL_BACKGROUND unset, so the Terminal tool window kept the parent
 * scheme's black no matter which SAFF theme was selected.
 */
function iclsColors(mode) {
  const u = UI[mode];
  const s = SYNTAX[mode];
  const t = TERM[mode];
  const tg = TERMINAL_GROUND[mode];
  const caret = mode === 'light' ? u.brassInk : u.brassBright;
  const fade = mode === 'light' ? '#0000000D' : '#FFFFFF0D';
  return {
    // Editor ground and marks
    BACKGROUND: u.surface,
    FOREGROUND: s.identifier,
    CARET_COLOR: caret,
    CARET_ROW_COLOR: u.caretRow,
    SELECTION_BACKGROUND: u.selection,
    SELECTION_FOREGROUND: u.ink,
    GUTTER_BACKGROUND: u.surface,
    INDENT_GUIDE: u.hairline,
    SELECTED_INDENT_GUIDE: u.brass,
    VISUAL_INDENT_GUIDE: u.hairline,
    MATCHED_BRACES_INDENT_GUIDE_COLOR: u.brass,
    WHITESPACES_INDENT_GUIDE: u.hairline,
    LINE_NUMBERS_COLOR: s.punctuation,
    LINE_NUMBER_ON_CARET_ROW_COLOR: caret,
    RIGHT_MARGIN_COLOR: u.hairline,
    WHITESPACES: u.stone2,
    TEARLINE_COLOR: u.hairline,
    SELECTED_TEARLINE_COLOR: u.brass,
    METHOD_SEPARATORS_COLOR: u.hairline,
    SEPARATOR_BELOW_COLOR: u.hairline,
    FOLDED_TEXT_BORDER_COLOR: u.stone2,
    ERROR_STRIPE_COLOR: u.correction,
    EFFECT_COLOR: u.brass,
    EFFECT_TYPE: '0',
    FONT_TYPE: '0',
    ANNOTATIONS_COLOR: u.ink3,
    DOC_COMMENT_LINK: u.brassInk,
    DOCUMENTATION_COLOR: u.stone,
    LOOKUP_COLOR: u.stone,
    NOTIFICATION_BACKGROUND: u.stone,
    PROMOTION_PANE: u.stone,
    RECENT_LOCATIONS_SELECTION: u.selection,
    MODIFIED_TAB_ICON: u.brass,
    TAB_UNDERLINE: caret,
    TAB_UNDERLINE_INACTIVE: u.brass,
    ERROR_HINT: u.correction,
    INFORMATION_HINT: u.stone,
    QUESTION_HINT: u.stone,
    INLINE_REFACTORING_SETTINGS_DEFAULT: u.stone,
    INLINE_REFACTORING_SETTINGS_FOCUSED: u.stone2,
    INLINE_REFACTORING_SETTINGS_HOVERED: u.stone2,

    // Both terminals. CONSOLE_BACKGROUND_KEY is the Run/Debug console;
    // TERMINAL_BACKGROUND and the BLOCK_TERMINAL_* pair are the tool window.
    CONSOLE_BACKGROUND_KEY: tg,
    TERMINAL_BACKGROUND: tg,
    BLOCK_TERMINAL_DEFAULT_BACKGROUND: tg,
    BLOCK_TERMINAL_DEFAULT_FOREGROUND: t.ink,
    BLOCK_TERMINAL_BLOCK_BACKGROUND_START: tg,
    BLOCK_TERMINAL_BLOCK_BACKGROUND_END: tg,
    BLOCK_TERMINAL_SELECTED_BLOCK_BACKGROUND: TERMINAL_BLOCK[mode],
    BLOCK_TERMINAL_INACTIVE_SELECTED_BLOCK_BACKGROUND: tg,
    BLOCK_TERMINAL_SELECTED_BLOCK_STROKE_COLOR: t.prompt,
    BLOCK_TERMINAL_INACTIVE_SELECTED_BLOCK_STROKE_COLOR: TERMINAL_DIM[mode],
    BLOCK_TERMINAL_ERROR_BLOCK_STROKE_COLOR: t.fail,
    BLOCK_TERMINAL_PROMPT_SEPARATOR_COLOR: TERMINAL_DIM[mode],
    BLOCK_TERMINAL_HOVERED_BLOCK_BACKGROUND_START: TERMINAL_HOVER[mode],
    BLOCK_TERMINAL_HOVERED_BLOCK_BACKGROUND_END: TERMINAL_HOVER[mode],
    BLOCK_TERMINAL_GENERATE_COMMAND_PLACEHOLDER_FOREGROUND: TERMINAL_DIM[mode],
    BLOCK_TERMINAL_GENERATE_COMMAND_CARET_COLOR: t.caret,

    // Version control
    ADDED_LINES_COLOR: u.ok,
    DELETED_LINES_COLOR: u.correction,
    MODIFIED_LINES_COLOR: u.brass,
    WHITESPACES_MODIFIED_LINES_COLOR: u.brass,
    DIFF_SEPARATORS_BACKGROUND: u.hairline,
    FILESTATUS_ADDED: u.ok,
    FILESTATUS_COPIED: u.ok,
    FILESTATUS_DELETED: u.ink3,
    FILESTATUS_MODIFIED: u.brassInk,
    FILESTATUS_MERGED: u.brass,
    FILESTATUS_SWITCHED: u.info,
    FILESTATUS_UNKNOWN: u.correction,
    FILESTATUS_HIJACKED: u.brass,
    FILESTATUS_SUPPRESSED: u.ink3,
    FILESTATUS_NOT_CHANGED_IMMEDIATE: u.emerald,
    FILESTATUS_NOT_CHANGED_RECURSIVE: u.emerald,
    'FILESTATUS_IGNORE.PROJECT_VIEW.IGNORED': u.ink3,
    FILESTATUS_IDEA_FILESTATUS_IGNORED: u.ink3,
    FILESTATUS_IDEA_FILESTATUS_DELETED_FROM_FILE_SYSTEM: u.ink3,
    FILESTATUS_IDEA_FILESTATUS_MERGED_WITH_CONFLICTS: u.correction,
    FILESTATUS_IDEA_FILESTATUS_MERGED_WITH_BOTH_CONFLICTS: u.correction,
    FILESTATUS_IDEA_FILESTATUS_MERGED_WITH_PROPERTY_CONFLICTS: u.correction,
    FILESTATUS_IDEA_SVN_FILESTATUS_EXTERNAL: u.ok,
    VCS_ANNOTATIONS_COLOR_1: u.stone,
    VCS_ANNOTATIONS_COLOR_2: u.surface,
    VCS_ANNOTATIONS_COLOR_3: u.stone,
    VCS_ANNOTATIONS_COLOR_4: u.surface,
    VCS_ANNOTATIONS_COLOR_5: u.stone,

    // Everything else the IDE registers as a ColorKey — diagram editor, inline
    // suggestion chrome, image editor. Named so it cannot inherit from Default
    // in one theme and Darcula in the other.
    ...Object.fromEntries(
      Object.entries(KEYS.colors ?? {}).map(([key, role]) => [key, u[role] ?? u.ink3]),
    ),

    // Markup nesting: a ladder of washes, not five separate hues.
    HTML_TAG_TREE_LEVEL0: fade,
    HTML_TAG_TREE_LEVEL1: fade,
    HTML_TAG_TREE_LEVEL2: fade,
    HTML_TAG_TREE_LEVEL3: fade,
    HTML_TAG_TREE_LEVEL4: fade,
    HTML_TAG_TREE_LEVEL5: fade,
  };
}

/**
 * The keys the Terminal tool window reads, verified against
 * `com/intellij/terminal/BlockTerminalColors` in GoLand 2026.2.
 *
 * The reworked terminal does not read `CONSOLE_*`. Naming only those left the
 * tool window on the parent scheme's black under SAFF Light, which is the whole
 * reason this list is asserted rather than trusted.
 */
const TERMINAL_COLOR_KEYS = [
  'BLOCK_TERMINAL_DEFAULT_FOREGROUND', 'BLOCK_TERMINAL_DEFAULT_BACKGROUND',
  'BLOCK_TERMINAL_BLOCK_BACKGROUND_START', 'BLOCK_TERMINAL_BLOCK_BACKGROUND_END',
  'BLOCK_TERMINAL_SELECTED_BLOCK_BACKGROUND', 'BLOCK_TERMINAL_SELECTED_BLOCK_STROKE_COLOR',
  'BLOCK_TERMINAL_HOVERED_BLOCK_BACKGROUND_START', 'BLOCK_TERMINAL_HOVERED_BLOCK_BACKGROUND_END',
  'BLOCK_TERMINAL_INACTIVE_SELECTED_BLOCK_BACKGROUND',
  'BLOCK_TERMINAL_INACTIVE_SELECTED_BLOCK_STROKE_COLOR',
  'BLOCK_TERMINAL_ERROR_BLOCK_STROKE_COLOR', 'BLOCK_TERMINAL_PROMPT_SEPARATOR_COLOR',
  'BLOCK_TERMINAL_GENERATE_COMMAND_PLACEHOLDER_FOREGROUND',
  'BLOCK_TERMINAL_GENERATE_COMMAND_CARET_COLOR',
];

const TERMINAL_ATTRIBUTE_KEYS = [
  ...['BLACK', 'RED', 'GREEN', 'YELLOW', 'BLUE', 'MAGENTA', 'CYAN', 'WHITE']
    .flatMap((c) => [`BLOCK_TERMINAL_${c}`, `BLOCK_TERMINAL_${c}_BRIGHT`]),
  'BLOCK_TERMINAL_COMMAND', 'BLOCK_TERMINAL_SEARCH_ENTRY',
  'BLOCK_TERMINAL_CURRENT_SEARCH_ENTRY', 'BLOCK_TERMINAL_GENERATE_COMMAND_PROMPT_TEXT',
  // The classic terminal and the Run console, which read these instead.
  'CONSOLE_NORMAL_OUTPUT', 'CONSOLE_ERROR_OUTPUT',
];

function assertTerminalIsCovered(mode, colors, attributes) {
  const missing = [
    ...TERMINAL_COLOR_KEYS.filter((k) => !(k in colors)).map((k) => `<colors> ${k}`),
    ...TERMINAL_ATTRIBUTE_KEYS.filter((k) => !(k in attributes)).map((k) => `<attributes> ${k}`),
  ];
  if (missing.length) {
    console.error(
      `SAFF ${mode} does not colour the terminal; these fall through to the parent scheme:\n  ${missing.join('\n  ')}`,
    );
    process.exit(1);
  }
}

function icls(mode) {
  const name = mode === 'light' ? 'SAFF Light' : 'SAFF Dark';
  assertTerminalIsCovered(mode, iclsColors(mode), allAttributes(mode));
  assertTableIsFullyEmitted(mode, allAttributes(mode), iclsColors(mode));
  assertIdeKeysAreNamed(mode, allAttributes(mode), iclsColors(mode));
  const body = Object.entries(iclsColors(mode))
    .map(([k, v]) => `    <option name="${k}" value="${/^[0-9]$/.test(v) ? v : bare(v)}" />`)
    .join('\n');
  return `<?xml version="1.0" encoding="UTF-8"?>
<!--
  ${name} — the colour scheme of "Learn Dart with Tests".

  Generated by editor-themes/generate.mjs. Edit that, not this.

  Both schemes name the identical key set. A scheme only decides the keys it
  names, and anything else falls through to \`parent_scheme\` — which for light
  and dark are two unrelated stock palettes. That is how a language key like
  GO_PACKAGE ends up a different colour in each theme.
-->
<scheme name="${name}" version="142" parent_scheme="${mode === 'light' ? 'Default' : 'Darcula'}">
  <metaInfo>
    <property name="created">${new Date().toISOString().slice(0, 10)}</property>
    <property name="ide">idea</property>
  </metaInfo>
  <colors>
${body}
  </colors>
  <attributes>
${iclsAttributes(mode)}
  </attributes>
</scheme>
`;
}

// ── IntelliJ UI theme (.theme.json) ──────────────────────────────────────────

/**
 * The IDE frame. A colour scheme cannot touch any of this — the toolbar, tool
 * windows, tabs and status bar only change through a theme plugin.
 *
 * Chrome is stone: the frame sits a step below the editor so the editor lifts
 * off it, the same relationship the book's card has with its page.
 */
/**
 * Islands geometry, taken from the platform's own themes so the two agree.
 *
 * `borderWidth` is not a stroke: it is the ring the island paints in its own
 * colour, which is why `Island.borderColor` is the island and not the ground.
 */
const ISLAND_GEOMETRY = {
  arc: 20, 'arc.compact': 16,
  borderArcLength: 14, 'borderArcLength.compact': 10,
  borderWidth: 6, 'borderWidth.compact': 4,
  inactiveAlpha: 0.56, toolWindowAlpha: 0.2,
};

/**
 * A seam and an outline are not the same colour, and `hairline` was only ever
 * one of them.
 *
 * `hairline` is the book's rule — a brass line drawn *on* a page. The theme
 * reused it for every border the IDE has, so the seam between two panels was
 * painted at OKLab dE 7.0 from the light page and 14.8 from the dark one, the
 * dark case louder than that theme's own selection wash (14.2). JetBrains draws
 * the same seam at 3.6-5.7 and keeps a second, much stronger colour for the
 * edges of controls, at 13.4 (light) and 13.8 (dark). Two jobs, two colours.
 *
 *   seam     light `stone`   dE 3.8 from the page, 5.6 from the editor
 *            dark  `surface` dE 3.7 from the page, 0 from the editor
 *   outline  light `edge`    dE 13.4 from the page   (new; the ladder had no rung there)
 *            dark  `edge`    dE 13.8 from the page   (the stone2 rung, measured)
 *
 * `hairline` keeps the job it was tuned for: rules drawn inside the editor —
 * indent guides, the right margin, method separators.
 */
function themeJson(mode, islands = false) {
  const u = UI[mode];
  const t = TERM[mode];
  const theme = {
    name: mode === 'light' ? 'SAFF Light' : 'SAFF Dark',
    dark: mode === 'dark',
    author: 'Learn Dart with Tests',
    editorScheme: `/themes/saff-${mode}.xml`,
    colors: {
      base: u.page,
      surface: u.stone,
      surface2: u.stone2,
      // Anything that floats - a popup, a menu, a balloon. `surface` cannot do
      // this job: it is the chrome tone, which is *darker* than the page in
      // light and lighter in dark, so popups sank in one theme and rose in the
      // other. Lifted means lighter in both.
      raised: mode === 'light' ? u.surface : u.stone,
      editorGround: u.surface,
      text: u.ink,
      textMuted: u.ink3,
      accent: mode === 'light' ? u.brassInk : u.brassBright,
      accentQuiet: u.brass,
      emerald: u.emerald,
      border: mode === 'light' ? u.stone : u.surface,
      outline: u.edge,
      selection: u.selection,
      hover: u.caretRow,
      onAccent: u.onAccent,
      error: u.correction,
      terminalGround: TERMINAL_GROUND[mode],
      terminalInk: t.ink,
    },
    ui: {
      '*': {
        foreground: 'text',
        background: 'base',
        infoForeground: 'textMuted',
        disabledForeground: 'textMuted',
        disabledBackground: 'base',
        inactiveBackground: 'base',
        selectionBackground: 'selection',
        selectionForeground: 'text',
        selectionInactiveBackground: 'surface2',
        selectionInactiveForeground: 'text',
        separatorColor: 'border',
        borderColor: 'border',
        focusColor: 'accent',
        focusedBorderColor: 'accent',
        acceleratorForeground: 'accent',
      },
      Borders: { color: 'border', ContrastBorderColor: 'border' },
      ToolWindow: {
        Header: { background: 'surface', inactiveBackground: 'base' },
        HeaderTab: { selectedInactiveBackground: 'surface2', selectedBackground: 'surface2', hoverBackground: 'hover' },
        Button: { hoverBackground: 'hover', selectedBackground: 'surface2', selectedForeground: 'text' },
      },
      DefaultTabs: {
        background: 'surface', hoverBackground: 'hover',
        underlinedTabBackground: 'editorGround', underlinedTabForeground: 'text',
        underlineColor: 'accent', inactiveUnderlineColor: 'accentQuiet', borderColor: 'border',
      },
      EditorTabs: {
        background: 'surface', hoverBackground: 'hover',
        underlinedTabBackground: 'editorGround', underlinedTabForeground: 'text',
        underlineColor: 'accent', inactiveUnderlineColor: 'accentQuiet',
        borderColor: 'border', inactiveColoredFileBackground: 'surface',
      },
      Editor: { background: 'editorGround', shortcutForeground: 'accent' },
      EditorPane: { background: 'editorGround' },
      Panel: { background: 'base', foreground: 'text' },
      Popup: {
        background: 'raised', borderColor: 'outline',
        Header: { activeBackground: 'surface2', inactiveBackground: 'surface' },
      },
      // `'*'` sets `background` on every key that ends in it, `MenuItem.background`
      // included, so naming only `PopupMenu` left the items on the page tone and
      // the popup underneath on another. What looked like a heavy divider between
      // groups was the popup's own background showing through the separator row.
      PopupMenu: { background: 'raised' },
      Menu: { background: 'raised' },
      MenuItem: { background: 'raised' },
      // The button bar is part of the dialog, not a tray under it. Unset, these
      // two fall through to a stock grey that owes nothing to the palette.
      DialogWrapper: { southPanelBackground: 'base', southPanelDivider: 'base' },
      MainToolbar: {
        background: 'surface',
        Dropdown: { hoverBackground: 'hover' },
        Icon: { hoverBackground: 'hover' },
      },
      StatusBar: { background: 'surface', borderColor: 'border' },
      SearchEverywhere: {
        SearchField: { background: 'base', borderColor: 'outline' },
        Tab: { selectedBackground: 'surface2' },
      },
      // `Button.background` fills the component's whole rectangle; the rounded
      // shape is drawn inside it. Set to anything but the panel behind it, it
      // shows as a square patch around every button - which is why the platform's
      // own themes never set it, and let `'*'` hand it the panel's own value.
      // The fill of the shape is `startBackground`/`endBackground`, named here so
      // it comes from the palette rather than from a stock fallback.
      Button: {
        foreground: 'text', arc: 8,
        startBackground: 'raised', endBackground: 'raised',
        startBorderColor: 'outline', endBorderColor: 'outline',
        default: {
          startBackground: 'accent', endBackground: 'accent', foreground: 'onAccent',
          startBorderColor: 'accent', endBorderColor: 'accent',
          focusColor: 'accent', focusedBorderColor: 'accent',
        },
      },
      Component: {
        focusColor: 'accent', focusedBorderColor: 'accent',
        borderColor: 'outline', errorFocusColor: 'error',
      },
      CheckBox: { background: 'base' },
      ComboBox: {
        background: 'base', nonEditableBackground: 'base',
        ArrowButton: { background: 'base', iconColor: 'textMuted' },
      },
      TextField: { background: 'base' },
      TextArea: { background: 'base' },
      List: { background: 'base', hoverBackground: 'hover', selectionBackground: 'selection', selectionForeground: 'text' },
      Tree: {
        background: 'base', hoverBackground: 'hover', rowHeight: 24,
        selectionBackground: 'selection', selectionForeground: 'text', modifiedItemForeground: 'accent',
      },
      Table: { background: 'base', gridColor: 'border', stripeColor: 'surface' },
      TableHeader: { background: 'surface', bottomSeparatorColor: 'border' },
      ScrollBar: {
        thumbColor: 'surface2', hoverThumbColor: 'textMuted',
        Transparent: { thumbColor: 'surface2', hoverThumbColor: 'textMuted' },
      },
      Notification: { background: 'raised', borderColor: 'outline' },
      CompletionPopup: { background: 'raised', selectionBackground: 'selection', matchForeground: 'accent' },
      NavBar: { borderColor: 'border' },
      Separator: { separatorColor: 'border' },
      Link: {
        activeForeground: 'accent', hoverForeground: 'accent',
        visitedForeground: 'accentQuiet', pressedForeground: 'accent',
      },
      ProgressBar: { progressColor: 'accent', indeterminateStartColor: 'accent', indeterminateEndColor: 'emerald' },
      Counter: { background: 'accent', foreground: 'onAccent' },
      ValidationTooltip: { errorBackground: 'surface', errorBorderColor: 'error' },
      Terminal: { background: 'terminalGround', foreground: 'terminalInk' },
    },
  };

  if (!islands) return theme;

  /**
   * The islands variant, which is the same theme with the seams taken out.
   *
   * IntelliJ 2026.1 paints the editor and each tool window as rounded panels
   * floating on a ground; the platform switches it on for any theme that sets
   * `Islands: 1`, and `targetUi="islands"` in plugin.xml is what files it under
   * Islands in Settings | Appearance. Nothing here is a new colour: JetBrains
   * put ground and island 6.3 (light) and 5.9 (dark) OKLab units apart, and the
   * rungs SAFF already has reach 5.6 and 4.7 on the same measurement.
   *
   * The ground is `stone` in both modes, which is darker than the island in
   * light and lighter in dark - the rung moves toward mid-grey either way, the
   * same direction the platform's own themes move. `raised` needs no override:
   * it already lands on the platform's own popup tone in both islands modes.
   */
  const island = u.surface;
  theme.name = mode === 'light' ? 'SAFF Light Islands' : 'SAFF Dark Islands';
  // By name, not by path: two providers pointing at the same scheme resource
  // would register it twice and show it twice in the Color Scheme dropdown.
  theme.editorScheme = mode === 'light' ? 'SAFF Light' : 'SAFF Dark';
  Object.assign(theme.colors, {
    islandGround: u.stone,
    island,
    // A dialog is not an island. Light seats it between the ground and the
    // island; dark has no rung there, so it takes the island's own value.
    dialog: mode === 'light' ? u.page : u.surface,
    transparent: `${island}00`,
  });

  const ui = theme.ui;
  Object.assign(ui['*'], {
    background: 'dialog', disabledBackground: 'dialog', inactiveBackground: 'dialog',
  });
  Object.assign(ui, {
    Islands: 1,
    Island: { ...ISLAND_GEOMETRY, borderColor: 'island' },
    MainWindow: { background: 'islandGround' },
    // The frame's seams are the gap now. Separators *inside* a panel or a menu
    // are not, so `border` keeps its classic value and only `Borders` moves.
    Borders: { color: 'islandGround', ContrastBorderColor: 'islandGround' },
    DialogWrapper: { southPanelBackground: 'dialog', southPanelDivider: 'dialog' },
  });
  ui.MainToolbar.background = 'islandGround';
  ui.StatusBar.background = 'islandGround';
  ui.StatusBar.borderColor = 'transparent';
  ui.Panel.background = 'dialog';
  ui.EditorTabs.background = 'island';
  ui.DefaultTabs.background = 'island';
  ui.Tree.background = 'island';
  ui.List.background = 'island';
  ui.Table.background = 'island';
  Object.assign(ui.ToolWindow, {
    background: 'island',
    borderColor: 'transparent',
    Header: { background: 'island', inactiveBackground: 'island', borderColor: 'border' },
    Stripe: { background: 'islandGround', borderColor: 'transparent' },
  });
  return theme;
}

const PLUGIN_XML = `<idea-plugin>
  <id>uz.saff.jetbrains.theme</id>
  <name>SAFF</name>
  <version>${VERSION}</version>
  <vendor>Learn Dart with Tests</vendor>
  <idea-version since-build="231" />
  <description><![CDATA[
    <h2>SAFF &mdash; the colour world of "Learn Dart with Tests"</h2>
    <p>Emerald marks what the language decides; brass marks what you wrote down.
    Two themes, light and dark, built from one palette so they read as one family.</p>
  ]]></description>
  <depends>com.intellij.modules.platform</depends>
  <extensions defaultExtensionNs="com.intellij">
    <themeProvider id="uz.saff.light" path="/themes/saff-light.theme.json" />
    <themeProvider id="uz.saff.dark" path="/themes/saff-dark.theme.json" />
    <themeProvider id="uz.saff.light.islands" path="/themes/saff-light-islands.theme.json" targetUi="islands" />
    <themeProvider id="uz.saff.dark.islands" path="/themes/saff-dark-islands.theme.json" targetUi="islands" />
  </extensions>
</idea-plugin>
`;

// ── Zed ──────────────────────────────────────────────────────────────────────

const alpha = (hex, a) => hex + Math.round(a * 255).toString(16).padStart(2, '0');

/** Mapped against the captures Zed's Dart grammar actually emits. */
function zedSyntax(mode) {
  const s = SYNTAX[mode];
  const u = UI[mode];
  const plain = (color, weight, style) => ({ color, font_style: style ?? null, font_weight: weight ?? null });
  const keyword = plain(s.keyword, 700);
  const fn = plain(s.fn);
  const type = plain(s.type);
  const str = plain(s.string);
  const num = plain(s.number);
  const interp = plain(s.interpolation);
  const annot = plain(s.annotation);
  const id = plain(s.identifier);
  const punct = plain(s.punctuation);
  const comment = plain(s.comment, null, 'italic');
  const fld = plain(s.field);
  return {
    keyword, 'keyword.conditional': keyword, 'keyword.conditional.ternary': keyword,
    'keyword.coroutine': keyword, 'keyword.definition': keyword, 'keyword.directive': keyword,
    'keyword.directive.define': keyword, 'keyword.exception': keyword, 'keyword.export': keyword,
    'keyword.function': keyword, 'keyword.import': keyword, 'keyword.modifier': keyword,
    'keyword.repeat': keyword, 'keyword.type': keyword, 'keyword.debug': keyword,
    'keyword.return': keyword, 'type.qualifier': keyword,
    boolean: plain(s.keyword), 'constant.builtin': plain(s.keyword),
    'variable.builtin': plain(s.keyword), 'variable.special': plain(s.keyword),
    function: fn, 'function.builtin': fn, 'function.call': fn, 'function.definition': fn,
    'function.method': fn, 'function.method.call': fn, 'function.macro': fn, constructor: fn,
    type, 'type.builtin': type, 'type.class.definition': type, 'type.definition': type,
    'type.interface': type, 'type.super': type, enum: type, variant: num,
    namespace: fn, module: fn,
    string: str, 'string.doc': str, 'string.documentation': str, 'string.regex': str,
    'string.regexp': str, 'string.special': str, 'string.special.path': str,
    'string.special.symbol': str, 'string.special.url': str, character: str, symbol: str,
    number: num, 'number.float': num, float: num, constant: num, 'constant.macro': num,
    'punctuation.special': interp, 'punctuation.special.symbol': interp,
    'string.escape': interp, embedded: interp, 'character.special': interp,
    attribute: annot, 'attribute.function': annot, 'attribute.special': annot,
    'function.decorator': annot, tag: annot, 'tag.attribute': annot,
    'tag.delimiter': punct, 'tag.doctype': annot,
    comment, 'comment.doc': comment, 'comment.documentation': comment,
    'comment.error': plain(u.correction, null, 'italic'), 'comment.hint': comment,
    'comment.info': comment, 'comment.note': comment, predoc: comment,
    'comment.todo': plain(u.brassInk, 700, 'italic'),
    'comment.warn': plain(u.brassInk, null, 'italic'),
    'comment.warning': plain(u.brassInk, null, 'italic'),
    variable: id, 'variable.parameter': id, parameter: id,
    label: id, text: id, primary: id, concept: id, parent: id,
    // A member belongs to something; a variable does not. Zed's Dart and Go
    // parsers both know the difference, so this is the one surface where the
    // distinction costs nothing to draw.
    'variable.member': fld, property: fld, field: fld,
    title: plain(s.identifier, 700),
    punctuation: punct, 'punctuation.bracket': punct, 'punctuation.delimiter': punct,
    'punctuation.list_marker': punct, operator: punct, 'keyword.operator': punct,
    emphasis: plain(s.identifier, null, 'italic'),
    'emphasis.strong': plain(s.identifier, 700),
    'text.literal': str,
    link_text: plain(u.brassInk, null, 'italic'), link_uri: plain(u.brassInk),
    hint: plain(s.comment, null, 'italic'), predictive: plain(s.comment, null, 'italic'),
    'diff.plus': plain(TERM[mode].pass), 'diff.minus': plain(TERM[mode].fail),
  };
}

function zedTheme(mode) {
  const u = UI[mode];
  const s = SYNTAX[mode];
  const t = TERM[mode];
  const ok = u.ok;
  const warn = u.brassInk;
  const err = u.correction;
  const info = u.info;
  return {
    name: mode === 'light' ? 'SAFF Light' : 'SAFF Dark',
    appearance: mode,
    style: {
      background: u.page,
      'background.appearance': 'opaque',
      accents: [u.accent, u.brass, t.pass, t.ansi.blue, t.ansi.magenta],
      border: u.hairline, 'border.variant': u.hairline, 'border.focused': u.brass,
      'border.selected': u.brass, 'border.transparent': '#00000000',
      'border.disabled': alpha(u.hairline, 0.5),
      'elevated_surface.background': u.surface, 'surface.background': u.page,
      'panel.background': u.page, 'panel.focused_border': u.brass,
      'panel.overlay_background': alpha(u.page, 0.9), 'panel.indent_guide': u.hairline,
      'panel.indent_guide_active': u.brass, 'panel.indent_guide_hover': u.brass,
      'pane.focused_border': u.brass, 'pane_group.border': u.hairline,
      'status_bar.background': u.stone, 'title_bar.background': u.stone,
      'title_bar.inactive_background': u.page, 'toolbar.background': u.surface,
      'tab_bar.background': u.stone, 'tab.active_background': u.surface,
      'tab.inactive_background': u.stone,
      'element.background': u.stone, 'element.hover': u.stone2, 'element.active': u.stone2,
      'element.selected': u.selection, 'element.disabled': alpha(u.stone, 0.5),
      'ghost_element.background': '#00000000', 'ghost_element.hover': alpha(u.stone2, 0.6),
      'ghost_element.active': u.stone2, 'ghost_element.selected': u.selection,
      'ghost_element.disabled': alpha(u.stone, 0.4),
      'drop_target.background': alpha(u.brass, 0.3),
      text: u.ink, 'text.muted': u.ink3, 'text.placeholder': u.ink3,
      'text.disabled': u.ink3, 'text.accent': u.brassInk, 'link_text.hover': u.brassInk,
      icon: u.ink2, 'icon.muted': u.ink3, 'icon.disabled': u.ink3,
      'icon.placeholder': u.ink3, 'icon.accent': u.brassInk,
      'editor.background': u.surface, 'editor.foreground': s.identifier,
      'editor.gutter.background': u.surface, 'editor.subheader.background': u.stone,
      'editor.active_line.background': u.caretRow, 'editor.highlighted_line.background': u.caretRow,
      'editor.debugger_active_line.background': alpha(u.brass, 0.2),
      'editor.line_number': s.punctuation, 'editor.active_line_number': u.brassInk,
      'editor.invisible': u.stone2, 'editor.wrap_guide': u.hairline,
      'editor.active_wrap_guide': u.brass, 'editor.indent_guide': u.hairline,
      'editor.indent_guide_active': u.brass,
      'editor.document_highlight.bracket_background': alpha(u.brass, 0.35),
      'editor.document_highlight.read_background': alpha(u.emerald, 0.16),
      'editor.document_highlight.write_background': alpha(u.brass, 0.22),
      'search.match_background': alpha(u.brass, 0.3),
      'search.active_match_background': alpha(u.brass, 0.55),
      'scrollbar.track.background': '#00000000', 'scrollbar.track.border': '#00000000',
      'scrollbar.thumb.background': alpha(u.ink3, 0.28),
      'scrollbar.thumb.hover_background': alpha(u.ink3, 0.45),
      'scrollbar.thumb.active_background': alpha(u.ink3, 0.6),
      'scrollbar.thumb.border': '#00000000',
      'minimap.thumb.background': alpha(u.ink3, 0.2),
      'minimap.thumb.hover_background': alpha(u.ink3, 0.35),
      'minimap.thumb.active_background': alpha(u.ink3, 0.5),
      'minimap.thumb.border': '#00000000',
      error: err, 'error.background': alpha(err, 0.14), 'error.border': alpha(err, 0.5),
      warning: warn, 'warning.background': alpha(warn, 0.14), 'warning.border': alpha(warn, 0.5),
      info, 'info.background': alpha(info, 0.14), 'info.border': alpha(info, 0.5),
      success: ok, 'success.background': alpha(ok, 0.14), 'success.border': alpha(ok, 0.5),
      hint: u.ink3, 'hint.background': alpha(u.ink3, 0.12), 'hint.border': alpha(u.ink3, 0.4),
      predictive: u.ink3, 'predictive.background': alpha(u.ink3, 0.12), 'predictive.border': alpha(u.ink3, 0.4),
      unreachable: u.ink3, 'unreachable.background': alpha(u.ink3, 0.12), 'unreachable.border': alpha(u.ink3, 0.4),
      created: ok, 'created.background': alpha(ok, 0.14), 'created.border': alpha(ok, 0.5),
      deleted: err, 'deleted.background': alpha(err, 0.14), 'deleted.border': alpha(err, 0.5),
      modified: u.brassInk, 'modified.background': alpha(u.brassInk, 0.14), 'modified.border': alpha(u.brassInk, 0.5),
      renamed: info, 'renamed.background': alpha(info, 0.14), 'renamed.border': alpha(info, 0.5),
      conflict: warn, 'conflict.background': alpha(warn, 0.14), 'conflict.border': alpha(warn, 0.5),
      hidden: u.ink3, 'hidden.background': alpha(u.ink3, 0.12), 'hidden.border': alpha(u.ink3, 0.4),
      ignored: u.ink3, 'ignored.background': alpha(u.ink3, 0.12), 'ignored.border': alpha(u.ink3, 0.4),
      'version_control.added': ok, 'version_control.deleted': err,
      'version_control.modified': u.brassInk, 'version_control.renamed': info,
      'version_control.conflict': warn, 'version_control.ignored': u.ink3,
      'version_control.conflict_marker.ours': alpha(ok, 0.18),
      'version_control.conflict_marker.theirs': alpha(info, 0.18),
      'debugger.accent': u.brass,
      'terminal.background': TERMINAL_GROUND[mode], 'terminal.foreground': t.ink,
      'terminal.dim_foreground': TERMINAL_DIM[mode], 'terminal.bright_foreground': t.command,
      'terminal.ansi.background': TERMINAL_GROUND[mode],
      'terminal.ansi.black': t.ansi.black, 'terminal.ansi.red': t.ansi.red,
      'terminal.ansi.green': t.ansi.green, 'terminal.ansi.yellow': t.ansi.yellow,
      'terminal.ansi.blue': t.ansi.blue, 'terminal.ansi.magenta': t.ansi.magenta,
      'terminal.ansi.cyan': t.ansi.cyan, 'terminal.ansi.white': t.ansi.white,
      'terminal.ansi.bright_black': t.ansi.brightBlack, 'terminal.ansi.bright_red': t.ansi.brightRed,
      'terminal.ansi.bright_green': t.ansi.brightGreen, 'terminal.ansi.bright_yellow': t.ansi.brightYellow,
      'terminal.ansi.bright_blue': t.ansi.brightBlue, 'terminal.ansi.bright_magenta': t.ansi.brightMagenta,
      'terminal.ansi.bright_cyan': t.ansi.brightCyan, 'terminal.ansi.bright_white': t.ansi.brightWhite,
      'terminal.ansi.dim_black': alpha(t.ansi.black, 0.7), 'terminal.ansi.dim_red': alpha(t.ansi.red, 0.7),
      'terminal.ansi.dim_green': alpha(t.ansi.green, 0.7), 'terminal.ansi.dim_yellow': alpha(t.ansi.yellow, 0.7),
      'terminal.ansi.dim_blue': alpha(t.ansi.blue, 0.7), 'terminal.ansi.dim_magenta': alpha(t.ansi.magenta, 0.7),
      'terminal.ansi.dim_cyan': alpha(t.ansi.cyan, 0.7), 'terminal.ansi.dim_white': alpha(t.ansi.white, 0.7),
      'vim.mode.text': u.onAccent, 'vim.normal.background': u.emerald, 'vim.normal.foreground': u.onAccent,
      'vim.insert.background': u.brass, 'vim.insert.foreground': u.onAccent,
      'vim.replace.background': err, 'vim.replace.foreground': '#FFFFFF',
      'vim.visual.background': u.selection, 'vim.visual.foreground': u.ink,
      'vim.visual_line.background': u.selection, 'vim.visual_line.foreground': u.ink,
      'vim.visual_block.background': u.selection, 'vim.visual_block.foreground': u.ink,
      'vim.helix_normal.background': u.emerald, 'vim.helix_normal.foreground': u.onAccent,
      'vim.helix_select.background': u.selection, 'vim.helix_select.foreground': u.ink,
      players: [
        { cursor: mode === 'light' ? u.brassInk : u.brassBright, selection: u.selection, background: u.brass },
        ...[u.emerald, t.ansi.blue, t.ansi.magenta, t.ansi.cyan].map((c) => ({
          cursor: c, selection: alpha(c, 0.28), background: c,
        })),
      ],
      syntax: zedSyntax(mode),
    },
  };
}

// ── Ghostty ─────────────────────────────────────────────────────────────────

/**
 * A Ghostty theme is a config fragment whose *filename* is the theme name —
 * no extension, no name field, and only the colour keys are accepted. Ghostty
 * reads user themes from `~/.config/ghostty/themes` even on macOS, where the
 * config file itself lives under `~/Library/Application Support`.
 *
 * The sixteen slots are the same ANSI table the IntelliJ terminal and Zed are
 * handed, so one `dart test` run is the same colours in all three.
 */
const ANSI = [
  'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white',
  'brightBlack', 'brightRed', 'brightGreen', 'brightYellow',
  'brightBlue', 'brightMagenta', 'brightCyan', 'brightWhite',
];

function ghostty(mode) {
  const t = TERM[mode];
  const ground = TERMINAL_GROUND[mode];
  const low = (hex) => hex.toLowerCase();
  return `${[
    `# SAFF ${mode === 'light' ? 'Light' : 'Dark'} — generated by editor-themes/generate.mjs.`,
    '# Edit web/src/lib/saff/palette.ts and re-run. Do not edit this file.',
    '',
    ...ANSI.map((name, i) => `palette = ${i}=${low(t.ansi[name])}`),
    '',
    `background = ${low(ground)}`,
    `foreground = ${low(t.ink)}`,
    `cursor-color = ${low(t.caret)}`,
    `cursor-text = ${low(ground)}`,
    `selection-background = ${low(TERMINAL_SELECTION[mode])}`,
    `selection-foreground = ${low(t.ink)}`,
  ].join('\n')}\n`;
}

// ── Emit ─────────────────────────────────────────────────────────────────────

assertMatchesBook();
assertCssMatchesPalette();

const light = icls('light');
const dark = icls('dark');

// The defect this file exists to prevent: a key named in one theme and not the
// other silently takes its colour from that theme's stock parent scheme.
const keysOf = (xml) => new Set([...xml.matchAll(/<option name="([A-Z_0-9.]+)"/g)].map((m) => m[1]));
const kl = keysOf(light);
const kd = keysOf(dark);
const onlyLight = [...kl].filter((k) => !kd.has(k));
const onlyDark = [...kd].filter((k) => !kl.has(k));
if (onlyLight.length || onlyDark.length) {
  console.error(`The two schemes name different keys — they would diverge:
  light only: ${onlyLight.join(' ')}
  dark only:  ${onlyDark.join(' ')}`);
  process.exit(1);
}
console.log(`both schemes name the same ${kl.size} keys`);

const build = join(HERE, 'build');
rmSync(build, { recursive: true, force: true });
mkdirSync(join(build, 'META-INF'), { recursive: true });
mkdirSync(join(build, 'themes'), { recursive: true });

writeFileSync(join(HERE, 'SAFF-Light.icls'), light);
writeFileSync(join(HERE, 'SAFF-Dark.icls'), dark);
writeFileSync(join(build, 'themes/saff-light.xml'), light);
writeFileSync(join(build, 'themes/saff-dark.xml'), dark);
for (const mode of ['light', 'dark']) {
  writeFileSync(join(build, `themes/saff-${mode}.theme.json`), `${JSON.stringify(themeJson(mode), null, 2)}\n`);
  writeFileSync(
    join(build, `themes/saff-${mode}-islands.theme.json`),
    `${JSON.stringify(themeJson(mode, true), null, 2)}\n`,
  );
}
writeFileSync(join(build, 'META-INF/plugin.xml'), PLUGIN_XML);

const jar = join(HERE, `SAFF-theme-${VERSION}.jar`);
rmSync(jar, { force: true });
execFileSync('zip', ['-qr', jar, 'META-INF', 'themes'], { cwd: build });
rmSync(build, { recursive: true, force: true });

writeFileSync(
  join(HERE, 'saff.json'),
  `${JSON.stringify(
    {
      $schema: 'https://zed.dev/schema/themes/v0.2.0.json',
      name: 'SAFF',
      author: 'Learn Dart with Tests',
      themes: [zedTheme('light'), zedTheme('dark')],
    },
    null,
    2,
  )}\n`,
);

mkdirSync(join(HERE, 'ghostty'), { recursive: true });
writeFileSync(join(HERE, 'ghostty/SAFF Light'), ghostty('light'));
writeFileSync(join(HERE, 'ghostty/SAFF Dark'), ghostty('dark'));

console.log(
  `wrote SAFF-Light.icls, SAFF-Dark.icls, saff.json, ghostty/SAFF {Light,Dark}, SAFF-theme-${VERSION}.jar`,
);
