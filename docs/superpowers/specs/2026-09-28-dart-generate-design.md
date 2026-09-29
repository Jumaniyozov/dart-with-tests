# dart_generate: design

A Dart analyzer plugin that adds "Generate" actions to the code action menu (Cmd+.)
of VS Code and Zed. It brings the Android Studio "Generate" menu to those editors and
replaces the hzgood "Dart Data Class Generator" extension. It reads classes with the
real analyzer, so primary constructors and class modifiers work.

## Scope

- **User.** One person, in their own repos. There is no publishing to pub.dev or to an
  editor marketplace.
- **Dart.** 3.13 or later. Primary constructors are the default class syntax, as in
  darty ADR 0002.
- **Editors.** VS Code and Zed only. Android Studio is not a target, and no test
  covers it. VS Code also has a separate extension. Its design is in
  [2026-09-28-vscode-extension-design.md](2026-09-28-vscode-extension-design.md).
- **Not in darty.** The book repo does not enable the plugin. Its members are
  hand-written teaching material, and `code/tool/check_also_met.dart:40` reads
  `code/analysis_options.yaml` as evidence. A local `plugins:` block can weaken that
  check on the author's machine.

## Decisions

| ADR | Decision |
|---|---|
| [0001](../../adr/0001-analyzer-plugin-not-a-language-server.md) | An analyzer plugin, not our own language server |
| [0002](../../adr/0002-generator-set-follows-effective-dart.md) | The Android Studio set, changed to follow Effective Dart and primary constructors |
| [0003](../../adr/0003-builder-is-the-first-public-covering-constructor.md) | copyWith and JSON call the first public, callable constructor that covers every field |
| [0004](../../adr/0004-copywith-clears-nullable-fields-with-a-sentinel.md) | copyWith clears a nullable field with a sentinel default |
| [0005](../../adr/0005-fromjson-takes-object-and-reads-with-map-patterns.md) | `fromJson(Object? json)` reads with map patterns and throws `FormatException` |
| [0006](../../adr/0006-each-assist-catches-and-logs-its-own-failure.md) | Each assist catches and logs its own failure |
| [0007](../../adr/0007-vscode-extension-beside-the-plugin.md) | A VS Code extension beside the plugin |
| [0008](../../adr/0008-stale-generated-members-get-a-warning-or-a-hint.md) | Stale-member diagnostics in the VS Code extension |

## Architecture

```
dart_generate/
  core/            package generate_core: model, rules, generators. No analyzer dependency.
  plugin/          package dart_generate: lib/main.dart, adapter, one assist per generator.
  fixtures/        package fixtures: lib/ is the expected output, test/ checks its behavior.
    input/         the same classes without generated members, with markers.
  docs/adr/
```

- **The dependency rule is enforced by pub.** `core` does not depend on `analyzer`, so
  it cannot import it. Only `plugin/` reads the analyzer.
- **Versions are pinned exactly.** `analysis_server_plugin: 0.3.23`, which pins
  `analyzer: 14.4.0`. Both ship from the Dart SDK repo.
- **The plugin entry point** is `plugin/lib/main.dart` with a top-level `plugin`
  variable, as the analyzer plugin docs require.
- **Elements give meaning, the syntax tree gives positions.** The adapter reads
  resolved elements to build the model. It reads the syntax tree only for offsets,
  existing members and the conversion rewrite.
- **Assist IDs start with `generate.`.** The server turns an ID into the LSP kind
  `refactor.<id>`, so every action has the kind `refactor.generate.*`. The six IDs
  are `generate.toString`, `generate.equality`, `generate.copyWith`, `generate.json`,
  `generate.getter` and `generate.primaryConstructor`.

## Class model

