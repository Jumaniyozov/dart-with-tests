import {
  type CardPalette,
  type ConsolePalette,
  cardDark,
  cardLight,
  consoleDark,
  consoleLight,
} from './palette';

/**
 * The SAFF syntax theme.
 *
 * This is a real TextMate theme rather than a recolouring of somebody else's,
 * because the book distinguishes eight roles in Dart and the off-the-shelf
 * themes do not: github-light gives `String` and `1_000_00` the same hex, so no
 * amount of remapping could make one gold and the other amber. Scopes are the
 * semantic layer; hex is only presentation, and remapping hex works on the
 * output after the semantics have already been thrown away.
 *
 * Both themes are built from one structure so that light and dark can differ in
 * colour but never in which scope means what.
 */

interface Setting {
  scope: string[];
  settings: { foreground?: string; fontStyle?: string };
}

/**
 * Scope names are matched by specificity: `variable.language.dart` (a keyword,
 * `this`) beats the broad `variable` rule below it, so the order here is for
 * readers, not for the resolver.
 */
function dartSettings(c: CardPalette): Setting[] {
  return [
    {
      // Declarations and control flow. Bold is the only weight TextMate has,
      // and this is the role that earns it.
      scope: [
        'keyword.declaration.dart',
        'keyword.control',
        'keyword.cast.dart',
        'keyword.new.dart',
        'keyword.other.import.dart',
        'storage.modifier.dart',
      ],
      settings: { foreground: c.keyword, fontStyle: 'bold' },
    },
    {
      // `true`, `null`, `this`, `super` — keyword-coloured, but bold on every
      // literal would shout.
      scope: ['constant.language.dart', 'variable.language.dart'],
      settings: { foreground: c.keyword, fontStyle: '' },
    },
    { scope: ['entity.name.function.dart'], settings: { foreground: c.fn } },
    {
      scope: ['support.class.dart', 'storage.type.primitive.dart'],
      settings: { foreground: c.type },
    },
    // The Dart grammar files `@override` under `storage.type.annotation`,
    // which is a type scope in name only.
    { scope: ['storage.type.annotation.dart'], settings: { foreground: c.annotation } },
    { scope: ['string'], settings: { foreground: c.string, fontStyle: '' } },
    { scope: ['constant.numeric.dart'], settings: { foreground: c.number } },
    {
      // `${` … `}` and its operators. Identifiers, calls and numbers nested
      // inside keep their own roles.
      scope: ['meta.embedded.expression.dart', 'constant.character.escape.dart'],
      settings: { foreground: c.interpolation },
    },
    { scope: ['comment'], settings: { foreground: c.comment, fontStyle: 'italic' } },
    // Members, from the injection grammar. TextMate cannot tell a field from a
    // variable on its own, which is why these scopes have to be invented here;
    // the IDE and Zed get the same distinction from a real parser.
    { scope: ['saff.field.dart'], settings: { foreground: c.field, fontStyle: '' } },
    {
      scope: ['variable', 'other.source.dart'],
      settings: { foreground: c.identifier, fontStyle: '' },
    },
    {
      scope: ['punctuation', 'keyword.operator'],
      settings: { foreground: c.punctuation, fontStyle: '' },
    },
  ];
}

/**
 * The console has its own ground, so its root scope carries the ink. Without
 * that, untokenised output would fall through to the theme's editor foreground,
 * which is set for the code card and is the wrong colour on the slab.
 */
function consoleSettings(c: ConsolePalette): Setting[] {
  return [
    { scope: ['source.saff-console'], settings: { foreground: c.ink, fontStyle: '' } },
    { scope: ['saff.console.timestamp'], settings: { foreground: c.dim, fontStyle: '' } },
    { scope: ['saff.console.prompt'], settings: { foreground: c.prompt } },
    { scope: ['saff.console.command'], settings: { foreground: c.command } },
    { scope: ['saff.console.pass'], settings: { foreground: c.pass, fontStyle: 'bold' } },
    { scope: ['saff.console.fail'], settings: { foreground: c.fail, fontStyle: 'bold' } },
    { scope: ['saff.console.ref'], settings: { foreground: c.ref } },
    { scope: ['saff.console.path'], settings: { foreground: c.path } },
    { scope: ['saff.console.caret'], settings: { foreground: c.caret, fontStyle: 'bold' } },
  ];
}

function build(name: string, type: 'light' | 'dark', card: CardPalette, term: ConsolePalette) {
  return {
    name,
    type,
    colors: { 'editor.background': card.ground, 'editor.foreground': card.identifier },
    settings: [
      { scope: ['source.dart'], settings: { foreground: card.identifier } },
      ...dartSettings(card),
      ...consoleSettings(term),
    ],
  };
}

export const saffLight = build('saff-light', 'light', cardLight, consoleLight);
export const saffDark = build('saff-dark', 'dark', cardDark, consoleDark);
