import Link from 'next/link';

const books = [
  {
    no: 'I',
    title: 'Foundations',
    span: 'Studies 1–22',
    line: 'The whole language, tests from study two.',
  },
  {
    no: 'II',
    title: 'Writing good Dart',
    span: 'Studies 23–34',
    line: 'An expense tracker, grown one slice per study.',
  },
  {
    no: 'III',
    title: 'Build the API',
    span: 'Studies 35–40',
    line: 'The same domain, served over HTTP.',
  },
  {
    no: 'IV',
    title: 'When you need it',
    span: 'Studies 41–45',
    line: 'Isolates, code generation, FFI, performance.',
  },
];

export default function HomePage() {
  return (
    <main className="flex-1">
      <section
        className="px-6 py-16 md:px-14 md:py-24"
        style={{ background: 'var(--rail)', color: 'var(--rail-ink)' }}
      >
        <div className="mx-auto max-w-4xl">
          <h1 className="font-[family-name:var(--font-display)] text-[clamp(2.5rem,7vw,4.4rem)] font-semibold leading-[0.98] tracking-[-0.028em] text-balance">
            Learn Dart with Tests
          </h1>
          <p className="mt-6 max-w-[54ch] font-[family-name:var(--font-body)] text-[1.12rem] leading-[1.64]">
            Forty-four studies in Dart 3.13. Every one names a technique, works a drill, and marks
            the result. You do not read a study. You run it.
          </p>
          <div className="mt-9 flex flex-wrap items-center gap-5">
            <Link
              href="/docs/foundations/hello-dart"
              className="inline-flex items-center rounded-card px-6 py-3.5 text-[0.94rem] font-semibold transition-opacity hover:opacity-90"
              style={{
                background: 'var(--on-rail-surface)',
                color: 'var(--on-rail-ink)',
              }}
            >
              Start study 1
            </Link>
            <Link
              href="/docs"
              className="text-[0.94rem] font-medium underline underline-offset-4"
              style={{ color: 'var(--brass-pale)' }}
            >
              How to use this book
            </Link>
          </div>
        </div>
      </section>

      <section className="px-6 py-14 md:px-14">
        <div className="mx-auto max-w-4xl">
          <h2 className="font-[family-name:var(--font-display)] text-[1.6rem] font-semibold tracking-[-0.015em]">
            The four books
          </h2>
          <div className="mt-7 grid gap-4 sm:grid-cols-2">
            {books.map((b) => (
              <div
                key={b.no}
                className="rounded-card grid grid-cols-[2.2rem_minmax(0,1fr)] gap-4 px-5 py-5 items-baseline"
                style={{
                  background: 'var(--porcelain-2)',
                  border: '1px solid var(--hairline)',
                  boxShadow: '0 1px 2px oklch(24% 0.03 170 / 0.05)',
                }}
              >
                <span
                  className="font-[family-name:var(--font-display)] text-[1.7rem] font-semibold leading-none tracking-[-0.02em]"
                  style={{ color: 'var(--emerald)' }}
                >
                  {b.no}
                </span>
                <div className="min-w-0">
                  <p className="text-[1.02rem] font-semibold" style={{ color: 'var(--ink)' }}>
                    {b.title}
                  </p>
                  <p
                    className="mt-1.5 font-[family-name:var(--font-body)] text-[0.96rem] leading-[1.6]"
                    style={{ color: 'var(--ink-3)' }}
                  >
                    {b.line}
                  </p>
                  <p
                    className="mt-2 font-mono text-[0.75rem]"
                    style={{ color: 'var(--brass-ink)' }}
                  >
                    {b.span}
                  </p>
                </div>
              </div>
            ))}
          </div>

          <div
            className="mt-12 grid gap-8 md:grid-cols-2 pt-8"
            style={{ borderTop: '1px solid var(--brass)' }}
          >
            <div>
              <h3 className="font-[family-name:var(--font-display)] text-[1.15rem] font-semibold">
                Every sample here compiles
              </h3>
              <p
                className="mt-2 font-[family-name:var(--font-body)] text-[0.99rem] leading-[1.66]"
                style={{ color: 'var(--ink-3)' }}
              >
                The code on these pages is pulled from a Dart package in the same repository, and{' '}
                <code className="font-mono text-[0.86em]">dart analyze</code> and{' '}
                <code className="font-mono text-[0.86em]">dart test</code> run against it. The
                terminal output is real output, failures included.
              </p>
            </div>
            <div>
              <h3 className="font-[family-name:var(--font-display)] text-[1.15rem] font-semibold">
                Not a Flutter book
              </h3>
              <p
                className="mt-2 font-[family-name:var(--font-body)] text-[0.99rem] leading-[1.66]"
                style={{ color: 'var(--ink-3)' }}
              >
                Flutter deserves its own book, and mixing it in would make both worse. This one
                takes you to the point where Flutter makes sense. The format is borrowed, with
                thanks, from Chris James&rsquo; <em>Learn Go with Tests</em>.
              </p>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