```dart
final class ClassModel(
  final String type,               // thisType, for example 'Range<T>'
  final List<FieldModel> fields,   // non-static fields: own, plus inherited through
                                   // super parameters of any constructor
  final ConstructorModel? builder, // null means no copyWith and no JSON
);
final class FieldModel(final String name, final TypeModel type,
    final bool isFinal, final bool isLate, final bool hasInitializer);
final class ConstructorModel(final String call, final List<ParamModel> params);
final class ParamModel(final String name, final TypeModel type,
    final bool isNamed, final bool isRequired, final String? defaultValue);
sealed class TypeModel { bool get isNullable; }
// primitive (int, String, bool, num) | double | passthrough (Object?, dynamic)
// | dateTime | enumType | list | set | map | typeParameter | other(name)
```

**Builder rule (ADR 0003).** The builder is the first constructor that meets all of
these conditions:

1. It is public.
2. It can be called. A generative constructor of an abstract class does not qualify.
3. Each parameter names a field, and the field type is assignable to the parameter type.
4. Together, the parameters cover every field, except `late` fields with an initializer.

The candidates are, in order, the unnamed constructor, then named constructors in
declaration order. If none qualifies, the builder is null.

**Field rules.**

- toString and `==` use every field that is not `late`.
- `==` needs every field in the class to be `final`.
- Fields that come from mixins are not included.

## Generators

| Action | Offered when | Output |
|---|---|---|
| Generate toString() | Cursor on the class header or a field, and one or more fields | `'Payment(pence: $pence, to: $to)'`. A text over 70 characters splits into adjacent string literals after a comma, because the formatter never splits a string. |
| Generate ==() and hashCode | Same, and every field is `final` | `other is X && other.a == a`. The hash is `a.hashCode` for one field (`DeepCollectionEquality().hash(a)` for a collection), `Object.hash` for 2 to 20 and `Object.hashAll` above 20. A collection field uses `const DeepCollectionEquality()` and the import is added. |
| Generate copyWith() | A builder with one or more parameters | Named `T?` parameters with `a ?? this.a`. A nullable field, or a type parameter with a nullable bound, uses `Object? a = _unset` and one `static const _unset = Object();`. The call goes to the builder. |
| Generate toJson() and fromJson() | A builder with one or more parameters, and no field is a type parameter, a nested collection or a map with non-String keys | See the JSON rules |
| Generate getter | Cursor on a private field with no public member of the same name | `int get count => _count;` after the field. For a header field, at the start of the body. |
| Convert to primary constructor | Cursor on the header of a class without a primary constructor. The class has exactly one generative constructor. It is unnamed, has only `this.` and `super.` parameters, and has no body, initializer list, assert or annotation. It is not `external`. No parameter is function-typed, such as `this.onTap()`. A moved field has no initializer and is not `late`. Either every variable of a declaration such as `final int a, b;` is a parameter, or none is. A class without a generative constructor has nothing to move, so the action is not offered. | `class const Pair(final int left, final int right) {}`. Field doc comments and annotations move onto the parameters. A non-final field becomes `var`. The constructor doc comment moves to the end of the class doc. A comment at the end of a moved field's line moves with its parameter. A comment at the end of the constructor's line stays in the class body. A class left without members keeps `{}`, not `;`, as in 74 of darty's 75 non-sealed classes of that shape. The opt-in lint `empty_container_bodies` prefers `;`. The user chose `{}` on 2026-09-28. |

**Names.** A private builder parameter such as `_count` becomes `count` in copyWith and
in the JSON key. copyWith passes `count ?? _count`.

**JSON rules (ADR 0005).** Keys are the builder parameter names.

