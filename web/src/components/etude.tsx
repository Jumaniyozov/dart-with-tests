import type { ReactNode } from 'react';

/** Repeat sign — brackets a drill the way it brackets a repeated bar. */
function RepeatSign() {
  return (
    <span className="etude-repeat" aria-hidden="true">
      <span className="etude-repeat-thick" />
      <span className="etude-repeat-thin" />
      <svg className="etude-repeat-dots" viewBox="0 0 5 14" fill="currentColor">
        <circle cx="2.5" cy="3.4" r="1.7" />
        <circle cx="2.5" cy="10.6" r="1.7" />
      </svg>
    </span>
  );
}

/** Fermata — hold here and read. Marks a gloss on the drill. */
function Fermata() {
  return (
    <svg
      viewBox="0 0 20 14"
      aria-hidden="true"
      className="w-[17px] h-[12px] shrink-0"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
    >
      <title>fermata</title>
      <path d="M1.5 12.5a8.5 8.5 0 0 1 17 0" />
      <circle cx="10" cy="8" r="1.7" fill="currentColor" stroke="none" />
    </svg>
  );
}

/**
 * One step of a drill. The numeral sits above the repeat sign the way a
 * fingering numeral sits above a note: it names the order, not a decoration.
 */
export function Drill({ n, children }: { n: number; children: ReactNode }) {
  return (
    <div className="grid grid-cols-[26px_minmax(0,1fr)] gap-3.5 my-6">
      <div
        className="flex flex-col items-center gap-1.5 pt-1"
        style={{ color: 'var(--etude-green)' }}
      >
        <span className="font-mono text-[0.8rem] font-bold tabular-nums leading-none">{n}</span>
        <RepeatSign />
      </div>
      <div className="min-w-0 [&>*:first-child]:mt-0 [&>*:last-child]:mb-0">{children}</div>
    </div>
  );
}

/**
 * A performance direction: how to play this drill. Red while the bar is
 * failing, green once it passes — always with words, never colour alone.
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
      className="!font-[family-name:var(--font-body)] italic !text-[0.95rem] !leading-[1.5] !my-2"
      style={{ color: tone === 'pass' ? 'var(--etude-green)' : 'var(--etude-red)' }}
    >
      {children}
    </p>
  );
}

/** Hold here. A note the reader should not skim past. */
export function Gloss({ title, children }: { title: string; children: ReactNode }) {
  return (
    <aside
      className="grid grid-cols-[auto_minmax(0,1fr)] gap-3 my-7 py-3.5"
      style={{
        borderTop: '1px solid var(--etude-rule)',
        borderBottom: '1px solid var(--etude-rule)',
      }}
    >
      <span className="pt-1" style={{ color: 'var(--etude-red)' }}>
        <Fermata />
      </span>
      <div className="min-w-0">
        <p className="!font-[family-name:var(--font-display)] !font-semibold !text-[0.94rem] !mt-0 !mb-1">
          {title}
        </p>
        <div className="[&>p]:!text-[0.95rem] [&>p]:!leading-[1.62] [&>p:last-child]:!mb-0">
          {children}
        </div>
      </div>
    </aside>
  );
}

/** The étude head: number and title over the double rule of a score. */
export function EtudeHead({ n, title }: { n?: number; title: ReactNode }) {
  return (
    <header className="mb-5">
      <div
        className="grid grid-cols-[auto_minmax(0,1fr)] gap-5 items-end pb-2.5"
        style={{ borderBottom: '2px solid var(--color-fd-foreground)' }}
      >
        {n !== undefined && (
          <span
            className="font-[family-name:var(--font-display)] font-bold text-[3.4rem] leading-[0.82] tracking-[-0.045em] tabular-nums"
            style={{ color: 'var(--etude-green)' }}
          >
            {n}
          </span>
        )}
        <h1 className="!m-0 !text-[1.72rem] !font-semibold !leading-[1.08] tracking-[-0.022em] text-balance">
          {title}
        </h1>
      </div>
      <div style={{ borderBottom: '1px solid var(--color-fd-foreground)', marginTop: '3px' }} />
    </header>
  );
}

/** How to play this study. Sits under the head, like a tempo marking. */
export function Prescription({ children }: { children: ReactNode }) {
  return (
    <p
      className="font-[family-name:var(--font-body)] italic text-[1rem] leading-[1.5] max-w-[60ch] mt-3.5"
      style={{ color: 'var(--etude-green)' }}
    >
      {children}
    </p>
  );
}

/** Machine output. A different material from the page: the terminal, not the plate. */
export function Console({ children }: { children: ReactNode }) {
  return <div className="etude-console my-4">{children}</div>;
}
