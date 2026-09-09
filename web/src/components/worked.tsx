'use client';

import { useEffect, useId, useState } from 'react';

const KEY = 'ldwt:worked';

function readSet(): Set<string> {
  try {
    const raw = localStorage.getItem(KEY);
    return new Set<string>(raw ? (JSON.parse(raw) as string[]) : []);
  } catch {
    return new Set<string>();
  }
}

function writeSet(set: Set<string>) {
  try {
    localStorage.setItem(KEY, JSON.stringify([...set]));
  } catch {
    /* private browsing, blocked storage — the page still works */
  }
}

/**
 * The signature interaction. Marking a study worked draws its pencil mark
 * and leaves it there: a worked practice book keeps its annotations.
 */
export function Worked({ study }: { study: string }) {
  const [worked, setWorked] = useState(false);
  const [hydrated, setHydrated] = useState(false);
  const [justMarked, setJustMarked] = useState(false);
  const titleId = useId();

  useEffect(() => {
    setWorked(readSet().has(study));
    setHydrated(true);
  }, [study]);

  function toggle() {
    const set = readSet();
    const next = !set.has(study);
    if (next) set.add(study);
    else set.delete(study);
    writeSet(set);
    setWorked(next);
    setJustMarked(next);
    window.dispatchEvent(new CustomEvent('ldwt:worked-changed'));
  }

  return (
    <div
      className="flex items-center gap-3 mt-12 pt-4"
      style={{ borderTop: '1px solid var(--hairline)' }}
    >
      <button
        type="button"
        onClick={toggle}
        aria-pressed={hydrated ? worked : undefined}
        className="inline-flex items-center gap-2.5 text-[0.87rem] font-medium cursor-pointer bg-transparent border-0 p-0 hover:opacity-70 transition-opacity"
        style={{ color: worked ? 'var(--brass)' : 'var(--ink-3)' }}
      >
        <svg
          viewBox="0 0 16 16"
          aria-hidden="true"
          className="w-[15px] h-[15px] shrink-0"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <title id={titleId}>pencil</title>
          <path
            d="M2.5 13.5l1-3 7.5-7.5 2 2L5.5 12.5z"
            className={justMarked ? 'sl-draw' : undefined}
            style={{ opacity: worked ? 1 : 0.45 }}
          />
          <path d="M9.5 4.5l2 2" style={{ opacity: worked ? 1 : 0.45 }} />
        </svg>
        <span>
          {worked ? (
            <>
              <b className="font-semibold" style={{ color: 'var(--ink)' }}>
                Worked.
              </b>{' '}
              The mark stays in the margin.
            </>
          ) : (
            'Mark this study worked'
          )}
        </span>
      </button>
    </div>
  );
}