| Type | toJson | fromJson |
|---|---|---|
| `int` `String` `bool` `num` | as is | in the map pattern |
| `Object` `Object?` `dynamic` | as is | `final Object x` in the pattern. `Object?` and `dynamic` are nullable, so they are read after the match as `map['k']`. |
| `double` | as is | `num` in the pattern, then `.toDouble()` |
| enum | `.name` | `asNameMap()[k] ?? (throw FormatException(...))` |
| `DateTime` | `.toIso8601String()` | `final String x`, then `DateTime.tryParse(x) ?? (throw FormatException(...))` |
| other type | `.toJson()` | `final Object x` in the pattern, then `X.fromJson(x)` |
| `List<E>`, `Set<E>` | `[for (final e in x) conv(e)]`. A list of primitives goes as is, and a set of primitives as `x.toList()`. A nullable collection uses `x?.map((e) => conv(e)).toList()`. | `final List<Object?> x`, then a list or set with the element rule |
| `Map<String, V>` | `{for (final MapEntry(:key, :value) in x.entries) key: conv(value)}`, or as is for primitive values. A nullable map uses `x?.map((key, value) => MapEntry(key, conv(value)))`. | `final Map<String, Object?> x`, then the same shape with the value rule |
| nullable, no default | `?.` where a call is needed | after the match: `switch (map['k']) { null => null, ... }` |
| has a default | as is | after the match: `map.containsKey('k') ? check : default` |

- **Signature.** fromJson is `factory X.fromJson(Object? json) => switch (json) {...}`.
  The last case throws `FormatException('Invalid X JSON', json)`.
- **Error messages.** Each check names its key, for example
  `FormatException('Invalid "kind" in Expense JSON', json)`.
- **Required keys and the map binding.** Required keys go in the map pattern. If an
  optional key exists, the case also binds `final Map<String, Object?> map &&`.
- **Local names.** A required key binds a local with the same name. The keys `json`
  and `map` bind `jsonValue` and `mapValue`, because the parameter and the map
  binding use those names.
- **Why `tryParse`.** `DateTime.parse` throws a `FormatException` that names no key.

### Existing members

- If a member exists, the title starts with "Regenerate" and the edit replaces the
  member in place, from its first annotation to its end (the annotation rule under
  Formatting below). It keeps the doc comment. Other annotations are removed, such
  as `@useResult`, `@Deprecated`, or an `@override` on toJson. Add them again after
  you regenerate. The user chose to keep this rule on 2026-09-28.
- `==` and hashCode are replaced together, and so are toJson and fromJson.
- If the existing toString body starts with `'ClassName(` and a field label, such
  as `'Point(x: `, the menu offers "Regenerate toString()". Otherwise it offers
  nothing. This protects hand-written domain text such as `=> asText` and
  `'Money(${format()})'`.
- If copyWith is regenerated and `_unset` is no longer used, the edit removes it.
- An existing `_unset` alone does not make the title "Regenerate". It is a helper,
  the same text every time, and it is kept as written either way.

### Selection

If the selection covers one or more fields, toString and `==`/hashCode use only those
fields. copyWith and JSON always use every builder parameter.

A plain header parameter is not a field. A selection of only plain parameters is
empty, so the action covers the whole class.

### Placement

- `factory X.fromJson` goes after the last constructor. For a class with only a
  header constructor, it goes at the start of the body. Constructors first is the
  usual Dart order, and darty's order.
- Two new members can have something else after them: Generate getter, after
  the field, and `factory X.fromJson`, after the last constructor. When
  another member, or a comment on a later line, follows before the closing
  `}`, a blank line goes after that inserted member too.
- Every other new member goes at the end of the class body, after one blank line.
- The end of the body is after its last member, and after any comment before `}`.
- A `;` body becomes `{ ... }`.
- A doc comment at the end of a line documents the next declaration, so it is not
  part of that line: it stays with the declaration that follows it.

### Formatting and imports

Each action calls `DartFileEditBuilder.format` once, over the class body from `{` to
`}`. The range is in the coordinates of the original file, and it must start and end
on a token that is already in the file.

- **One format per action.** The action first adds every replacement, insertion and
  deletion as a plain edit, and then formats once. If a range covers only part of an
  earlier edit, `format` throws. With one format per edit, a replaced member and
  a new member next to it shared a token. Their ranges overlapped, and the action
  disappeared.
