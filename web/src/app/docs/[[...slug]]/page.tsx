import { getPageImageUrl, getPageMarkdownUrl, source } from '@/lib/source';
import { DocsBody, DocsPage, MarkdownCopyButton, ViewOptionsPopover } from 'fumadocs-ui/layouts/docs/page';
import { notFound } from 'next/navigation';
import { getMDXComponents } from '@/components/mdx';
import type { Metadata } from 'next';
import { createRelativeLink } from 'fumadocs-ui/mdx';
import { EtudeHead, Prescription } from '@/components/etude';
import { Worked } from '@/components/worked';

export default async function Page(props: PageProps<'/docs/[[...slug]]'>) {
  const params = await props.params;
  const page = source.getPage(params.slug);
  if (!page) notFound();

  const MDX = page.data.body;
  const markdownUrl = getPageMarkdownUrl(page).url;
  const { study, direction } = page.data;

  return (
    <DocsPage toc={page.data.toc} full={page.data.full}>
      <div className="hidden md:flex justify-end gap-1 items-center opacity-50 hover:opacity-100 transition-opacity -mb-1">
        <MarkdownCopyButton markdownUrl={markdownUrl} />
        <ViewOptionsPopover markdownUrl={markdownUrl} />
      </div>
      <EtudeHead n={study} title={page.data.title} />
      {direction ? <Prescription>{direction}</Prescription> : null}
      <DocsBody>
        <MDX components={getMDXComponents({ a: createRelativeLink(source, page) })} />
        {study !== undefined ? <Worked study={`study-${study}`} /> : null}
      </DocsBody>
    </DocsPage>
  );
}

export async function generateStaticParams() {
  return source.generateParams();
}

export async function generateMetadata(props: PageProps<'/docs/[[...slug]]'>): Promise<Metadata> {
  const params = await props.params;
  const page = source.getPage(params.slug);
  if (!page) notFound();

  return {
    title: page.data.title,
    description: page.data.description,
    openGraph: { images: getPageImageUrl(page).url },
  };
}
