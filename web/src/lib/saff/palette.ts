/**
 * The SAFF syntax palette, as sRGB hex.
 *
 * The rest of the design system is authored in OKLCH, but a TextMate theme can
 * only carry hex, so every value here is the sRGB the browser actually paints
 * for the OKLCH in the comment beside it, read back off a canvas.
 *
 * Measured, not computed. Five of the light roles sit outside sRGB, and Chrome
 * resolves those by clipping each channel — not by the chroma reduction of CSS
 * Color 4 §13.2. Deriving them with that algorithm produces visibly duller
 * colour than the page shows (up to 11/255 per channel on `string`), so the
 * paint is the only reliable source. Re-measure if a source OKLCH changes.
 */

/** The eight roles the code card distinguishes, plus its two neutrals. */
export interface CardPalette {
  ground: string;
  keyword: string;
  fn: string;
  type: string;
  string: string;
  number: string;
  interpolation: string;
  annotation: string;
  comment: string;
  field: string;
  identifier: string;
  punctuation: string;
}

/**
 * Light is tuned for salience, not for maximum darkness.
 *
 * Every chromatic role here already sits exactly on the sRGB gamut boundary for
 * its lightness — there is no saturation left to add. Measured against dark,
 * the gap was never chroma (0.135 against 0.142) but weight: plain `identifier`
 * carried 2.67x the contrast of the median coloured role, against 1.73x in
 * dark, so near-black text won every glance and colour read as a tint on grey.
 *
 * Two moves close it. `identifier` gives up its contrast headroom (14.5:1 to
 * 9.3:1, still past WCAG AAA), and `keyword` and `interpolation` — the only two
 * roles that were over-contrasted — spend their surplus on chroma instead.
 * Salience ratio 1.83, mean chroma 0.143: dark's numbers, on a white ground.
 *
 * What is not available is more saturation. On a near-white ground a legible
 * colour has to sit near L 50, and at L 50 the sRGB ceiling for SAFF's own hues
 * is 0.10 for gold and 0.09 for teal — the two flattest points on the whole hue
 * circle, where indigo and magenta offer 0.28. Brass and emerald have no vivid
 * dark form. Dark mode gets vividness for free, because bright saturated colour
 * is high-contrast on a dark ground; light mode cannot, and tuning will not
 * change it — only abandoning the two brand hues would.
 */
export const cardLight: CardPalette = {
  ground: '#F7FAF8', //        oklch(98.2% 0.004 165)  --porcelain-2
  keyword: '#006425', //       oklch(44% 0.127 148)  +13% chroma off its surplus contrast
  fn: '#007C57', //            oklch(52% 0.111 164)
  type: '#936000', //          oklch(53% 0.113 73)
  string: '#AD4A00', //        oklch(53% 0.147 47)
  number: '#C34500', //        oklch(56% 0.173 41)
  interpolation: '#C10002', // oklch(51% 0.209 29)   +15% chroma, same trade
  annotation: '#717500', //    oklch(54% 0.120 112)  hue pushed off `type`
  comment: '#587A6C', //       oklch(55% 0.045 167)
  field: '#6F530A', //         oklch(46% 0.090 85)   members, not variables
  identifier: '#2E493F', //    oklch(38% 0.037 169)  lifted off near-black
  punctuation: '#5B6E67', //   oklch(52% 0.025 171)
};

export const cardDark: CardPalette = {
  ground: '#16251F', //        oklch(25% 0.024 168)  --porcelain-2 (dark)
  keyword: '#36AC62', //       oklch(66% 0.150 152)  hue-matched to light's keyword
  fn: '#4BC39F', //            oklch(74% 0.120 170)
  type: '#EFCF59', //          oklch(86% 0.140 94)
  string: '#F4AF38', //        oklch(80% 0.150 76)
  number: '#F48E1F', //        oklch(74% 0.165 60)
  interpolation: '#E57431', // oklch(68% 0.160 48)
  annotation: '#E1DC85', //    oklch(88% 0.110 106)
  comment: '#7C9A8E', //       oklch(66% 0.038 168)
  field: '#CFBE7E', //         oklch(80% 0.085 95)   members, not variables
  identifier: '#DFE7E0', //    oklch(92% 0.012 150)
  punctuation: '#96A29A', //   oklch(70% 0.018 158)
};

/**
 * The console.
 *
 * Machine output is a different material from authored source, so it gets its
 * own ground: recessed stone under a light lamp, a near-black slab under a dark
 * one. The nine roles are the same either way — only their lightness flips,
 * because emphasis on a pale ground is darkness and on a dark ground is light.
 *
 * The light ground is set so the card-to-console step measures 1.28:1, the same
 * step the dark theme already had. The two materials should read as equally far
 * apart under either lamp, and a value picked by eye does not do that.
 */
export interface ConsolePalette {
  ground: string;
  ink: string;
  dim: string;
  prompt: string;
  command: string;
  pass: string;
  fail: string;
  ref: string;
  path: string;
  caret: string;
}

export const consoleLight: ConsolePalette = {
  ground: '#D5E1DB', //  oklch(90% 0.016 162)
  ink: '#142922', //     oklch(26% 0.030 170)
  dim: '#52645D', //     ink at 68% over ground, composited
  prompt: '#744C0E', //  oklch(45% 0.090 72)   brass at text weight
  command: '#021911', // oklch(19% 0.035 168)
  pass: '#006432', //    oklch(43% 0.130 158)  +N
  fail: '#9E2D28', //    oklch(47% 0.150 27)   -N, [E], Error
  ref: '#7A5800', //     oklch(48% 0.120 88)   file:line:col
  path: '#1A6444', //    oklch(45% 0.090 160)  quoted paths
  caret: '#005E29', //   oklch(40% 0.150 160)  ^
};

export const consoleDark: ConsolePalette = {
  ground: '#0E1C17', //  oklch(21% 0.022 170)  the ground every terminal uses
  ink: '#CDD8CE', //     oklch(87% 0.018 148)
  dim: '#909C93', //     ink at 68% over ground, composited
  prompt: '#C3A76B', //  oklch(74% 0.085 85)   brass, on a dark ground
  command: '#F1F7F2', // oklch(97% 0.01 150)
  pass: '#6EEEAB', //    oklch(86% 0.15 158)   +N
  fail: '#F17166', //    oklch(70% 0.16 27)    -N, [E], Error
  ref: '#E8C67D', //     oklch(84% 0.10 85)    file:line:col
  path: '#A4D1AC', //    oklch(82% 0.07 150)   quoted paths
  caret: '#76E5AD', //   oklch(84% 0.13 160)   ^
};
