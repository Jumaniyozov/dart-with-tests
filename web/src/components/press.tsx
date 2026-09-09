import type { ReactNode } from 'react';

/**
 * Stonelight Press components.
 *
 * The app's vocabulary, cut for a book: emerald carries structure, stone
 * carries surface, and brass is spent only on what a reader earns. Nothing
 * here is a tinted row or a coloured stripe — a thing is either a card, a
 * pill, or plain text on the page.
 */

/** Hold here. Marks a note the reader should not skim past. */
function Bookmark() {
  return (
    <svg
      viewBox="0 0 14 16"
      aria-hidden="true"
      className="w-[13px] h-[15px] shrink-0"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <title>bookmark</title>
      <path d="M3 1.9h8a1 1 0 0 1 1 1v11.2l-5-3-5 3V2.9a1 1 0 0 1 1-1Z" />
    </svg>
  );
}

/**
 * One step of a drill. The numeral is a filled emerald pill — the same shape
 * the app uses for a circular control, doing the job a fingering numeral does
 * in a score: it names the order, not a decoration.
 */
export function Drill({ n, children }: { n: number; children: ReactNode }) {
  return (
    <div className="grid grid-cols-[1.75rem_minmax(0,1fr)] gap-3.5 my-7">
      <span
        className="grid place-items-center w-7 h-7 rounded-full font-[family-name:var(--font-ui)] text-[0.8rem] font-semibold tabular-nums select-none"
        style={{ background: 'var(--emerald)', color: 'var(--on-emerald)' }}
      >
        {n}
      </span>
      <div className="min-w-0 [&>*:first-child]:mt-0 [&>*:last-child]:mb-0">{children}</div>
    </div>
  );
}

/**
 * How to play this drill. Red while the bar is failing, emerald once it
 * passes — always with words as well, never colour alone.
 */
export function Direction({
  tone = 'fail',
  children,
}: {
  tone?: 'fail' | 'pass';
  children: ReactNode;
}) {
  return (
    <p
      className="!font-[family-name:var(--font-ui)] !text-[0.92rem] !font-medium !leading-[1.5] !my-2"
      style={{
        color: tone === 'pass' ? 'var(--emerald)' : 'var(--correction)',
      }}
    >
      {children}
    </p>
  );
}

/**
 * A note that must not be skimmed. A stone card, bookmarked in emerald.
 *
 * Stone, not `--porcelain-2`: that token is now the ground every editor paints
 * on, so in dark it sits *below* the page and a note wearing it reads as a code
 * block. Both asides take `--stone` and are told apart by their accent — emerald
 * bookmark here, brass rule on `Practice`.
 */
export function Gloss({ title, children }: { title: string; children: ReactNode }) {
  return (
    <aside
      className="rounded-card my-7 px-5 py-4"
      style={{
        background: 'var(--stone)',
        border: '1px solid var(--hairline)',
        boxShadow: '0 1px 2px oklch(24% 0.03 170 / 0.05)',
      }}
    >
      <p className="!mt-0 !mb-1.5 flex items-center gap-2" style={{ color: 'var(--emerald)' }}>
        <Bookmark />
        <span className="font-[family-name:var(--font-display)] font-semibold text-[1rem]">
          {title}
        </span>
      </p>
      <div className="[&>p]:!text-[0.95rem] [&>p]:!leading-[1.65] [&>p:last-child]:!mb-0">
        {children}
      </div>
    </aside>
  );
}

/**
 * The convention layered on top of what the language allows. Brass-edged,
 * because a best practice is earned knowledge rather than a language rule.
 * Cite the source when the guidance has one; leave it off for a house rule,
 * so an uncited note visibly claims less.
 *
 * The ground is plain `--stone`, the same panel every other raised surface in
 * the book uses, and brass appears only in the rule and the label. It used to be
 * a brass wash fading into `--porcelain-2`, which failed twice over: the fade
 * left the bottom edge 1.8 OKLab units from the page, so the box dissolved
 * before the last line, and in dark a warm tint over a green ground can only
 * land in the olive band — `--brass-pale` is L85, and composited down onto an
 * L29 page there is nowhere else for it to go. Brass stays an accent, which is
 * what the palette says it is for.
 */
export function Practice({
  source,
  href,
  children,
}: {
  source?: string;
  href?: string;
  children: ReactNode;
}) {
  const cite = href ? (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      className="!text-inherit underline underline-offset-2 decoration-dotted"
    >
      {source}
    </a>
  ) : (
    source
  );

  return (
    <aside
      className="rounded-card my-7 px-5 py-4"
      style={{
        background: 'var(--stone)',
        border: '1px solid var(--hairline)',
        borderLeft: '1px solid var(--brass)',
      }}
    >
      <p className="!mt-0 !mb-2 flex flex-wrap items-baseline gap-x-2.5 gap-y-1">
        <span
          className="font-[family-name:var(--font-ui)] text-[0.72rem] font-semibold uppercase tracking-[0.08em]"
          style={{ color: 'var(--brass-ink)' }}
        >
          Best practice
        </span>
        {source && (
          <span
            className="font-[family-name:var(--font-mono)] text-[0.72rem]"
            style={{ color: 'var(--ink-3)' }}
          >
            {cite}
          </span>
        )}
      </p>
      <div className="[&>p]:!text-[0.95rem] [&>p]:!leading-[1.65] [&>p:last-child]:!mb-0">
        {children}
      </div>
    </aside>
  );
}

/** The chapter head: a display numeral in emerald over the title. */
export function PressHead({ n, title }: { n?: number; title: ReactNode }) {
  return (
    <header className="mb-6">
      {n !== undefined && (
        <div
          className="font-[family-name:var(--font-display)] font-normal text-[3.4rem] leading-[0.85] tracking-[-0.03em] tabular-nums"
          style={{ color: 'var(--emerald)' }}
        >
          {n}
        </div>
      )}
      <h1 className="!mt-2 !mb-0 font-[family-name:var(--font-display)] !text-[2.1rem] !font-semibold !leading-[1.06] tracking-[-0.018em] text-balance">
        {title}
      </h1>
    </header>
  );
}

/** How to work this study. Sits under the head, in the UI voice. */
export function Prescription({ children }: { children: ReactNode }) {
  return (
    <p
      className="font-[family-name:var(--font-ui)] text-[0.98rem] leading-[1.5] max-w-[56ch] mt-3.5"
      style={{ color: 'var(--ink-3)' }}
    >
      {children}
    </p>
  );
}

/** Machine output. A different material from the page: the terminal, not the card. */
export function Console({ children }: { children: ReactNode }) {
  return <div className="sl-console my-4">{children}</div>;
}
