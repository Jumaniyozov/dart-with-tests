import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';
import { Fraunces, JetBrains_Mono, Literata, Manrope } from 'next/font/google';

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
