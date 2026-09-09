export const appName = 'Learn Dart with Tests';

/** One sentence, used for the page description and every social card. */
export const appDescription =
  'Forty-four studies in Dart 3.13. Every one names a technique, works a drill, and marks the result. Every sample is pulled from code that dart test runs.';

export const docsRoute = '/docs';
export const docsImageRoute = '/og/docs';
export const docsContentRoute = '/llms.mdx/docs';

export const gitConfig = {
  user: 'Jumaniyozov',
  repo: 'dart-with-tests',
  branch: 'main',
};

/**
 * Absolute base for metadata. Never hardcode a domain: on Vercel the production
 * host is supplied, locally it is localhost, and a deploy anywhere else sets
 * NEXT_PUBLIC_SITE_URL. A wrong metadataBase silently breaks every OG image.
 */
export const siteUrl = new URL(
  process.env.NEXT_PUBLIC_SITE_URL ??
    (process.env.VERCEL_PROJECT_PRODUCTION_URL
      ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
      : 'http://localhost:3000'),
);
