import { loader } from 'fumadocs-core/source';
import { lucideIconsPlugin } from 'fumadocs-core/source/lucide-icons';
import { docsContentRoute, docsImageRoute, docsRoute } from './shared';
import { defineDocs } from 'fumadocs-mdx/macro';
import { metaSchema, pageSchema } from 'fumadocs-core/source/schema';
import { z } from 'zod';

/** A study carries its number and the direction it is worked under. */
const studySchema = pageSchema.extend({
  study: z.number().int().optional(),
  direction: z.string().optional(),
});

const docs = defineDocs({
  dir: 'content/docs',
  docs: {
    schema: studySchema,
    postprocess: {
      includeProcessedMarkdown: true,
    },
    /**
     * The book brings its own syntax theme and two grammars Shiki does not ship.
     * The imports are dynamic because the macro erases this whole call from the
     * app bundle, so nothing here should be reachable from a static import.
     */
    mdxOptions: async (environment) => {
      const [{ applyMdxPreset }, { saffDark, saffLight }, { saffConsole, saffDart, saffDartInterpolation }] =
        await Promise.all([
          import('fumadocs-mdx/config'),
          import('./saff/theme'),
          import('./saff/langs'),
        ]);

      return applyMdxPreset({
        rehypeCodeOptions: {
          themes: { light: saffLight, dark: saffDark },
          langs: ['dart', saffConsole, saffDart, saffDartInterpolation],
        },
      })(environment);
    },
  },
  meta: {
    schema: metaSchema,
  },
});

// See https://fumadocs.dev/docs/headless/source-api for more info
export const source = loader({
  baseUrl: docsRoute,
  source: docs.toFumadocsSource(),
  plugins: [lucideIconsPlugin()],
});

export function getPageImageUrl(page: (typeof source)['$inferPage']) {
  const segments = [...page.slugs, 'image.png'];

  return {
    segments,
    url: '/' + [page.locale, ...docsImageRoute.split('/'), ...segments].filter(Boolean).join('/'),
  };
}

export function getPageMarkdownUrl(page: (typeof source)['$inferPage']) {
  const segments = [...page.slugs, 'content.md'];

  return {
    segments,
    url: '/' + [page.locale, ...docsContentRoute.split('/'), ...segments].filter(Boolean).join('/'),
  };
}

export async function getLLMText(page: (typeof source)['$inferPage']) {
  const processed = await page.data.getText('processed');

  return `# ${page.data.title} (${page.url})

${processed}`;
}