- **Code in the class body is formatted too.** The range is the whole body, so the
  members that are already in that class are formatted with the new ones. The format
  does not touch code outside the class.
- **One edit takes a small range.** A `;` body becomes `{ ... }` in one replacement,
  formatted from the token before the `;`. Generate getter inserts one member, and its
  range runs from the token before it to the token after it. One edit cannot collide.
  Convert to primary constructor rewrites the header too, so it formats the whole
  class.
- **An insertion goes right after an existing token,** and after any comment that
  ends that line. A doc comment on that line is an exception: see Placement above,
  it belongs to the next declaration instead. The end-of-body insertion also goes
  past a comment on a later line, before `}`. The new line and the indent on both
  sides are then inside the range.
- **A range that starts in whitespace loses that whitespace.** The formatted text of
  a range starts and ends at a token. In the prototype, a range that was only the
  closing brace put the new member at column 0 with no blank line before it.
- **A replaced member keeps its doc comment.** Its edit runs from its first annotation
  to its end.
- **A wrong range fails silently.** A range in edited-text coordinates ran past the
  end of the original file. `compute` threw, and the assist disappeared with no error.

Imports go through `importLibrary`. This needs no `dart_style` dependency.

## Not offered

`NotOffered(reason)` uses one enum, defined in `core`. Each reason has one owner.

| Owner | Reasons | Tested by |
|---|---|---|
| core, from the model | `noFields`, `noBuilder`, `mutableClass`, `typeParameterField`, `nestedCollection`, `nonStringMapKey` | core tests |
| adapter, from the syntax tree | `customToString`, `notConvertible`, `publicNameTaken`, `notAClass` | e2e `@not` markers |

`noBuilder` covers every way the builder rule can fail. The README lists the four
conditions under it. The README has one row per reason, and a core test makes sure
that each enum value name appears in the README.

## Errors

- **Each assist catches its own failure (ADR 0006).** It appends the time, the
  generator, the file and the stack trace to the log, then returns no edit. It
  rethrows only `InconsistentAnalysisException`, because the server already handles
  it.
- **A conflicting edit is logged.** The server drops an action with a
  `ConflictingEditException`, but it writes no log. The edit is built in a private
  draft, so a conflict can only come from dart_generate's own placement code, and it
  is always our bug. The first version rethrew it, and that hid a bug in Task 11 of
  the plan: the JSON action was missing on every class whose last member was a
  constructor, and the log stayed empty.
- **No partial edit.** The server reads the builder after `compute` returns, so a
  caught error after half an edit still shows a broken action. Each assist builds
  its edit in a draft `ChangeBuilder` and copies the edits to the server's builder
  only at the end. In the prototype, a planted throw in the JSON assist removed only
  the JSON action. The other actions stayed, and the log recorded the error.
- **Log location.** The log path is the value of `DART_GENERATE_LOG`. If the variable
  is not set, the path is `~/.dartServer/dart_generate.log`. If the log passes 1 MB,
  the plugin empties it. A spike showed that the plugin inherits the server's
  environment and can write files.
- **Speed.** Each assist checks whether it applies before it builds text, because
  VS Code asks for code actions on every cursor move.

## Setup

In each checkout, add these lines to `analysis_options.yaml` and never commit them:

```yaml
plugins:
  dart_generate:
    path: /Users/islom/Projects/dart_generate/plugin
```

- **An accidental commit fails loudly.** On any machine without that path,
  `dart analyze` exits with code 4, so CI turns red.
- **A `git:` source is optional.** It can be committed, but every CI run then compiles
  the plugin (16 s cold) for actions that CI never uses. It also needs a remote. A
  `git:` source with `path: plugin` and the `../core` path dependency compiled in a
  test.

For a VS Code key that shows only the generate actions, add this to `keybindings.json`:

