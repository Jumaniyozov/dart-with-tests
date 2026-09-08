'use client';

import type * as PageTree from 'fumadocs-core/page-tree';
import { SidebarItem } from 'fumadocs-ui/components/sidebar/base';
import { usePathname } from 'next/navigation';
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';

const StudyContext = createContext<Record<string, number>>({});

export function StudyProvider({
  map,
  children,
}: {
  map: Record<string, number>;
  children: ReactNode;
}) {
  return <StudyContext value={map}>{children}</StudyContext>;
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

/**
 * A rail entry is an étude: numbered, and once worked it keeps a pencil mark
 * in the margin. The mark is drawn in when it first appears.
 */
export function EtudeItem({ item }: { item: PageTree.Item }) {
  const studies = useContext(StudyContext);
  const pathname = usePathname();
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

  const n = studies[item.url];
  const isWorked = ready && n !== undefined && worked.has(`study-${n}`);

  return (
    <SidebarItem href={item.url} active={pathname === item.url}>
      <span className="etude-entry">
        <span className="etude-entry-no">{n ?? ''}</span>
        <span className="etude-entry-name">{item.name}</span>
        {isWorked ? (
          <svg
            className="etude-entry-mark"
            viewBox="0 0 16 16"
            aria-label="worked"
            role="img"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path className="etude-draw" d="M2.5 13.5l1-3 7.5-7.5 2 2L5.5 12.5z" />
            <path d="M9.5 4.5l2 2" />
          </svg>
        ) : (
          <span />
        )}
      </span>
    </SidebarItem>
  );
}
