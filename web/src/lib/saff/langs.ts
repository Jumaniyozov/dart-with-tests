/**
 * Grammars the SAFF theme colours that Shiki does not ship.
 *
 * Both are small on purpose: the theme decides colour, and a grammar's only job
 * is to say what a run of characters *is*.
 */

/**
 * A grammar as Shiki wants it. Declared locally rather than imported from
 * `shiki`, which is only a transitive dependency here; the shapes are checked
 * structurally where they are handed to `rehypeCodeOptions`.
 */
interface Rule {
  match: string;
  name?: string;
  captures?: Record<string, { name: string }>;
}

interface Grammar {
  name: string;
  scopeName: string;
  repository: Record<string, Rule>;
  patterns: Rule[];
  injectionSelector?: string;
  injectTo?: string[];
}

/**
 * Terminal transcripts.
 *
 * These are captured output, not shell scripts, so highlighting them as bash
 * finds a command on the first line and nothing at all on the rest — the test
 * counts, the `[E]` markers, the file references and the caret are the part a
 * reader actually needs to see. Scope names live under `saff.console.*` so they
 * cannot collide with the Dart rules in the same theme.
 */
export const saffConsole: Grammar = {
  name: 'saff-console',
  scopeName: 'source.saff-console',
  // No shared sub-rules: every pattern is a single line-level match.
  repository: {},
  patterns: [
    {
      // `$ dart test test/` — the prompt is brass, the command is what you type.
      match: '^(\\$)([ \\t]+)(.*)$',
      captures: {
        '1': { name: 'saff.console.prompt' },
        '3': { name: 'saff.console.command' },
      },
    },
    // The test runner's elapsed clock. Present on every line, so it recedes.
    { match: '^\\d{2}:\\d{2}', name: 'saff.console.timestamp' },
    { match: '\\+\\d+', name: 'saff.console.pass' },
    { match: '-\\d+', name: 'saff.console.fail' },
    { match: '\\[E\\]', name: 'saff.console.fail' },
    // `Error:`, `UnimplementedError:` — but not the `Error` inside prose such as
    // "Error when reading", which carries no colon.
    { match: '\\b(\\w*Error):', captures: { '1': { name: 'saff.console.fail' } } },
    // `dart analyze` severity column.
    { match: '^(\\s*)(error)\\b', captures: { '2': { name: 'saff.console.fail' } } },
    // `test/first_test.dart:1:8` — a place you can go and look.
    { match: '[\\w./_-]+\\.\\w+:\\d+(?::\\d+)?', name: 'saff.console.ref' },
    { match: '"[^"\\n]*"|\'[^\'\\n]*\'', name: 'saff.console.path' },
    { match: '\\^+', name: 'saff.console.caret' },
  ],
};

/**
 * Corrections to the bundled Dart grammar.
 *
 * Four things the grammar gets wrong for this book, fixed in one injection so
 * there is a single place to look when a token is the wrong colour:
 *
 * 1. It files `var` under `storage.type.primitive`, the same scope as `void`,
 *    which would print `var` as a type and `final`/`const` as keywords. Study 3
 *    is *about* the difference between those three words; they have to look
 *    like the same kind of word.
 * 2. It leaves brackets, braces, commas and generic angles unscoped, so they
 *    would take the identifier colour instead of receding.
 * 3. Its call rule matches at the *name* and swallows the following `(` as an
 *    unnamed tail. TextMate resolves competition by earliest match, so a rule
 *    matching only `(` never runs — the fix has to claim the name and its
 *    parenthesis together, and `L:` wins the tie. The lookahead keeps `if(a)`
 *    a keyword rather than a call.
 * 4. It marks calls but not accessor names, so `get isLarge` lost its member.
 *
 * `-string -comment` keeps all of it out of interpolation, where the
 * parentheses of `${(cents / 100)}` belong to the expression around them.
 */
/**
 * The short form of string interpolation.
 *
 * Dart writes `$name` and `${expr}`, and the grammar gives both the same scope,
 * so a theme cannot tell them apart. They want different treatment: inside
 * braces the expression is code and its identifiers keep their own colour,
 * while a bare `$name` reads as one thing and takes the interpolation colour
 * whole. Requiring a letter after the `$` matches only the short form, and
 * `L:` lets it claim the name before the grammar's own rule reaches it.
 */
export const saffDartInterpolation: Grammar = {
  name: 'saff-dart-interpolation',
  scopeName: 'saff.injection.dart-interpolation',
  injectionSelector: 'L:string',
  injectTo: ['source.dart'],
  repository: {},
  patterns: [{ match: '\\$[$_a-zA-Z][$\\w]*', name: 'meta.embedded.expression.dart' }],
};

export const saffDart: Grammar = {
  name: 'saff-dart',
  scopeName: 'saff.injection.dart',
  injectionSelector: 'L:source.dart -string -comment',
  injectTo: ['source.dart'],
  repository: {},
  patterns: [
    { match: '\\b(?:var|deferred)\\b', name: 'keyword.declaration.dart' },
    {
      match:
        '(?!(?:if|for|while|switch|catch|return|assert|await|throw|else|do|in|is|as|new|this|super|yield|rethrow|set|get)\\b)([$_]*[a-z][$\\w]*)([!?]?\\()',
      captures: {
        '1': { name: 'entity.name.function.dart' },
        '2': { name: 'punctuation.bracket.dart' },
      },
    },
    {
      match: '\\b(get|set)\\s+([$_]*[a-z][$\\w]*)',
      captures: {
        '1': { name: 'keyword.declaration.dart' },
        '2': { name: 'entity.name.function.dart' },
      },
    },
    { match: '[{}()\\[\\],<>]', name: 'punctuation.bracket.dart' },
  ],
};
