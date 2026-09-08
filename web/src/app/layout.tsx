import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';
import { Archivo, JetBrains_Mono, Literata } from 'next/font/google';

const archivo = Archivo({
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

const mono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-mono',
  display: 'swap',
});

export default function Layout({ children }: LayoutProps<'/'>) {
  return (
    <html
      lang="en"
      className={`${archivo.variable} ${literata.variable} ${mono.variable}`}
      suppressHydrationWarning
    >
      <body className="flex flex-col min-h-screen">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