```json
{
  "key": "cmd+n",
  "command": "editor.action.codeAction",
  "args": { "kind": "refactor.generate", "apply": "never" },
  "when": "editorTextFocus && editorLangId == dart"
}
```

In a Dart editor, this key replaces "New Untitled Text File". Android Studio uses
the same key for its Generate menu.

Zed shows the actions in its normal code action menu. It has no filter by kind.

### Troubleshooting

1. If no action appears, run `dart analyze` in the project.
2. Look for "An error occurred while executing an analyzer plugin" in the output.

- A compile error in the plugin gives exit code 0.
- A missing path gives exit code 4.
- If an action is missing on only one class, read the README table of reasons.
- If an action fails, read the log.

## Testing

1. **Core tests (fast).** They test decisions only: the builder choice, each
   core-owned `NotOffered` reason, the JSON key names and the type rule chosen for
   each field.
2. **Placement unit tests (fast).** They are their own layer, under
   `plugin/test/`, with no tag. They call `afterLine` directly on parsed
   source, with no server. `dart format` moves a doc comment at the end of a
   line to its own line, so a formatted fixture cannot hold that shape. This
   layer tests it instead.
3. **Fixtures package.** `lib/` is the expected output.
   - `dart analyze` must report no issues under the strict options (`strict-casts`,
     `strict-inference`, `strict-raw-types`) and `package:lints/recommended.yaml`.
   - `dart test` checks the round trip, clearing a nullable field, old files without
     a defaulted key, JSON `1` read as `1.0`, a `FormatException` for each key, and an
     explicit `null` that survives a non-null default.
4. **End-to-end over LSP (tag `e2e`).** The test starts `dart language-server` on a
   copy of `input/`. `DART_GENERATE_LOG` points to a temporary file.
   - **Markers.** A marker names the actions and a target, for example
     `// @generate toString, equality, copyWith, json`,
     `// @generate getter at _count`, `// @generate toString select left..right` and
     `// @not copyWith noBuilder`. A `@not` marker names the reason that it covers.
     `// @regenerate` asks for the same as `@generate`, and also asserts that the
     action's title starts with "Regenerate" because the member already exists.
     Every `@generate` and `@regenerate` marker also checks the action's title,
     except getter and Convert, which have one fixed title each: "Generate
     getter" and "Convert to primary constructor". The other four generators
     check that the title starts with the marker's verb, "Generate" or
     "Regenerate".
   - **Isolation.** Each checkout gets its own temp root, named by a hash of the
     checkout path. So two checkouts never share a `~/.dartServer/.plugin_manager`
     entry. A lock file sits next to the root. It makes a second run in the same
     checkout wait for the first, instead of racing it for the same root.
   - **Update mode.** `DART_GENERATE_UPDATE=1` writes the output to `fixtures/lib/`
     instead of comparing. Read the diff before you commit it.
   - **Steps.** The test polls for up to 120 s until the first expected action
     appears. It matches actions by kind, applies each edit, and compares every file
     with `fixtures/lib/`. The files in `lib/` keep the same marker lines, so the
     comparison strips nothing.
   - **Failures.** The test fails in each of these cases:
     - It finds zero markers, or `input/` is missing.
     - An input file has no expected file, or an expected file has no input file.
     - A marker names an unknown generator, or a generator appears in no marker.
     - An adapter-owned `NotOffered` reason appears in no `@not` marker.
     - A `@not` marker is in a file where no action appeared at all.
     - `dart analyze` prints a plugin error.
     - The log file is not empty.
     - `dart pub get --offline` exits with a code other than 0.
     - A `@not` marker's reason is not the name of a `Reason` value.
     - The server exits. Every request that is still waiting then fails, instead
       of hanging.
     - An action's title fails its check: the fixed title, for getter or
       Convert, or a start with the marker's verb, for the other four.
   - **Before you trust a green run.** Make the test fail four ways: change one
     expected file, remove the `plugins:` line, add a generator name that no marker
     uses, and make one assist throw. Each change must turn the test red.
