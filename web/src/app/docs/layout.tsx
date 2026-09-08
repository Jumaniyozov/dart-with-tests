import { source } from '@/lib/source';
import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import { baseOptions } from '@/lib/layout.shared';
import { EtudeItem, StudyProvider } from '@/components/sidebar-item';

export default function Layout({ children }: LayoutProps<'/docs'>) {
  const studies: Record<string, number> = {};
  for (const page of source.getPages()) {
    if (page.data.study !== undefined) studies[page.url] = page.data.study;
  }

  return (
    <StudyProvider map={studies}>
      <DocsLayout
        tree={source.getPageTree()}
        sidebar={{ components: { Item: EtudeItem } }}
        {...baseOptions()}
      >
        {children}
      </DocsLayout>
    </StudyProvider>
  );
}
