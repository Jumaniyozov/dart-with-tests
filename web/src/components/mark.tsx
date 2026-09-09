/**
 * The book's mark: a cat looking over the edge of the page.
 *
 * One silhouette with the face punched clean through it, so the same path
 * renders emerald on porcelain, pale on cloth, or over anything else without a
 * second artwork. The flat bottom is the point — the cat is behind an edge the
 * mark never draws, so it sits on any horizontal without being redrawn.
 *
 * Below 26px the nose and mouth are dropped and the eyes are cut wider and
 * thicker. That is a different drawing, not the same one scaled: at 16px the
 * reading-size eye is two pixels of nothing.
 *
 * No brass. DESIGN.md's Earned-Brass Rule reserves it for what the reader
 * worked and says it is never a brand accent.
 */

const PAWS =
  'M5.6 44 C5.6 40.2 8.6 37.4 12.2 37.4 C15.8 37.4 18.8 40.2 18.8 44 Z ' +
  'M45.2 44 C45.2 40.2 48.2 37.4 51.8 37.4 C55.4 37.4 58.4 40.2 58.4 44 Z';

const HEAD =
  'M13.6 44 C13.6 36 14 28.4 15.2 22 L17 9.6 L27.2 18.6 ' +
  'C30.4 17.8 33.6 17.8 36.8 18.6 L47 9.6 L48.8 22 ' +
  'C50 28.4 50.4 36 50.4 44 Z';

/* Each eye is a crescent between two arcs, not a stroked arc: a stroke ends in
   a blunt cap, and the taper to a point at both ends is what reads as pleased
   rather than as a drawn line. */
const FACE_LARGE =
  ' M19.2 31.4 C21.4 26.2 26.6 26.2 28.8 31.4 C26.4 28.8 21.6 28.8 19.2 31.4 Z' +
  ' M35.2 31.4 C37.4 26.2 42.6 26.2 44.8 31.4 C42.4 28.8 37.6 28.8 35.2 31.4 Z' +
  ' M30.2 36.8 L33.8 36.8 L32 39.4 Z' +
  ' M28.4 40.4 C29.8 43.6 34.2 43.6 35.6 40.4 C34.2 42 29.8 42 28.4 40.4 Z';

const FACE_SMALL =
  ' M18.8 32 C21.2 25.6 26.8 25.6 29.2 32 C26.6 29 21.4 29 18.8 32 Z' +
  ' M34.8 32 C37.2 25.6 42.8 25.6 45.2 32 C42.6 29 37.4 29 34.8 32 Z';

/** The size below which the fine cut silts up and the small cut takes over. */
export const MARK_FINE = 26;

export function markPaths(fine: boolean) {
  return { paws: PAWS, head: HEAD + (fine ? FACE_LARGE : FACE_SMALL) };
}

export function Mark({
  size = 24,
  tiled = false,
  className,
}: {
  size?: number;
  /** Draw on a `--rail` cloth tile. The tile is identical in both themes, so a
   *  tiled mark never needs a dark variant. */
  tiled?: boolean;
  className?: string;
}) {
  const fine = size >= MARK_FINE;
  const { paws, head } = markPaths(fine);
  const fill = tiled ? 'var(--on-rail-surface)' : 'currentColor';

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 64 64"
      role="img"
      aria-label="Learn Dart with Tests"
      className={className}
      style={{ display: 'block' }}
    >
      <title>Learn Dart with Tests</title>
      {tiled && <rect width="64" height="64" rx="14.8" fill="var(--rail)" />}
      <g transform={tiled ? 'translate(6.4 10.6) scale(0.8)' : 'translate(0 5.2)'} fill={fill}>
        <path d={paws} />
        <path d={head} fillRule="evenodd" />
      </g>
    </svg>
  );
}

/**
 * Mark plus wordmark, set on two lines.
 *
 * One line does not fit: the rail is 228px, and a 26px mark beside the full
 * name at reading size runs under fumadocs' collapse button. Two lines also
 * happen to be how a title page sets it.
 *
 * The break is derived from `appName` rather than written out, so the constant
 * stays the single source of the title.
 *
 * Both mark and text take `currentColor`, because this lockup renders on two
 * different grounds: the rail, which sets `color: var(--rail-ink)` on
 * everything inside it, and the mobile navbar, which is on porcelain. That is
 * the Rail-Tints-Its-Own-Chrome Rule — a page token picked here would be
 * page-ink on emerald cloth, which is invisible.
 *
 * Emphasis by weight: "Dart" is the semibold, and no word is told apart by
 * colour alone.
 */
export function Lockup({ appName }: { appName: string }) {
  const words = appName.split(' ');
  const at = words.indexOf('with');
  const lines = (at > 0 ? [words.slice(0, at), words.slice(at)] : [words]).map((l) => l.join(' '));

  return (
    <span className="inline-flex items-center gap-2.5">
      <Mark size={30} />
      <span className="font-[family-name:var(--font-display)] text-[0.98rem] font-normal leading-[1.06] tracking-[-0.022em]">
        {lines.map((line) => {
          const d = line.indexOf('Dart');
          return (
            <span key={line} className="block whitespace-nowrap">
              {d < 0 ? (
                line
              ) : (
                <>
                  {line.slice(0, d)}
                  <span className="font-semibold">Dart</span>
                  {line.slice(d + 4)}
                </>
              )}
            </span>
          );
        })}
      </span>
    </span>
  );
}
