import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import { BookFolder, RailProgress, RailProvider, StudyItem } from '@/components/rail';
import { baseOptions } from '@/lib/layout.shared';
import { source } from '@/lib/source';

export default function Layout({ children }: LayoutProps<'/docs'>) {
  const studies: Record<string, number> = {};
  for (const page of source.getPages()) {
    if (page.data.study !== undefined) studies[page.url] = page.data.study;
  }
  // The total is the studies that exist, not the forty-four that are planned.
  const total = Object.keys(studies).length;

  return (
    <RailProvider data={{ studies, total }}>
      <DocsLayout
        tree={source.getPageTree()}
        sidebar={{
          banner: <RailProgress />,
          components: { Item: StudyItem, Folder: BookFolder },
        }}
        {...baseOptions()}
      >
        {children}
      </DocsLayout>
    </RailProvider>
  );
}
