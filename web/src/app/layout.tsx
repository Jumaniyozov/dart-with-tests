import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';
import type { Metadata } from 'next';
import { Fraunces, JetBrains_Mono, Literata, Manrope } from 'next/font/google';
import { appDescription, appName, siteUrl } from '@/lib/shared';

/* Four faces, and each earns its place. Stonelight runs a serif display over a
   Manrope UI; a book adds one thing the app never needed — a text face that
   survives forty-four chapters — so Literata carries the prose. */

const fraunces = Fraunces({
  subsets: ['latin'],
  variable: '--font-display',
  display: 'swap',
});

const literata = Literata({
  subsets: ['latin'],
  variable: '--font-body',
  style: ['normal', 'italic'],
  display: 'swap',
});

const manrope = Manrope({
  subsets: ['latin'],
  variable: '--font-ui',
  display: 'swap',
});

const mono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-mono',
  display: 'swap',
});

/* App Router picks the marks up from src/app/ by filename — icon.svg,
   apple-icon.png and favicon.ico — so `icons` is not restated here. Only the
   things convention cannot infer are declared. */
export const metadata: Metadata = {
  metadataBase: siteUrl,
  title: {
    default: appName,
    // A study page is already titled "Study N — Name"; the suffix says which
    // book it belongs to without repeating the whole name in the tab.
    template: `%s · ${appName}`,
  },
  description: appDescription,
  applicationName: appName,
  openGraph: {
    type: 'book',
    siteName: appName,
    title: appName,
    description: appDescription,
    url: siteUrl,
  },
  twitter: {
    card: 'summary_large_image',
    title: appName,
    description: appDescription,
  },
};

export default function Layout({ children }: LayoutProps<'/'>) {
  return (
    <html
      lang="en"
      className={`${fraunces.variable} ${literata.variable} ${manrope.variable} ${mono.variable}`}
      suppressHydrationWarning
    >
      <body className="flex flex-col min-h-screen">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
