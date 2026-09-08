import Link from 'next/link';

const books = [
  { no: 'I', title: 'Foundations', span: 'Studies 1–22', line: 'The whole language, tests from study two.' },
  { no: 'II', title: 'Writing good Dart', span: 'Studies 23–34', line: 'An expense tracker, grown one slice per study.' },
  { no: 'III', title: 'Build the API', span: 'Studies 35–39', line: 'The same domain, served over HTTP.' },
  { no: 'IV', title: 'When you need it', span: 'Studies 40–44', line: 'Isolates, code generation, FFI, performance.' },
];

export default function HomePage() {
  return (
    <main className="flex-1">
      <section
        className="px-6 py-16 md:px-14 md:py-24"
        style={{ background: 'var(--etude-rail)', color: 'var(--etude-rail-ink)' }}
      >
        <div className="mx-auto max-w-4xl">
          <h1 className="text-[clamp(2.4rem,7vw,4.2rem)] font-bold leading-[0.98] tracking-[-0.035em] text-balance">
            Learn Dart with Tests
          </h1>
          <p className="mt-6 max-w-[54ch] font-[family-name:var(--font-body)] text-[1.12rem] leading-[1.62]">
            Forty-four studies in Dart 3.13. Every one names a technique, works a drill, and
            marks the result. You do not read a study. You run it.
          </p>
          <div className="mt-9 flex flex-wrap items-center gap-4">
            <Link
              href="/docs/foundations/hello-dart"
              className="inline-block px-6 py-3 text-[0.94rem] font-semibold"
              style={{ background: 'var(--etude-marked)', color: '#16352c' }}
            >
              Start study 1
            </Link>
            <Link href="/docs" className="text-[0.94rem] font-medium underline underline-offset-4">
              How to use this book
            </Link>
          </div>
        </div>
      </section>

      <section className="px-6 py-14 md:px-14">
        <div className="mx-auto max-w-4xl">
          <h2 className="text-[1.4rem] font-semibold tracking-[-0.02em]">The four books</h2>
          <div className="mt-7 flex flex-col">
            {books.map((b) => (
              <div
                key={b.no}
                className="grid grid-cols-[2.6rem_minmax(0,1fr)] gap-5 py-5 items-baseline"
                style={{ borderTop: '1px solid var(--etude-rule)' }}
              >
                <span
                  className="text-[1.6rem] font-bold leading-none tracking-[-0.03em]"
                  style={{ color: 'var(--etude-green)' }}
                >
                  {b.no}
                </span>
                <div>
                  <p className="text-[1.05rem] font-semibold">{b.title}</p>
                  <p className="mt-1 font-[family-name:var(--font-body)] text-[0.99rem] leading-[1.6] text-fd-muted-foreground">
                    {b.line}{' '}
                    <span className="font-mono text-[0.8rem]">{b.span}</span>
                  </p>
                </div>
              </div>
            ))}
          </div>

          <div
            className="mt-12 grid gap-8 md:grid-cols-2 pt-8"
            style={{ borderTop: '2px solid var(--color-fd-foreground)' }}
          >
            <div>
              <h3 className="text-[1.02rem] font-semibold">Every sample here compiles</h3>
              <p className="mt-2 font-[family-name:var(--font-body)] text-[0.99rem] leading-[1.66] text-fd-muted-foreground">
                The code on these pages is pulled from a Dart package in the same
                repository, and <code className="font-mono text-[0.86em]">dart analyze</code>{' '}
                and <code className="font-mono text-[0.86em]">dart test</code> run against it.
                The terminal output is real output, failures included.
              </p>
            </div>
            <div>
              <h3 className="text-[1.02rem] font-semibold">Not a Flutter book</h3>
              <p className="mt-2 font-[family-name:var(--font-body)] text-[0.99rem] leading-[1.66] text-fd-muted-foreground">
                Flutter deserves its own book, and mixing it in would make both worse. This
                one takes you to the point where Flutter makes sense. The format is
                borrowed, with thanks, from Chris James&rsquo; <em>Learn Go with Tests</em>.
              </p>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
