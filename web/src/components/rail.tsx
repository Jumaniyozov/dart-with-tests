'use client';

import type * as PageTree from 'fumadocs-core/page-tree';
import {
  SidebarFolder,
  SidebarFolderContent,
  SidebarFolderTrigger,
  SidebarItem,
} from 'fumadocs-ui/components/sidebar/base';
import { usePathname } from 'next/navigation';
import { createContext, type ReactNode, useContext, useEffect, useState } from 'react';

/**
 * The rail.
 *
 * A book's contents page, not a docs tree. Three things have to be true at a
 * glance: which study you are in, how far through the book you are, and which
 * studies you have already worked. Everything else is chrome.
 */

type RailData = { studies: Record<string, number>; total: number };

const RailContext = createContext<RailData>({ studies: {}, total: 0 });

export function RailProvider({ data, children }: { data: RailData; children: ReactNode }) {
  return <RailContext value={data}>{children}</RailContext>;
}

const KEY = 'ldwt:worked';

function readWorked(): Set<string> {
  try {
    const raw = localStorage.getItem(KEY);
    return new Set<string>(raw ? (JSON.parse(raw) as string[]) : []);
  } catch {
    return new Set<string>();
  }
}

/** Subscribes to the worked set. Empty until hydrated, so the server render matches. */
function useWorked() {
  const [worked, setWorked] = useState<Set<string>>(() => new Set());
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const sync = () => setWorked(readWorked());
    sync();
    setReady(true);
    window.addEventListener('ldwt:worked-changed', sync);
    window.addEventListener('storage', sync);
    return () => {
      window.removeEventListener('ldwt:worked-changed', sync);
      window.removeEventListener('storage', sync);
    };
  }, []);

  return { worked, ready };
}

/** The pencil, drawn in the first time it appears. Brass, because it was earned. */
function WorkedMark() {
  return (
    <svg
      className="sl-entry-mark"
      viewBox="0 0 16 16"
      aria-label="worked"
      role="img"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path className="sl-draw" d="M2.5 13.5l1-3 7.5-7.5 2 2L5.5 12.5z" />
      <path d="M9.5 4.5l2 2" />
    </svg>
  );
}

/**
 * How far through the book you are. The number is the signal; the rule under it
 * only makes the number easier to feel. Both are present, so the reading
 * survives greyscale.
 */
export function RailProgress() {
  const { total } = useContext(RailContext);
  const { worked, ready } = useWorked();
  const done = ready ? [...worked].filter((k) => k.startsWith('study-')).length : 0;
  const pct = total > 0 ? Math.min(100, (done / total) * 100) : 0;

  return (
    <div className="sl-progress">
      <p className="sl-progress-line">
        <span>Worked</span>
        <span className="sl-progress-count">
          {done} of {total}
        </span>
      </p>
      <div
        className="sl-progress-track"
        role="progressbar"
        aria-label="Studies worked"
        aria-valuenow={done}
        aria-valuemin={0}
        aria-valuemax={total}
      >
        <span className="sl-progress-fill" style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

/**
 * One study. A numbered row that becomes a filled pill when you are in it.
 * The pages with no study number are front matter, and they say so by not
 * pretending to be a chapter.
 */
export function StudyItem({ item }: { item: PageTree.Item }) {
  const { studies } = useContext(RailContext);
  const pathname = usePathname();
  const { worked, ready } = useWorked();

  const n = studies[item.url];
  const active = pathname === item.url;

  if (n === undefined) {
    return (
      <SidebarItem href={item.url} active={active}>
        <span className="sl-front">{item.name}</span>
      </SidebarItem>
    );
  }

  return (
    <SidebarItem href={item.url} active={active}>
      <span className="sl-entry">
        <span className="sl-entry-no">{n}</span>
        <span className="sl-entry-name">{item.name}</span>
        {ready && worked.has(`study-${n}`) ? <WorkedMark /> : <span />}
      </span>
    </SidebarItem>
  );
}

/** "Book I: Foundations" → numeral and name, so the rail can set them apart. */
function splitBookTitle(name: ReactNode): { numeral?: string; title: ReactNode } {
  if (typeof name !== 'string') return { title: name };
  const m = name.match(/^Book\s+([IVXLC]+)\s*:\s*(.+)$/);
  return m ? { numeral: m[1], title: m[2] } : { title: name };
}

/**
 * A book. Open while you are reading it, closed otherwise, and a closed book
 * still says how much of it you have worked — so the rail answers "where am I
 * in the whole thing" without expanding anything.
 */
export function BookFolder({ item, children }: { item: PageTree.Folder; children: ReactNode }) {
  const { studies } = useContext(RailContext);
  const pathname = usePathname();
  const { worked, ready } = useWorked();

  const pages = item.children.filter(
    (c): c is PageTree.Item => c.type === 'page' && studies[c.url] !== undefined,
  );
  const active = pages.some((p) => p.url === pathname);
  const done = ready ? pages.filter((p) => worked.has(`study-${studies[p.url]}`)).length : 0;

  // On the front matter, no book is active — leaving every book shut would show
  // a contents page with no contents. The book holding study 1 opens instead.
  const onAStudy = Object.hasOwn(studies, pathname);
  const holdsFirstStudy = pages.some((p) => studies[p.url] === 1);
  const open = active || (!onAStudy && holdsFirstStudy);

  const { numeral, title } = splitBookTitle(item.name);

  return (
    <SidebarFolder defaultOpen={open} collapsible={item.collapsible} active={open}>
      <SidebarFolderTrigger>
        <span className="sl-book" data-open={active ? 'true' : 'false'}>
          {numeral && <span className="sl-book-no">{numeral}</span>}
          <span className="sl-book-name">{title}</span>
          <span className="sl-book-count">
            {done}/{pages.length}
          </span>
        </span>
      </SidebarFolderTrigger>
      <SidebarFolderContent>
        <div className="sl-book-studies">{children}</div>
      </SidebarFolderContent>
    </SidebarFolder>
  );
}
