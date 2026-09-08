# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Next.js 16 + Fumadocs (MDX, App Router), npm, TypeScript, Tailwind 4, Biome. Deployed to
Vercel. Chapter code lives in a separate Dart 3.13 pub workspace (`code/`) and is pulled
into the pages at build time by Fumadocs' `<include>` transclusion, so the book cannot
contain a snippet that was never compiled and tested.

## Users

Primary: people learning Dart as one of their first programming languages. They read with
an editor and a terminal open and type along; they are not skimming for reference. Many,
including the author, read English as a second language.

Secondary: programmers fluent in another language who want idiomatic Dart quickly and will
skip the foundations.

Not an audience: Flutter developers looking for widget guidance. Flutter is deliberately
out of scope and planned as a separate book.

## Product Purpose

Teach idiomatic, pragmatic Dart by building real software, using tests as the mechanism
that proves each idea works. Success is a reader who finishes able to start a Dart project,
model a domain, test it without mocking everything, and ship a CLI and an HTTP API.

## Positioning

A Dart counterpart to Chris James' *Learn Go with Tests*, with one deliberate difference:
that book leads with the test, this one explains the concept first and then uses a TDD
sequence to prove and sharpen it. The author is explicit that the goal is not TDD dogma.

The mechanism a neighbouring book could not truthfully copy: every code sample is included
from a real package in the repository that `dart analyze` and `dart test` run against, so
the book's examples cannot drift from working code.

## Operating Context

The reader works in three places at once: this book, an editor, and a terminal running
`dart test`. Verbatim terminal output — including failures — is primary content, not
decoration. Chapters end with challenges shipped as already-failing tests the reader makes
green, so the book verifies the reader rather than the reader trusting an answer key.

## Capabilities and Constraints

- Dart 3.13.2 is the target; the book must cover language features through 3.13
  (digit separators, wildcard variables, null-aware elements, dot shorthands, private named
  parameters, primary constructors).
- 44 chapters in four phases: Foundations (1–22, whole language, tests from ch2), Writing
  good Dart (23–34, an expense-tracker CLI grown one slice per chapter), Build the API
  (35–39, `dart:io` → `shelf` with `sqlite3`, reusing the CLI's domain package), and
  When you need it (40–44, reference depth: isolates, codegen, FFI, performance).
- Testing uses `package:test` and `package:matcher`. `package:checks` is experimental and
  is mentioned once, never taught.
- No in-browser code execution. An earlier version embedded a DartPad editor; it was
  removed deliberately. The reader runs code locally.
- Surfaces: chapter pages, a home/cover page, and a reference/cheatsheet section that is
  scanned rather than read through. No separate progress-overview page.
- Per-chapter reading progress is kept in the browser via localStorage.

## Brand Commitments

- Title: **Learn Dart with Tests**.
- Chris James and *Learn Go with Tests* are credited in the front matter as the origin of
  the format.
- The v1 book's "flight deck" palette (ink `#0A1322`, cyan `#36D2F2`, amber `#F4B740`,
  Space Grotesk / IBM Plex Sans / JetBrains Mono) is prior art, **not** a binding
  constraint. The visual direction is open.

## Evidence on Hand

- `archive/dart-book-v1.html` — the 3304-line v1 book. Source-verified prose to mine, but
  its version claims are stale (it targets Dart 3.12 and covers no feature after 3.5).
- `code/` — Dart pub workspace. Chapters 1 and 2 written: `dart analyze` clean, 8 tests
  passing, 6 challenge tests deliberately red and verified solvable.
- No readers, no testimonials, no download numbers, no reviews. Nothing of the kind exists
  and none may be invented for any surface, including the home page.

## Product Principles

1. **No unverified code.** If a snippet is in the book, it came from a file the test suite
   ran. Intermediate stages get their own tested files; only deliberately-broken examples
   are inline.
2. **Concept, then proof.** Explain the idea in prose, then drive it with a test. Tests are
   how the reader checks understanding, not a ritual to perform.
3. **Name the bad choice out loud.** When a chapter shows something suboptimal because the
   better tool comes later, say so and name the chapter that fixes it.
4. **Write for a second-language reader.** Short sentences, active voice, one idea per
   sentence, no idiom or wordplay. Every term defined the first time it appears.
5. **The reader never leaves their editor.** The book explains; the machine on their desk
   verifies.

## Accessibility & Inclusion

- Sustained long-form reading is a product requirement, not a preference: 44 chapters read
  end to end.
- English as a second language is the assumed reading condition.
- The red–green–refactor cycle is the book's core signal. Colour may never be its only
  carrier — every phase also carries a name and a number, so red–green colour blindness
  does not degrade comprehension.
