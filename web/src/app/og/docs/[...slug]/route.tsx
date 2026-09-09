import { notFound } from 'next/navigation';
import { ImageResponse } from 'next/og';
import { appDescription, appName } from '@/lib/shared';
import { getPageImageUrl, source } from '@/lib/source';

export const revalidate = false;

/* Hex measured off a canvas rather than converted, the way every other colour in
   this project was: see editor-themes/README.md. These four are all theme-stable
   tokens, so a social card needs no dark variant.
     #05281d  --rail             book cloth
     #e6f2e8  --rail-ink         the title
     #a1b4a6  --rail-mute        everything secondary
     #ecf4ee  --on-rail-surface  the mark */
const RAIL = '#05281d';
const RAIL_INK = '#e6f2e8';
const RAIL_MUTE = '#a1b4a6';

/* Satori cannot resolve CSS variables or external files, so the mark travels as
   a data URI. This is the fine cut — the card is 1200px wide and the nose and
   mouth are legible at this scale. */
const MARK = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
<g transform="translate(0 5.2)" fill="#ecf4ee">
<path d="M5.6 44 C5.6 40.2 8.6 37.4 12.2 37.4 C15.8 37.4 18.8 40.2 18.8 44 Z M45.2 44 C45.2 40.2 48.2 37.4 51.8 37.4 C55.4 37.4 58.4 40.2 58.4 44 Z"/>
<path fill-rule="evenodd" d="M13.6 44 C13.6 36 14 28.4 15.2 22 L17 9.6 L27.2 18.6 C30.4 17.8 33.6 17.8 36.8 18.6 L47 9.6 L48.8 22 C50 28.4 50.4 36 50.4 44 Z M19.2 31.4 C21.4 26.2 26.6 26.2 28.8 31.4 C26.4 28.8 21.6 28.8 19.2 31.4 Z M35.2 31.4 C37.4 26.2 42.6 26.2 44.8 31.4 C42.4 28.8 37.6 28.8 35.2 31.4 Z M30.2 36.8 L33.8 36.8 L32 39.4 Z M28.4 40.4 C29.8 43.6 34.2 43.6 35.6 40.4 C34.2 42 29.8 42 28.4 40.4 Z"/>
</g></svg>`;
const MARK_SRC = `data:image/svg+xml;base64,${Buffer.from(MARK).toString('base64')}`;

/**
 * Satori needs real font binaries, and next/font gives none out. Google's CSS
 * API serves TrueType instead of woff2 when the caller looks like an old
 * browser, and Satori cannot read woff2 — hence the deliberately ancient
 * user agent.
 *
 * These cards are prerendered (revalidate false plus generateStaticParams), so
 * this runs at build time. If the network is unavailable the fetch is allowed
 * to fail and the card falls back to Satori's own face: a card in the wrong
 * font is a worse card, but a build that dies over a font is a worse build.
 */
async function face(family: string, weight: number) {
  const url = `https://fonts.googleapis.com/css2?family=${family}:wght@${weight}`;
  const css = await fetch(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36' },
  }).then((r) => r.text());
  const src = /src: url\((?<u>[^)]+)\) format\('(?:truetype|opentype)'\)/.exec(css);
  if (!src?.groups) throw new Error(`no truetype for ${family} ${weight}`);
  return fetch(src.groups.u).then((r) => r.arrayBuffer());
}

let fontsOnce: Promise<
  { name: string; data: ArrayBuffer; weight: 400 | 500 | 600; style: 'normal' }[]
> | null = null;

function fonts() {
  fontsOnce ??= Promise.all([
    face('Fraunces', 600),
    face('Manrope', 600),
    face('JetBrains+Mono', 400),
  ])
    .then(([fraunces, manrope, mono]) => [
      { name: 'Fraunces', data: fraunces, weight: 600 as const, style: 'normal' as const },
      { name: 'Manrope', data: manrope, weight: 600 as const, style: 'normal' as const },
      { name: 'JetBrains Mono', data: mono, weight: 400 as const, style: 'normal' as const },
    ])
    .catch(() => []);
  return fontsOnce;
}

export async function GET(_req: Request, { params }: RouteContext<'/og/docs/[...slug]'>) {
  const { slug } = await params;
  const page = source.getPage(slug.slice(0, -1));
  if (!page) notFound();

  const title = page.data.title;
  const description = page.data.description ?? appDescription;

  return new ImageResponse(
    <div
      style={{
        width: '100%',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        background: RAIL,
        padding: '68px 76px',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
        {/* biome-ignore lint/performance/noImgElement: Satori renders img, not next/image */}
        <img src={MARK_SRC} width={62} height={62} alt="" />
        <div
          style={{
            fontFamily: 'Manrope',
            fontSize: 25,
            fontWeight: 600,
            letterSpacing: 3,
            textTransform: 'uppercase',
            color: RAIL_MUTE,
          }}
        >
          {appName}
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column' }}>
        <div
          style={{
            fontFamily: 'Fraunces',
            fontSize: 82,
            fontWeight: 600,
            lineHeight: 1.04,
            letterSpacing: -2.2,
            color: RAIL_INK,
            // Satori has no text-wrap: balance, so long titles are simply
            // clamped to two lines rather than pushing the card out of shape.
            display: 'flex',
            maxHeight: 180,
            overflow: 'hidden',
          }}
        >
          {title}
        </div>
        <div
          style={{
            fontFamily: 'Manrope',
            fontSize: 29,
            lineHeight: 1.45,
            color: RAIL_MUTE,
            marginTop: 26,
            maxWidth: 900,
            maxHeight: 128,
            overflow: 'hidden',
            display: 'flex',
          }}
        >
          {description}
        </div>
      </div>

      <div
        style={{
          display: 'flex',
          borderTop: '1px solid rgba(255,255,255,0.11)',
          paddingTop: 24,
          fontFamily: 'JetBrains Mono',
          fontSize: 23,
          color: RAIL_MUTE,
        }}
      >
        Every sample here is pulled from code that dart test runs.
      </div>
    </div>,
    { width: 1200, height: 630, fonts: await fonts() },
  );
}

export function generateStaticParams() {
  return source.getPages().map((page) => ({
    lang: page.locale,
    slug: getPageImageUrl(page).segments,
  }));
}