5. **Manual, once.** Press Cmd+. on a fixture in Zed. Use the `refactor.generate` key
   in VS Code.

**After a Dart SDK upgrade.** Run the e2e tests. Add a fixture that uses the newest
syntax you write. If the tests fail, move the `analysis_server_plugin` pin.

The server's plugin entry point requires the `analysis_server_plugin` range that
matches its protocol. Dart 3.13.2 requires `^0.3.8`. A newer SDK can require a newer
range. The exact pin then fails version solving, and `dart analyze` prints the error.

## Known limits

- fromJson calls the builder. If that is a validating factory, well-typed but invalid
  data throws the factory's `ArgumentError`. The generator cannot know the domain rule.
- A missing `X.fromJson` is a compile error on the generated line.
- The `==` rule treats a class with a `final List` field as immutable. The list itself
  can still change.
- A `double` field that holds `NaN` is never equal to itself.
- No field picker dialog. Selection replaces it.
- The first start compiles the plugin. The first `dart analyze` took 16 s. In the
  first editor probe, the action was missing after 4 s and present after 45 s. The
  time between those two points was not measured. Later `dart analyze` runs took 4 s
  instead of 2 s.
- The plugin runs its own analysis in the server process. On a 600-file workspace the
  server used 317 MB instead of 224 MB, in one measurement each.
- Each plugin configuration keeps a compiled copy of about 14 MB in
  `~/.dartServer/.plugin_manager`.
- An `Object?` or `dynamic` field that holds a list or a map compares by identity in
  `==`.
- A type from a prefixed import loses its prefix in generated code. The generated
  line then does not compile.
- In a file with a syntax error, the formatter gives up. The generated members are
  not indented. Format the file after you fix the error.
- Regenerate replaces the whole member, from its first annotation to its end. It
  keeps the doc comment. Other annotations are removed, such as `@useResult`,
  `@Deprecated`, or an `@override` on toJson. Add them again after you regenerate.
- Convert to primary constructor leaves a comment that ended the constructor's
  line in the class body.

## Evidence

All measurements come from Dart 3.13.2 on macOS, collected on 2026-09-28.

| Claim | How it was checked |
|---|---|
| Plugin assists reach LSP clients, and inside pub workspace members | Raw LSP probe on darty's `code/` copy: `refactor.gen.assist.toString` offered on `class const Expense(` |
| The `only: ["refactor.gen"]` filter works | The same probe with `context.only` |
| Zed requests `refactor` actions | `crates/lsp/src/lsp.rs:956` in zed-industries/zed |
| A missing path gives exit 4, and a git source works | `dart analyze` on a scratch project |
| A git source with `path: plugin` and a `../core` path dependency compiles | The plugin manager built `plugin.aot` from a scratch git repo |
| A compile error gives exit 0, and the actions disappear | The same, with a broken core file |
| An edit in `core/` alone reaches the plugin after a restart | The probe before and after the edit |
| The generated code compiles and behaves | `golden.dart` and `golden2.dart` under darty's analysis options |
| One throwing producer fails every plugin assist in the request | `assist_processor.dart:61` catches only `ConflictingEditException` |
| The `format` range uses original-file coordinates and starts on a token | A range past the original end made the assist disappear. A range of only the closing brace dropped the line break before the new member. |
| The generated fixtures are clean | `dart analyze` on `fixtures/` reported no issues, and `dart format` changed 0 of 9 files |
| A throwing assist leaves no partial edit | A planted throw removed only the JSON action, and the log test failed |
| The end-to-end test fails without the plugin | Without the `plugins:` block, it failed after 120 s with `no refactor.generate.toString` |
| darty's `Day` gets a builder | ch25 to ch40 each have `factory Day(int year, int month, int day)` |
