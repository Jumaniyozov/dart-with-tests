# dart_generate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the dart_generate analyzer plugin: six Generate actions for Dart classes in VS Code and Zed, as the spec describes.

**Architecture:** Three packages in one repo. `core/` (package `generate_core`) holds the class model, the builder rule and the text generators, with no analyzer dependency. `plugin/` (package `dart_generate`) reads resolved classes into the model and turns the text into edits. `fixtures/` holds input classes with markers and the expected output, and an end-to-end test drives the real analysis server over LSP.

**Tech Stack:** Dart 3.13.2, `analysis_server_plugin` 0.3.23, `analyzer` 14.4.0, `analyzer_plugin` 0.14.17, `package:test`, `package:collection`, `package:lints`.

**Source of truth:** `docs/superpowers/specs/2026-09-28-dart-generate-design.md` and `docs/adr/0001` to `0006`. Task 1 corrects them first.

**Evidence:** Every code block in this plan ran in a prototype on 2026-09-28, on Dart 3.13.2 and macOS. The final state gave: core 44 tests passed, fixtures 20 tests passed, e2e 11 tests passed in about 33 s, and `dart analyze` reported no issues in all three packages. The prototype also ran the Task 8 state alone. That run found the `@not` guard defect that Task 8 already fixes.

## Global Constraints

- SDK constraint `^3.13.0` in every `pubspec.yaml`. The machine has Dart 3.13.2.
- Exact pins in `plugin/pubspec.yaml`: `analysis_server_plugin: 0.3.23`, `analyzer: 14.4.0`, `analyzer_plugin: 0.14.17`.
- `core/` never depends on `analyzer`. Only `plugin/` imports it.
- Every package uses the same `analysis_options.yaml`: `include: package:lints/recommended.yaml` with `strict-casts`, `strict-inference` and `strict-raw-types`. `dart analyze` must print `No issues found!` in each package before a commit.
- Run `dart format` on every Dart file that you write.
- New classes use Dart 3.13 primary constructors, as the code in this plan does.
- Assist IDs are `generate.<name>`. The six names are `toString`, `equality`, `copyWith`, `json`, `getter` and `primaryConstructor`.
- Generated `fromJson` is always `factory X.fromJson(Object? json)`.
- Never enable the plugin in `~/Projects/darty`. Never commit a `plugins:` block in any repo.
- Commit on `main` in `~/Projects/dart_generate`. The repo has no remote. End each commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- All paths in this plan are relative to `~/Projects/dart_generate`.

## File Structure

```
.gitignore
README.md                         setup, troubleshooting, one row per NotOffered reason
core/                             package generate_core
  pubspec.yaml
  analysis_options.yaml
  lib/generate_core.dart          exports
  lib/src/model.dart              ClassModel, FieldModel, ConstructorModel, ParamModel,
                                  TypeModel, chooseBuilder, publicName
  lib/src/outcome.dart            Owner, Reason, Outcome, Generated, NotOffered, Member
  lib/src/to_string.dart          generateToString, usedFields, interpolate
  lib/src/equality.dart           generateEquality
  lib/src/copy_with.dart          generateCopyWith
  lib/src/json.dart               generateJson
  lib/src/getter.dart             generateGetter
  lib/src/primary_constructor.dart HeaderParam, primaryHeader
  test/helpers.dart               modelOf, codeOf, reasonOf, shared types
  test/*_test.dart                one file per source file
plugin/                           package dart_generate
  pubspec.yaml
  analysis_options.yaml
  dart_test.yaml                  declares the e2e tag
  lib/main.dart                   the `plugin` entry point
  lib/src/read_class.dart         resolved element -> ClassModel
  lib/src/placement.dart          where edits go, and the format ranges
  lib/src/assist.dart             GenerateAssist base, draft builder, log
  lib/src/assists.dart            the six assists and generatorNames
  test/lsp.dart                   minimal LSP client
  test/markers.dart               marker parser and targets
  test/e2e_test.dart              end-to-end test over LSP
fixtures/                         package fixtures
  pubspec.yaml
  analysis_options.yaml           excludes input/
  input/*.dart                    classes with markers, before generation
  lib/*.dart                      the expected output
  test/*_test.dart                behavior of the generated code
```

---

### Task 1: Correct the spec and ADRs with the prototype findings

The prototype found seven places where the written design is wrong or incomplete. Fix the documents first, so that every later task has a correct source.

**Files:**
- Modify: `docs/superpowers/specs/2026-09-28-dart-generate-design.md`
- Modify: `docs/adr/0004-copywith-clears-nullable-fields-with-a-sentinel.md`
- Modify: `docs/adr/0005-fromjson-takes-object-and-reads-with-map-patterns.md`
- Modify: `docs/adr/0006-each-assist-catches-and-logs-its-own-failure.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the rules that Tasks 4 to 14 implement.

- [ ] **Step 1: Reflow the spec introduction**

Replace:

```
of VS Code and Zed. It brings the Android Studio "Generate" menu to those editors and
replaces the hzgood "Dart Data Class Generator" extension. It reads classes with the real analyzer, so primary
constructors and class modifiers work.
```

With:

```
of VS Code and Zed. It brings the Android Studio "Generate" menu to those editors and
replaces the hzgood "Dart Data Class Generator" extension. It reads classes with the
real analyzer, so primary constructors and class modifiers work.
```

- [ ] **Step 2: Name the six assist IDs**

Replace:

```
- **Assist IDs start with `generate.`.** The server turns an ID into the LSP kind
  `refactor.<id>`, so every action has the kind `refactor.generate.*`.
```

With:

```
- **Assist IDs start with `generate.`.** The server turns an ID into the LSP kind
  `refactor.<id>`, so every action has the kind `refactor.generate.*`. The six IDs
  are `generate.toString`, `generate.equality`, `generate.copyWith`, `generate.json`,
  `generate.getter` and `generate.primaryConstructor`.
```

- [ ] **Step 3: Correct three rows of the Generators table**

In the toString row, replace `` `'Payment(pence: $pence, to: $to)'` `` with:

```
`'Payment(pence: $pence, to: $to)'`. A text over 70 characters splits into adjacent string literals after a comma, because the formatter never splits a string.
```

In the `==` row, replace ``The hash is `a.hashCode` for one field,`` with:

```
The hash is `a.hashCode` for one field (`DeepCollectionEquality().hash(a)` for a collection),
```

In the Convert row, replace the "Offered when" cell:

```
Cursor on the class header. The class has no generative constructor, or one unnamed constructor with only `this.` and `super.` parameters and no body, initializer list, assert or annotation.
```

With:

```
Cursor on the header of a class without a primary constructor. The class has exactly one generative constructor. It is unnamed, has only `this.` and `super.` parameters, and has no body, initializer list, assert or annotation. A moved field has no initializer and is not `late`. A class without a generative constructor has nothing to move, so the action is not offered.
```

- [ ] **Step 4: Correct the JSON rules table**

Replace each of these five rows. The rows are not next to each other.

Row 1. Replace:

```
| `Object?` `dynamic` | as is | `final Object? x` in the pattern |
```

With:

```
| `Object` `Object?` `dynamic` | as is | `final Object x` in the pattern. `Object?` and `dynamic` are nullable, so they are read after the match as `map['k']`. |
```

Row 2. Replace:

```
| `DateTime` | `.toIso8601String()` | `DateTime.parse` |
```

With:

```
| `DateTime` | `.toIso8601String()` | `final String x`, then `DateTime.tryParse(x) ?? (throw FormatException(...))` |
```

Row 3. Replace:

```
| other type | `.toJson()` | `X.fromJson(value)` |
```

With:

```
| other type | `.toJson()` | `final Object x` in the pattern, then `X.fromJson(x)` |
```

Row 4. Replace:

```
| `List<E>`, `Set<E>` | `[for (final e in x) conv(e)]`, or as is for primitives | `final List<Object?> x`, then a list or set with the element rule |
```

With:

```
| `List<E>`, `Set<E>` | `[for (final e in x) conv(e)]`. A list of primitives goes as is, and a set of primitives as `x.toList()`. A nullable collection uses `x?.map((e) => conv(e)).toList()`. | `final List<Object?> x`, then a list or set with the element rule |
```

Row 5. Replace:

```
| `Map<String, V>` | `{for (final MapEntry(:key, :value) in x.entries) key: conv(value)}` | `final Map<String, Object?> x`, then the same shape with the value rule |
```

With:

```
| `Map<String, V>` | `{for (final MapEntry(:key, :value) in x.entries) key: conv(value)}`, or as is for primitive values. A nullable map uses `x?.map((key, value) => MapEntry(key, conv(value)))`. | `final Map<String, Object?> x`, then the same shape with the value rule |
```

After the bullet that starts with `- **Required keys and the map binding.**`, add:

```
- **Local names.** A required key binds a local with the same name. The keys `json`
  and `map` bind `jsonValue` and `mapValue`, because the parameter and the map
  binding use those names.
- **Why `tryParse`.** `DateTime.parse` throws a `FormatException` that names no key.
```

- [ ] **Step 5: Replace the Formatting and imports section**

Replace the text from ``The adapter calls `DartFileEditBuilder.format` after the insertion.`` down to the line before ``Imports go through `importLibrary`.`` with:

```
The adapter calls `DartFileEditBuilder.format` after each edit. Its range is in the
coordinates of the original file, and it must start and end on a token that is
already in the file.

- **An insertion goes right after an existing token.** The range runs from that token
  to the next token. The new line and the indent on both sides are then inside the
  range.
- **A range that starts in whitespace loses that whitespace.** The formatted text of
  a range starts and ends at a token. In the prototype, a range that was only the
  closing brace put the new member at column 0 with no blank line before it.
- **A replaced member uses its own range.** The range runs from its first annotation
  to its end, so its doc comment stays.
- **A wrong range fails silently.** A range in edited-text coordinates ran past the
  end of the original file. `compute` threw, and the assist disappeared with no error.
```

- [ ] **Step 6: Add the draft builder to Errors**

After the bullet that starts with `- **Each assist catches its own failure (ADR 0006).**`, add:

```
- **No partial edit.** The server reads the builder after `compute` returns, so a
  caught error after half an edit still shows a broken action. Each assist builds
  its edit in a draft `ChangeBuilder` and copies the edits to the server's builder
  only at the end. In the prototype, a planted throw in the JSON assist removed only
  the JSON action. The other actions stayed, and the log recorded the error.
```

- [ ] **Step 7: Correct the Testing section**

Replace:

```
     `// @generate toString, equality, copyWith, json`,
     `// @generate getter at _count`, `// @generate toString select left..right` and
     `// @not copyWith`.
```

With:

```
     `// @generate toString, equality, copyWith, json`,
     `// @generate getter at _count`, `// @generate toString select left..right` and
     `// @not copyWith noBuilder`. A `@not` marker names the reason that it covers.
   - **Update mode.** `DART_GENERATE_UPDATE=1` writes the output to `fixtures/lib/`
     instead of comparing. Read the diff before you commit it.
```

Replace:

```
   - **Before you trust a green run.** Make the test fail three ways: change one
     expected file, remove the `plugins:` line, and register an action that no marker
     expects. Each change must turn the test red.
```

With:

```
   - **Before you trust a green run.** Make the test fail four ways: change one
     expected file, remove the `plugins:` line, add a generator name that no marker
     uses, and make one assist throw. Each change must turn the test red.
```

- [ ] **Step 8: Add two known limits**

At the end of the Known limits list, add:

```
- An `Object?` or `dynamic` field that holds a list or a map compares by identity in
  `==`.
- A type from a prefixed import loses its prefix in generated code. The generated
  line then does not compile.
```

- [ ] **Step 9: Correct the Evidence table**

Replace:

```
| The `format` range uses original-file coordinates | A range past the original end made the assist disappear. The closing-brace range formatted only the new member. |
```

With:

```
| The `format` range uses original-file coordinates and starts on a token | A range past the original end made the assist disappear. A range of only the closing brace dropped the line break before the new member. |
| The generated fixtures are clean | `dart analyze` on `fixtures/` reported no issues, and `dart format` changed 0 of 9 files |
| A throwing assist leaves no partial edit | A planted throw removed only the JSON action, and the log test failed |
| The end-to-end test fails without the plugin | Without the `plugins:` block, it failed after 120 s with `no refactor.generate.toString` |
```

- [ ] **Step 10: Add the cast rule to ADR 0004**

At the end of `docs/adr/0004-copywith-clears-nullable-fields-with-a-sentinel.md`, add:

```

**An `Object?` or `dynamic` parameter gets no cast.** `raw as Object?` is the warning
`unnecessary_cast`. The sentinel still applies, so `copyWith(raw: null)` clears it.
```

- [ ] **Step 11: Add two consequences to ADR 0005**

At the end of `docs/adr/0005-fromjson-takes-object-and-reads-with-map-patterns.md`, add:

```
- **`DateTime` reads through `tryParse`.** `DateTime.parse('x')` throws a
  `FormatException` that names no key. `tryParse` returns `null`, and the rule throws
  its own `FormatException` with the key.
- **`Object?` and `dynamic` are read after the match.** They are nullable, so they
  follow the rule for nullable keys: `map['raw']`, with no check.
```

- [ ] **Step 12: Add the draft builder to ADR 0006**

At the end of `docs/adr/0006-each-assist-catches-and-logs-its-own-failure.md`, add:

```

**The edit is built in a draft.** `AssistProcessor` reads the builder after
`compute` returns. A catch after half an edit therefore still shows a broken action.
Each assist builds into a draft `ChangeBuilder` and copies the edits only on success.
In the prototype, a planted throw in the JSON assist removed only that action.
```

- [ ] **Step 13: Commit**

```bash
git add docs/superpowers/specs/2026-09-28-dart-generate-design.md docs/adr/0004-copywith-clears-nullable-fields-with-a-sentinel.md docs/adr/0005-fromjson-takes-object-and-reads-with-map-patterns.md docs/adr/0006-each-assist-catches-and-logs-its-own-failure.md
git commit -m "Correct the spec and ADRs with the prototype findings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Core package and the builder rule

**Files:**
- Create: `.gitignore`
- Create: `core/pubspec.yaml`, `core/analysis_options.yaml`
- Create: `core/lib/generate_core.dart`, `core/lib/src/model.dart`
- Create: `core/test/helpers.dart`, `core/test/model_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `ClassModel(String type, List<FieldModel> fields, ConstructorModel? builder)` with `String get name`.
  - `FieldModel(String name, TypeModel type, {bool isFinal = true, bool isLate = false, bool hasInitializer = false})`.
  - `ConstructorModel(String call, List<ParamModel> params, {bool isPublic = true, bool isCallable = true})`.
  - `ParamModel(String name, TypeModel type, {bool isNamed = false, bool isRequired = true, String? defaultValue, bool fitsField = true})`.
  - sealed `TypeModel(String code, {bool isNullable = false})` with `String get base`, and the subclasses `PrimitiveType`, `DoubleType`, `PassthroughType`, `DateTimeType`, `EnumType`, `ListType(code, element)`, `SetType(code, element)`, `MapType(code, key, value)`, `TypeParameterModel`, `OtherType`.
  - `ConstructorModel? chooseBuilder(List<FieldModel>, List<ConstructorModel>)`.
  - `String publicName(String)`.
  - Test helpers: `intType`, `stringType`, `noteType`, `modelOf(String type, List<FieldModel> fields, {bool named = false})`.

- [ ] **Step 1: Create the package files**

`.gitignore`:

```
.dart_tool/
```

`core/pubspec.yaml`:

```yaml
name: generate_core
description: Class model, rules and code generators for dart_generate.
publish_to: none

environment:
  sdk: ^3.13.0

dev_dependencies:
  lints: ^6.1.0
  test: ^1.31.0
```

`core/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
```

`core/lib/generate_core.dart`:

```dart
/// Class model, rules and code generators for dart_generate.
///
/// No analyzer dependency: the plugin builds the model, and these functions
/// return source text.
library;

export 'src/model.dart';
```

Run: `cd core && dart pub get`
Expected: `Changed ... dependencies!`

- [ ] **Step 2: Write the failing tests**

`core/test/helpers.dart`:

```dart
import 'package:generate_core/generate_core.dart';

final intType = PrimitiveType('int');
final stringType = PrimitiveType('String');
final noteType = PrimitiveType('String?', isNullable: true);

/// A class whose builder is the unnamed constructor, taking every field in
/// order.
ClassModel modelOf(
  String type,
  List<FieldModel> fields, {
  bool named = false,
}) => ClassModel(
  type,
  fields,
  ConstructorModel(type.split('<').first, [
    for (final f in fields) ParamModel(f.name, f.type, isNamed: named),
  ]),
);
```

`core/test/model_test.dart`:

```dart
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final pence = FieldModel('pence', intType);

  test('a public validating factory wins over the private primary', () {
    final builder = chooseBuilder(
      [pence],
      [
        ConstructorModel('Money._', [
          ParamModel('pence', intType),
        ], isPublic: false),
        ConstructorModel('Money.fromPence', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder?.call, 'Money.fromPence');
  });

  test('the unnamed constructor goes before named ones', () {
    final builder = chooseBuilder(
      [pence],
      [
        ConstructorModel('Money.of', [ParamModel('pence', intType)]),
        ConstructorModel('Money', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder?.call, 'Money');
  });

  test('a factory with raw parameters is skipped for a named one', () {
    final category = FieldModel('category', stringType);
    final builder = chooseBuilder(
      [category, pence],
      [
        ConstructorModel('Limit', [
          ParamModel('raw', stringType, fitsField: false),
          ParamModel('pence', intType),
        ]),
        ConstructorModel('Limit.of', [
          ParamModel('category', stringType),
          ParamModel('pence', intType),
        ]),
      ],
    );
    expect(builder?.call, 'Limit.of');
  });

  test('a generative constructor of an abstract class is skipped', () {
    final builder = chooseBuilder(
      [pence],
      [
        ConstructorModel('Entry', [
          ParamModel('pence', intType),
        ], isCallable: false),
      ],
    );
    expect(builder, isNull);
  });

  test('state outside the constructor means no builder', () {
    final recorded = FieldModel(
      '_recorded',
      ListType('List<int>', intType),
      hasInitializer: true,
    );
    final builder = chooseBuilder(
      [pence, recorded],
      [
        ConstructorModel('Store', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder, isNull);
  });

  test('a late field with an initializer is not needed', () {
    final label = FieldModel(
      'label',
      stringType,
      isLate: true,
      hasInitializer: true,
    );
    final builder = chooseBuilder(
      [pence, label],
      [
        ConstructorModel('Tagged', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder?.call, 'Tagged');
  });

  test('a late field without an initializer is needed', () {
    final label = FieldModel('label', stringType, isLate: true);
    final builder = chooseBuilder(
      [pence, label],
      [
        ConstructorModel('Tagged', [ParamModel('pence', intType)]),
      ],
    );
    expect(builder, isNull);
  });

  test('publicName drops one leading underscore', () {
    expect(publicName('_count'), 'count');
    expect(publicName('count'), 'count');
  });

  test('name drops type arguments', () {
    expect(ClassModel('Range<T>', [], null).name, 'Range');
  });
}
```

- [ ] **Step 3: Run the tests and see them fail**

Run: `cd core && dart test`
Expected: FAIL. The files do not load, because `src/model.dart` does not exist.

- [ ] **Step 4: Write the model**

`core/lib/src/model.dart`:

```dart
/// A class as the generators see it.
///
/// The plugin builds it from resolved elements. Tests build it by hand.
final class ClassModel(
  /// The type as written inside the class, for example `Range<T>`.
  final String type,

  /// Non-static fields: the class's own, plus inherited fields that the primary
  /// constructor takes through `super.` parameters.
  final List<FieldModel> fields,

  /// The constructor that copyWith and fromJson call, or `null` if none
  /// qualifies. See [chooseBuilder].
  final ConstructorModel? builder,
) {
  /// The class name without type arguments, for example `Range`.
  String get name => type.split('<').first;
}

final class FieldModel(
  final String name,
  final TypeModel type, {
  final bool isFinal = true,
  final bool isLate = false,
  final bool hasInitializer = false,
});

final class ConstructorModel(
  /// The text that calls it: `Expense`, `Money.fromPence` or `Money._`.
  final String call,
  final List<ParamModel> params, {
  final bool isPublic = true,

  /// `false` for a generative constructor of an abstract class.
  final bool isCallable = true,
});

final class ParamModel(
  /// The parameter name: `pence` for `super.pence`, `_count` for `this._count`.
  final String name,
  final TypeModel type, {
  final bool isNamed = false,
  final bool isRequired = true,
  final String? defaultValue,

  /// Whether a field has this name and its type is assignable to [type].
  final bool fitsField = true,
});

/// A field or parameter type, sorted by what the JSON rules do with it.
sealed class TypeModel(
  /// The type as written, with `?` when it is nullable: `List<Money>?`.
  final String code, {

  /// Whether the type can hold `null`. This is `true` for `String?`,
  /// `dynamic` and a type parameter with a nullable bound.
  final bool isNullable = false,
}) {
  /// [code] without a trailing `?`.
  String get base =>
      code.endsWith('?') ? code.substring(0, code.length - 1) : code;
}

/// `int`, `String`, `bool` and `num`: JSON carries them as they are.
final class PrimitiveType(super.code, {super.isNullable}) extends TypeModel;

/// JSON can write `1` for a `double`, so fromJson reads a `num`.
final class DoubleType(super.code, {super.isNullable}) extends TypeModel;

/// `Object`, `Object?` and `dynamic`: any JSON value fits.
final class PassthroughType(super.code, {super.isNullable}) extends TypeModel;

final class DateTimeType(super.code, {super.isNullable}) extends TypeModel;

final class EnumType(super.code, {super.isNullable}) extends TypeModel;

final class ListType(super.code, final TypeModel element, {super.isNullable})
    extends TypeModel;

final class SetType(super.code, final TypeModel element, {super.isNullable})
    extends TypeModel;

final class MapType(
  super.code,
  final TypeModel key,
  final TypeModel value, {
  super.isNullable,
}) extends TypeModel;

final class TypeParameterModel(super.code, {super.isNullable})
    extends TypeModel;

/// Any other type. JSON calls its `toJson()` and `fromJson`.
final class OtherType(super.code, {super.isNullable}) extends TypeModel;

/// Picks the builder: the first constructor that is public, can be called,
/// has only parameters that fit a field, and covers every field except `late`
/// fields with an initializer. The unnamed constructor goes first, then named
/// constructors in declaration order.
ConstructorModel? chooseBuilder(
  List<FieldModel> fields,
  List<ConstructorModel> constructors,
) {
  final needed = [
    for (final f in fields)
      if (!(f.isLate && f.hasInitializer)) f.name,
  ];
  final ordered = [
    ...constructors.where((c) => !c.call.contains('.')),
    ...constructors.where((c) => c.call.contains('.')),
  ];
  for (final c in ordered) {
    if (!c.isPublic || !c.isCallable) continue;
    if (!c.params.every((p) => p.fitsField)) continue;
    final names = {for (final p in c.params) p.name};
    if (needed.every(names.contains)) return c;
  }
  return null;
}

/// The name a caller uses: `count` for the private `_count`.
String publicName(String name) =>
    name.startsWith('_') ? name.substring(1) : name;
```

- [ ] **Step 5: Run the tests and see them pass**

Run: `cd core && dart test && dart analyze`
Expected: `+9: All tests passed!` and `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add .gitignore core/pubspec.yaml core/pubspec.lock core/analysis_options.yaml core/lib core/test
git commit -m "Add the core model and the builder rule

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Reasons, outcomes and the README

**Files:**
- Create: `core/lib/src/outcome.dart`, `core/test/outcome_test.dart`
- Create: `README.md`
- Modify: `core/lib/generate_core.dart`, `core/test/helpers.dart`

**Interfaces:**
- Consumes: Task 2.
- Produces:
  - `enum Owner { core, adapter }`.
  - `enum Reason` with `final Owner owner` and ten values.
  - sealed `Outcome`.
  - `Generated(List<Member> members, {List<String> imports = const []})`.
  - `NotOffered(Reason reason)`.
  - `Member(String name, String code)`.
  - Test helpers: `String codeOf(Outcome)`, `Reason? reasonOf(Outcome)`.

- [ ] **Step 1: Write the failing test**

`core/test/outcome_test.dart`:

```dart
import 'dart:io';

import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

void main() {
  test('every reason has a row in the README', () {
    final readme = File('../README.md').readAsStringSync();
    for (final reason in Reason.values) {
      expect(readme, contains('| `${reason.name}` |'), reason: reason.name);
    }
  });

  test('the core owns six reasons and the adapter four', () {
    final byOwner = {
      for (final owner in Owner.values)
        owner: Reason.values.where((r) => r.owner == owner).length,
    };
    expect(byOwner, {Owner.core: 6, Owner.adapter: 4});
  });
}
```

Run: `cd core && dart test test/outcome_test.dart`
Expected: FAIL. The file does not load: `Reason` and `Owner` are not defined.

- [ ] **Step 2: Write the outcomes**

`core/lib/src/outcome.dart`:

```dart
/// Who decides a [Reason]: the core from the model, or the plugin's adapter
/// from the syntax tree.
enum Owner { core, adapter }

/// Why an action is not offered. The README has one row per value.
enum Reason {
  noFields(Owner.core),
  noBuilder(Owner.core),
  mutableClass(Owner.core),
  typeParameterField(Owner.core),
  nestedCollection(Owner.core),
  nonStringMapKey(Owner.core),
  customToString(Owner.adapter),
  notConvertible(Owner.adapter),
  publicNameTaken(Owner.adapter),
  notAClass(Owner.adapter);

  const Reason(this.owner);

  final Owner owner;
}

/// What a generator returns.
sealed class Outcome {}

final class Generated(
  final List<Member> members, {

  /// Library URIs that the members need, such as `package:collection`.
  final List<String> imports = const [],
}) implements Outcome;

final class NotOffered(final Reason reason) implements Outcome;

/// One generated class member.
final class Member(
  /// The member name, used to find an existing member: `toString`, `==`,
  /// `hashCode`, `_unset`, `copyWith`, `toJson`, `fromJson` or a getter name.
  final String name,

  /// Unformatted Dart source. The plugin formats it after insertion.
  final String code,
);
```

In `core/lib/generate_core.dart`, add after `export 'src/model.dart';`:

```dart
export 'src/outcome.dart';
```

Run: `cd core && dart test test/outcome_test.dart`
Expected: FAIL in `every reason has a row in the README`: `../README.md` does not exist.

- [ ] **Step 3: Write the README**

`README.md`:

~~~markdown
# dart_generate

Generate actions for Dart classes in VS Code and Zed: toString, `==` and hashCode,
copyWith, toJson and fromJson, a getter for a private field, and "Convert to primary
constructor". It is an analyzer plugin, so it reads classes with the real analyzer.
Primary constructors and class modifiers work.

The design is in `docs/superpowers/specs/2026-09-28-dart-generate-design.md`. The
decisions are in `docs/adr/`.

## Setup

1. Add these lines to `analysis_options.yaml` in the project. Do not commit them.

   ```yaml
   plugins:
     dart_generate:
       path: /Users/islom/Projects/dart_generate/plugin
   ```

2. Run `dart analyze` in the project. The first run compiles the plugin, which took
   16 s in a test.
3. Restart the Dart analysis server in the editor.

A committed `path:` line makes `dart analyze` exit with code 4 on any machine without
that folder, so CI turns red.

In VS Code, this key shows only the generate actions. Add it to `keybindings.json`:

```json
{
  "key": "cmd+n",
  "command": "editor.action.codeAction",
  "args": { "kind": "refactor.generate", "apply": "never" },
  "when": "editorTextFocus && editorLangId == dart"
}
```

In a Dart editor, this key replaces "New Untitled Text File".

Zed shows the actions in its code action menu (Cmd+.). It has no filter by kind.

## Troubleshooting

1. If no action appears, run `dart analyze` in the project.
2. Look for `An error occurred while executing an analyzer plugin` in the output.
3. If an action fails, read the log. Its path is the value of `DART_GENERATE_LOG`, or
   `~/.dartServer/dart_generate.log`.

A compile error in the plugin gives exit code 0. A missing plugin path gives exit
code 4.

## Why an action is missing

Each row is one `Reason` in `core/lib/src/outcome.dart`.

| Reason | Actions | Meaning |
|---|---|---|
| `noFields` | toString, `==`, copyWith, JSON | The class has no field that the action can use. A `late` field does not count for toString and `==`. |
| `noBuilder` | copyWith, JSON | No constructor meets the four builder conditions. The builder is public. It can be called, so it is not a generative constructor of an abstract class. Each parameter names a field with an assignable type. The parameters cover every field except `late` fields with an initializer. |
| `mutableClass` | `==` | A field is not `final`. |
| `typeParameterField` | JSON | A builder parameter has a type parameter type, such as `T` or `List<T>`. |
| `nestedCollection` | JSON | A collection holds a collection, such as `List<List<int>>`. |
| `nonStringMapKey` | JSON | A map key is not `String`. |
| `customToString` | toString | The class has a toString whose body does not start with `'ClassName(`. It is hand-written text, so it stays. |
| `notConvertible` | Convert to primary constructor | The class already has a primary constructor, or it does not have exactly one generative constructor. Or that constructor has a name, a body, an initializer list or an annotation, or a parameter that is not `this.` or `super.`. Or a moved field is `late` or has an initializer. |
| `publicNameTaken` | getter | The class already has a getter or a method with the public name. |
| `notAClass` | all | The cursor is in an enum, a mixin or an extension type. |
~~~

- [ ] **Step 4: Add the outcome helpers for later tests**

Replace `core/test/helpers.dart` with:

```dart
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

final intType = PrimitiveType('int');
final stringType = PrimitiveType('String');
final noteType = PrimitiveType('String?', isNullable: true);

/// A class whose builder is the unnamed constructor, taking every field in
/// order.
ClassModel modelOf(
  String type,
  List<FieldModel> fields, {
  bool named = false,
}) => ClassModel(
  type,
  fields,
  ConstructorModel(type.split('<').first, [
    for (final f in fields) ParamModel(f.name, f.type, isNamed: named),
  ]),
);

/// The code of every generated member, joined. Fails when not offered.
String codeOf(Outcome outcome) => switch (outcome) {
  Generated(:final members) => members.map((m) => m.code).join('\n'),
  NotOffered(:final reason) => fail('not offered: $reason'),
};

/// The reason, or `null` when the outcome is generated code.
Reason? reasonOf(Outcome outcome) => switch (outcome) {
  NotOffered(:final reason) => reason,
  Generated() => null,
};
```

- [ ] **Step 5: Run the tests and see them pass**

Run: `cd core && dart test && dart analyze`
Expected: `+11: All tests passed!` and `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add README.md core/lib core/test
git commit -m "Add the NotOffered reasons, generator outcomes and the README

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: toString and equality generators

**Files:**
- Create: `core/lib/src/to_string.dart`, `core/lib/src/equality.dart`
- Create: `core/test/to_string_test.dart`, `core/test/equality_test.dart`
- Modify: `core/lib/generate_core.dart`

**Interfaces:**
- Consumes: Tasks 2 and 3.
- Produces:
  - `Outcome generateToString(ClassModel model, {Set<String>? only})`.
  - `Outcome generateEquality(ClassModel model, {Set<String>? only})`.
  - `List<FieldModel> usedFields(ClassModel, Set<String>?)`.
  - `String interpolate(String name)`.
  - Member names: `toString`, `==` and `hashCode`.

- [ ] **Step 1: Write the failing tests**

`core/test/to_string_test.dart`:

```dart
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('lists every field that is not late', () {
    final model = modelOf('Payment', [
      FieldModel('pence', intType),
      FieldModel('to', stringType),
      FieldModel('label', stringType, isLate: true, hasInitializer: true),
    ]);
    expect(
      codeOf(generateToString(model)),
      "@override\nString toString() => 'Payment(pence: \$pence, to: \$to)';",
    );
  });

  test('keeps only the selected fields', () {
    final model = modelOf('Pair', [
      FieldModel('left', intType),
      FieldModel('right', intType),
    ]);
    expect(
      codeOf(generateToString(model, only: {'right'})),
      contains(r"'Pair(right: $right)'"),
    );
  });

  test('braces a name with a dollar sign', () {
    final model = modelOf('Odd', [FieldModel(r'a$b', intType)]);
    expect(codeOf(generateToString(model)), contains(r"'Odd(a$b: ${a$b})'"));
  });

  test('splits a long text into adjacent literals after a comma', () {
    final model = modelOf('Expense', [
      for (final name in ['amount', 'kind', 'day', 'rate', 'note', 'tip'])
        FieldModel(name, stringType),
      FieldModel('acknowledged', stringType),
    ]);
    expect(
      codeOf(generateToString(model)),
      "@override\nString toString() => "
      "'Expense(amount: \$amount, kind: \$kind, day: \$day, rate: \$rate, '\n"
      "'note: \$note, tip: \$tip, acknowledged: \$acknowledged)';",
    );
  });

  test('noFields', () {
    expect(
      reasonOf(generateToString(ClassModel('Empty', [], null))),
      Reason.noFields,
    );
  });
}
```

`core/test/equality_test.dart`:

```dart
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('one field hashes with hashCode', () {
    final model = modelOf('Money', [FieldModel('pence', intType)]);
    final code = codeOf(generateEquality(model));
    expect(code, contains('other is Money && other.pence == pence'));
    expect(code, contains('int get hashCode => pence.hashCode;'));
  });

  test('the type check keeps type arguments', () {
    final model = modelOf('Range<T>', [
      FieldModel('low', TypeParameterModel('T')),
    ]);
    expect(codeOf(generateEquality(model)), contains('other is Range<T> &&'));
  });

  test('a collection uses DeepCollectionEquality and adds the import', () {
    final model = modelOf('Tagged', [
      FieldModel('id', stringType),
      FieldModel('tags', ListType('List<String>', stringType)),
    ]);
    final outcome = generateEquality(model) as Generated;
    expect(outcome.imports, ['package:collection/collection.dart']);
    final code = codeOf(outcome);
    expect(
      code,
      contains('const DeepCollectionEquality().equals(other.tags, tags)'),
    );
    expect(
      code,
      contains('Object.hash(id, const DeepCollectionEquality().hash(tags),)'),
    );
  });

  test('more than 20 fields use Object.hashAll', () {
    final model = modelOf('Wide', [
      for (var i = 0; i < 21; i++) FieldModel('f$i', intType),
    ]);
    expect(codeOf(generateEquality(model)), contains('Object.hashAll(['));
  });

  test('mutableClass', () {
    final counter = modelOf('Counter', [
      FieldModel('count', intType, isFinal: false),
    ]);
    expect(reasonOf(generateEquality(counter)), Reason.mutableClass);
  });

  test('noFields', () {
    expect(
      reasonOf(generateEquality(ClassModel('Empty', [], null))),
      Reason.noFields,
    );
  });
}
```

- [ ] **Step 2: Run the tests and see them fail**

Run: `cd core && dart test test/to_string_test.dart test/equality_test.dart`
Expected: FAIL. The files do not load: `generateToString` and `generateEquality` are not defined.

- [ ] **Step 3: Write the generators**

`core/lib/src/to_string.dart`:

```dart
import 'model.dart';
import 'outcome.dart';

/// `toString()` over every field that is not `late`.
///
/// If [only] is given, it keeps just those field names: the fields that the
/// editor selection covers.
Outcome generateToString(ClassModel model, {Set<String>? only}) {
  final fields = usedFields(model, only);
  if (fields.isEmpty) return NotOffered(Reason.noFields);
  final parts = [for (final f in fields) '${f.name}: ${interpolate(f.name)}'];
  final text = '${model.name}(${parts.join(', ')})';
  return Generated([
    Member('toString', '@override\nString toString() => ${_literal(text)};'),
  ]);
}

/// The longest string literal content on one line. With the formatter's
/// indent of 6 and the quotes, a line stays within 80 columns.
const _width = 70;

/// [text] as one string literal, or as adjacent literals split after a
/// `, ` when it is longer than [_width]. The formatter never splits a string.
String _literal(String text) {
  if (text.length <= _width) return "'$text'";
  final pieces = text.split(', ');
  final lines = <String>[];
  var line = '';
  for (final (i, piece) in pieces.indexed) {
    final next = i == pieces.length - 1 ? piece : '$piece, ';
    if (line.isNotEmpty && line.length + next.length > _width) {
      lines.add(line);
      line = '';
    }
    line += next;
  }
  lines.add(line);
  return lines.map((l) => "'$l'").join('\n');
}

/// The fields that toString and `==` use.
List<FieldModel> usedFields(ClassModel model, Set<String>? only) => [
  for (final f in model.fields)
    if (!f.isLate && (only == null || only.contains(f.name))) f,
];

/// `$name`, or `${name}` when the name has a `$` that would end the
/// interpolation early.
String interpolate(String name) =>
    name.contains(r'$') ? '\${$name}' : '\$$name';
```

`core/lib/src/equality.dart`:

```dart
import 'model.dart';
import 'outcome.dart';
import 'to_string.dart';

const _collection = 'package:collection/collection.dart';

/// `operator ==` and `hashCode`. Offered only when every field is `final`.
Outcome generateEquality(ClassModel model, {Set<String>? only}) {
  if (model.fields.any((f) => !f.isFinal)) {
    return NotOffered(Reason.mutableClass);
  }
  final fields = usedFields(model, only);
  if (fields.isEmpty) return NotOffered(Reason.noFields);

  final checks = [
    for (final f in fields)
      _isCollection(f.type)
          ? 'const DeepCollectionEquality().equals(other.${f.name}, ${f.name})'
          : 'other.${f.name} == ${f.name}',
  ];
  final hashes = [
    for (final f in fields)
      _isCollection(f.type)
          ? 'const DeepCollectionEquality().hash(${f.name})'
          : f.name,
  ];
  final hash = switch (hashes.length) {
    1 when !_isCollection(fields.single.type) => '${hashes.single}.hashCode',
    1 => hashes.single,
    <= 20 => 'Object.hash(${hashes.join(', ')},)',
    _ => 'Object.hashAll([${hashes.join(', ')},])',
  };
  return Generated(
    [
      Member(
        '==',
        '@override\nbool operator ==(Object other) => '
            'other is ${model.type} && ${checks.join(' && ')};',
      ),
      Member('hashCode', '@override\nint get hashCode => $hash;'),
    ],
    imports: [if (fields.any((f) => _isCollection(f.type))) _collection],
  );
}

bool _isCollection(TypeModel type) =>
    type is ListType || type is SetType || type is MapType;
```

In `core/lib/generate_core.dart`, add these exports in sorted order:

```dart
export 'src/equality.dart';
export 'src/to_string.dart';
```

- [ ] **Step 4: Run the tests and see them pass**

Run: `cd core && dart test && dart analyze`
Expected: `+22: All tests passed!` and `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add core/lib core/test
git commit -m "Generate toString, == and hashCode text in the core

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: copyWith generator

**Files:**
- Create: `core/lib/src/copy_with.dart`, `core/test/copy_with_test.dart`
- Modify: `core/lib/generate_core.dart`

**Interfaces:**
- Consumes: Tasks 2 and 3.
- Produces: `Outcome generateCopyWith(ClassModel model)`. If a parameter is nullable, the members are `_unset` and `copyWith`. Otherwise the only member is `copyWith`.

- [ ] **Step 1: Write the failing test**

`core/test/copy_with_test.dart`:

```dart
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('a nullable field uses the sentinel and a cast', () {
    final model = modelOf('Expense', [
      FieldModel('pence', intType),
      FieldModel('note', noteType),
    ]);
    final outcome = generateCopyWith(model) as Generated;
    expect(outcome.members.map((m) => m.name), ['_unset', 'copyWith']);
    final code = codeOf(outcome);
    expect(code, contains('int? pence'));
    expect(code, contains('Object? note = _unset'));
    expect(code, contains('pence ?? this.pence'));
    expect(
      code,
      contains('identical(note, _unset) ? this.note : note as String?'),
    );
  });

  test('a type parameter with a nullable bound uses the sentinel', () {
    final model = modelOf('Box<T>', [
      FieldModel('value', TypeParameterModel('T', isNullable: true)),
    ]);
    final code = codeOf(generateCopyWith(model));
    expect(code, contains('Box<T> copyWith({Object? value = _unset,})'));
    expect(code, contains('value as T'));
  });

  test('Object? needs no cast', () {
    final model = modelOf('Raw', [
      FieldModel('raw', PassthroughType('Object?', isNullable: true)),
    ]);
    expect(
      codeOf(generateCopyWith(model)),
      contains('identical(raw, _unset) ? this.raw : raw,'),
    );
  });

  test('a private parameter gets a public name', () {
    final model = modelOf('Box', [FieldModel('_count', intType)]);
    final code = codeOf(generateCopyWith(model));
    expect(code, contains('int? count'));
    expect(code, contains('count ?? _count'));
  });

  test('named parameters stay named, and the builder is called', () {
    final model = ClassModel(
      'Money',
      [FieldModel('pence', intType)],
      ConstructorModel('Money.fromPence', [
        ParamModel('pence', intType, isNamed: true),
      ]),
    );
    expect(
      codeOf(generateCopyWith(model)),
      contains('Money.fromPence(pence: pence ?? this.pence,)'),
    );
  });

  test('noFields and noBuilder', () {
    expect(
      reasonOf(generateCopyWith(ClassModel('Empty', [], null))),
      Reason.noFields,
    );
    final store = ClassModel('Store', [FieldModel('a', intType)], null);
    expect(reasonOf(generateCopyWith(store)), Reason.noBuilder);
  });
}
```

Run: `cd core && dart test test/copy_with_test.dart`
Expected: FAIL. The file does not load: `generateCopyWith` is not defined.

- [ ] **Step 2: Write the generator**

`core/lib/src/copy_with.dart`:

```dart
import 'model.dart';
import 'outcome.dart';

/// `copyWith` that calls the builder. A nullable parameter uses the `_unset`
/// sentinel, so `copyWith(note: null)` clears the field.
Outcome generateCopyWith(ClassModel model) {
  if (model.fields.isEmpty) return NotOffered(Reason.noFields);
  final builder = model.builder;
  if (builder == null) return NotOffered(Reason.noBuilder);
  if (builder.params.isEmpty) return NotOffered(Reason.noFields);

  final params = <String>[];
  final args = <String>[];
  for (final p in builder.params) {
    final name = publicName(p.name);
    final field = name == p.name ? 'this.${p.name}' : p.name;
    final String value;
    if (p.type.isNullable) {
      params.add('Object? $name = _unset');
      final cast = p.type is PassthroughType ? '' : ' as ${p.type.code}';
      value = 'identical($name, _unset) ? $field : $name$cast';
    } else {
      params.add('${p.type.base}? $name');
      value = '$name ?? $field';
    }
    args.add(p.isNamed ? '$name: $value' : value);
  }
  return Generated([
    if (builder.params.any((p) => p.type.isNullable))
      Member('_unset', 'static const _unset = Object();'),
    Member(
      'copyWith',
      '${model.type} copyWith({${params.join(', ')},}) => '
          '${builder.call}(${args.join(', ')},);',
    ),
  ]);
}
```

In `core/lib/generate_core.dart`, add `export 'src/copy_with.dart';` as the first export.

- [ ] **Step 3: Run the tests and see them pass**

Run: `cd core && dart test && dart analyze`
Expected: `+28: All tests passed!` and `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add core/lib core/test
git commit -m "Generate copyWith text with the _unset sentinel

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: JSON generator

**Files:**
- Create: `core/lib/src/json.dart`, `core/test/json_test.dart`
- Modify: `core/lib/generate_core.dart`

**Interfaces:**
- Consumes: Tasks 2 and 3.
- Produces: `Outcome generateJson(ClassModel model)`. Members: `toJson`, then `fromJson`.

- [ ] **Step 1: Write the failing test**

`core/test/json_test.dart`:

```dart
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final money = OtherType('Money');
  final kind = EnumType('Kind');

  test('keys are public names', () {
    final code = codeOf(
      generateJson(modelOf('Box', [FieldModel('_count', intType)])),
    );
    expect(code, contains("'count': _count"));
    expect(code, contains("'count': final int count"));
  });

  test('required keys go in the map pattern', () {
    final code = codeOf(
      generateJson(
        modelOf('Expense', [
          FieldModel('pence', intType),
          FieldModel('rate', DoubleType('double')),
          FieldModel('kind', kind),
          FieldModel('day', DateTimeType('DateTime')),
          FieldModel('amount', money),
        ]),
      ),
    );
    expect(code, contains("'pence': final int pence"));
    expect(code, contains("'rate': final num rate"));
    expect(code, contains('rate.toDouble()'));
    expect(code, contains("'kind': final String kind"));
    expect(code, contains('Kind.values.asNameMap()[kind] ?? (throw'));
    expect(code, contains('DateTime.tryParse(day) ?? (throw'));
    expect(code, contains("'amount': final Object amount"));
    expect(code, contains('Money.fromJson(amount)'));
    expect(code, contains("'kind': kind.name"));
    expect(code, contains("'day': day.toIso8601String()"));
    expect(code, contains("'amount': amount.toJson()"));
    expect(code, isNot(contains('final Map<String, Object?> map')));
  });

  test('nullable keys are read after the match', () {
    final code = codeOf(
      generateJson(
        modelOf('Expense', [
          FieldModel('pence', intType),
          FieldModel('note', noteType),
          FieldModel('tip', OtherType('Money?', isNullable: true)),
          FieldModel('raw', PassthroughType('Object?', isNullable: true)),
        ]),
      ),
    );
    expect(code, contains('final Map<String, Object?> map && {'));
    expect(
      code,
      contains(
        "switch (map['note']) { null => null, final String v => v, _ => throw",
      ),
    );
    expect(
      code,
      contains(
        "switch (map['tip']) { null => null, "
        'final Object v => Money.fromJson(v), }',
      ),
    );
    expect(code, contains("map['raw'],"));
    expect(code, contains("'tip': tip?.toJson()"));
  });

  test('a default keeps an explicit null', () {
    final model = ClassModel(
      'Bag',
      [
        FieldModel('label', noteType),
        FieldModel('seen', PrimitiveType('bool')),
      ],
      ConstructorModel('Bag', [
        ParamModel(
          'label',
          noteType,
          isNamed: true,
          isRequired: false,
          defaultValue: "'none'",
        ),
        ParamModel(
          'seen',
          PrimitiveType('bool'),
          isNamed: true,
          isRequired: false,
          defaultValue: 'false',
        ),
      ]),
    );
    final code = codeOf(generateJson(model));
    expect(code, contains("label: map.containsKey('label') ? switch"));
    expect(code, contains(": 'none'"));
    expect(
      code,
      contains("seen: switch (map['seen']) { null => false, final bool v => v,"),
    );
  });

  test('collections convert each element', () {
    final code = codeOf(
      generateJson(
        modelOf('Bag', [
          FieldModel('parts', ListType('List<Money>', money)),
          FieldModel('kinds', SetType('Set<Kind>', kind)),
          FieldModel('prices', MapType('Map<String, Money>', stringType, money)),
          FieldModel('tags', ListType('List<String?>', noteType)),
          FieldModel('names', SetType('Set<String>', stringType)),
        ]),
      ),
    );
    expect(code, contains("'parts': [for (final e in parts) e.toJson()]"));
    expect(code, contains('[for (final e in parts) Money.fromJson(e)]'));
    expect(
      code,
      contains('{for (final e in kinds) (e is String ? Kind.values'),
    );
    expect(code, contains('key: Money.fromJson(value)'));
    expect(code, contains("'tags': tags,"));
    expect(code, contains('e is String? ? e : throw'));
    expect(code, contains("'names': names.toList()"));
  });

  test('errors name the key and the class', () {
    final code = codeOf(
      generateJson(modelOf('Expense', [FieldModel('kind', kind)])),
    );
    expect(
      code,
      contains('''FormatException('Invalid "kind" in Expense JSON', json)'''),
    );
    expect(code, contains("FormatException('Invalid Expense JSON', json)"));
  });

  test('a key named map or json gets its own local', () {
    final code = codeOf(
      generateJson(modelOf('Odd', [FieldModel('map', intType)])),
    );
    expect(code, contains("'map': final int mapValue"));
  });

  group('not offered', () {
    test('noFields and noBuilder', () {
      expect(
        reasonOf(generateJson(ClassModel('Empty', [], null))),
        Reason.noFields,
      );
      final store = ClassModel('Store', [FieldModel('a', intType)], null);
      expect(reasonOf(generateJson(store)), Reason.noBuilder);
    });

    test('typeParameterField', () {
      final box = modelOf('Box<T>', [
        FieldModel('value', TypeParameterModel('T', isNullable: true)),
      ]);
      expect(reasonOf(generateJson(box)), Reason.typeParameterField);
    });

    test('nestedCollection', () {
      final grid = modelOf('Grid', [
        FieldModel(
          'rows',
          ListType('List<List<int>>', ListType('List<int>', intType)),
        ),
      ]);
      expect(reasonOf(generateJson(grid)), Reason.nestedCollection);
    });

    test('nonStringMapKey', () {
      final byDay = modelOf('ByDay', [
        FieldModel('totals', MapType('Map<int, int>', intType, intType)),
      ]);
      expect(reasonOf(generateJson(byDay)), Reason.nonStringMapKey);
    });
  });
}
```

Run: `cd core && dart test test/json_test.dart`
Expected: FAIL. The file does not load: `generateJson` is not defined.

- [ ] **Step 2: Write the generator**

`core/lib/src/json.dart`:

```dart
import 'model.dart';
import 'outcome.dart';

/// `toJson()` and `factory X.fromJson(Object? json)` over the builder
/// parameters. Keys are the public parameter names.
Outcome generateJson(ClassModel model) {
  if (model.fields.isEmpty) return NotOffered(Reason.noFields);
  final builder = model.builder;
  if (builder == null) return NotOffered(Reason.noBuilder);
  if (builder.params.isEmpty) return NotOffered(Reason.noFields);
  for (final p in builder.params) {
    if (_unsupported(p.type) case final reason?) return NotOffered(reason);
  }
  return Generated([
    Member('toJson', _toJson(builder)),
    Member('fromJson', _Reader(model.name, builder).fromJson()),
  ]);
}

Reason? _unsupported(TypeModel type) => switch (type) {
  TypeParameterModel() => Reason.typeParameterField,
  ListType(:final element) || SetType(:final element) => _inner(element),
  MapType(:final key) when key.code != 'String' => Reason.nonStringMapKey,
  MapType(:final value) => _inner(value),
  _ => null,
};

Reason? _inner(TypeModel type) => switch (type) {
  TypeParameterModel() => Reason.typeParameterField,
  ListType() || SetType() || MapType() => Reason.nestedCollection,
  _ => null,
};

String _toJson(ConstructorModel builder) {
  final entries = [
    for (final p in builder.params)
      '${_quote(publicName(p.name))}: ${_write(p.name, p.type)}',
  ];
  return 'Map<String, Object?> toJson() => {${entries.join(', ')},};';
}

/// The JSON value of [v], an expression of [type].
String _write(String v, TypeModel type) {
  final q = type.isNullable ? '?' : '';
  return switch (type) {
    EnumType() => '$v$q.name',
    DateTimeType() => '$v$q.toIso8601String()',
    OtherType() => '$v$q.toJson()',
    ListType(:final element) || SetType(:final element) when !_asIs(element) =>
      type.isNullable
          ? '$v?.map((e) => ${_write('e', element)}).toList()'
          : '[for (final e in $v) ${_write('e', element)}]',
    SetType() => '$v$q.toList()',
    MapType(:final value) when !_asIs(value) =>
      type.isNullable
          ? '$v?.map((key, value) => MapEntry(key, ${_write('value', value)}))'
          : '{for (final MapEntry(:key, :value) in $v.entries) '
                'key: ${_write('value', value)}}',
    _ => v,
  };
}

/// Whether JSON carries values of [type] unchanged.
bool _asIs(TypeModel type) =>
    type is PrimitiveType || type is DoubleType || type is PassthroughType;

String _quote(String text) => "'${text.replaceAll(r'$', r'\$')}'";

/// Builds the fromJson text for one class.
final class _Reader(final String className, final ConstructorModel builder) {
  String fromJson() {
    final entries = <String>[];
    final args = <String>[];
    var needsMap = false;
    for (final p in builder.params) {
      final key = publicName(p.name);
      final String value;
      if (p.type.isNullable || p.defaultValue != null) {
        needsMap = true;
        value = _optional(key, p.type, p.defaultValue);
      } else {
        final local = _local(key);
        entries.add('${_quote(key)}: final ${_pattern(p.type)} $local');
        value = _convert(local, p.type, key);
      }
      args.add(p.isNamed ? '$key: $value' : value);
    }
    final head = [
      if (needsMap) 'final Map<String, Object?> map',
      if (entries.isNotEmpty) '{${entries.join(', ')},}',
    ].join(' && ');
    return 'factory $className.fromJson(Object? json) => switch (json) {'
        '$head => ${builder.call}(${args.join(', ')},),'
        "_ => throw FormatException('Invalid $className JSON', json),"
        '};';
  }

  /// A key that can be missing or `null`: read after the match.
  String _optional(String key, TypeModel type, String? defaultValue) {
    final read = 'map[${_quote(key)}]';
    final String value;
    if (type is PassthroughType) {
      value = read;
    } else {
      final pattern = _pattern(type);
      final fallback = pattern == 'Object' ? '' : ', _ => throw ${_error(key)}';
      final onNull = type.isNullable ? 'null' : defaultValue!;
      value =
          'switch ($read) { null => $onNull, '
          'final $pattern v => ${_convert('v', type, key)}$fallback, }';
    }
    if (!type.isNullable || defaultValue == null) return value;
    return 'map.containsKey(${_quote(key)}) ? $value : $defaultValue';
  }

  /// The type to match for a present, non-null value of [type].
  String _pattern(TypeModel type) => switch (type) {
    PrimitiveType() => type.base,
    DoubleType() => 'num',
    PassthroughType() || OtherType() => 'Object',
    DateTimeType() || EnumType() => 'String',
    ListType() || SetType() => 'List<Object?>',
    MapType() => 'Map<String, Object?>',
    TypeParameterModel() => throw StateError('JSON is not offered for $type'),
  };

  /// Converts [v], already matched with [_pattern], to [type].
  String _convert(String v, TypeModel type, String key) => switch (type) {
    DoubleType() => '$v.toDouble()',
    DateTimeType() => 'DateTime.tryParse($v) ?? (throw ${_error(key)})',
    EnumType() =>
      '${type.base}.values.asNameMap()[$v] ?? (throw ${_error(key)})',
    OtherType() => '${type.base}.fromJson($v)',
    ListType(:final element) =>
      '[for (final e in $v) ${_element('e', element, key)}]',
    SetType(:final element) =>
      '{for (final e in $v) ${_element('e', element, key)}}',
    MapType(:final value) =>
      '{for (final MapEntry(:key, :value) in $v.entries) '
          'key: ${_element('value', value, key)}}',
    _ => v,
  };

  /// Converts [v], an `Object?` element of a collection, to [type].
  String _element(String v, TypeModel type, String key) {
    final error = _error(key);
    final String present = switch (type) {
      PrimitiveType() => '$v is ${type.code} ? $v : throw $error',
      DoubleType() when type.isNullable =>
        '$v is num? ? $v?.toDouble() : throw $error',
      DoubleType() => '$v is num ? $v.toDouble() : throw $error',
      PassthroughType() when type.isNullable => v,
      PassthroughType() => '$v ?? (throw $error)',
      DateTimeType() =>
        '($v is String ? DateTime.tryParse($v) : null) ?? (throw $error)',
      EnumType() =>
        '($v is String ? ${type.base}.values.asNameMap()[$v] : null) '
            '?? (throw $error)',
      OtherType() => '${type.base}.fromJson($v)',
      _ => throw StateError('JSON is not offered for $type'),
    };
    final nullCheck =
        type is DateTimeType || type is EnumType || type is OtherType;
    return type.isNullable && nullCheck
        ? '$v == null ? null : $present'
        : present;
  }

  String _error(String key) =>
      "FormatException('Invalid \"${key.replaceAll(r'$', r'\$')}\" "
      "in $className JSON', json)";

  /// The local that binds a required key. `json` and `map` are taken.
  String _local(String key) =>
      key == 'json' || key == 'map' ? '${key}Value' : key;
}
```

In `core/lib/generate_core.dart`, add `export 'src/json.dart';` in sorted order.

- [ ] **Step 3: Run the tests and see them pass**

Run: `cd core && dart test && dart analyze`
Expected: `+39: All tests passed!` and `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add core/lib core/test
git commit -m "Generate toJson and fromJson text with map patterns

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Getter and primary header generators

**Files:**
- Create: `core/lib/src/getter.dart`, `core/lib/src/primary_constructor.dart`
- Create: `core/test/getter_test.dart`, `core/test/primary_constructor_test.dart`
- Modify: `core/lib/generate_core.dart`

**Interfaces:**
- Consumes: Tasks 2 and 3.
- Produces:
  - `Outcome generateGetter(FieldModel field)`, with one member named after the public name.
  - `HeaderParam(String name, {String? type, bool isFinal = true, bool isNamed = false, bool isOptionalPositional = false, bool isRequired = false, String? defaultValue, String metadata = ''})`.
  - `String primaryHeader(String name, List<HeaderParam> params, {String typeParameters = '', bool isConst = false})`.

- [ ] **Step 1: Write the failing tests**

`core/test/getter_test.dart`:

```dart
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('a public getter returns the private field', () {
    expect(
      codeOf(generateGetter(FieldModel('_count', intType))),
      'int get count => _count;',
    );
  });

  test('a nullable type keeps its question mark', () {
    expect(
      codeOf(generateGetter(FieldModel('_note', noteType))),
      'String? get note => _note;',
    );
  });
}
```

`core/test/primary_constructor_test.dart`:

```dart
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

void main() {
  test('keeps groups, defaults, var and super', () {
    final header = primaryHeader(
      'Conv',
      [
        HeaderParam('_secret', type: 'int'),
        HeaderParam('id'),
        HeaderParam('name', type: 'String', isNamed: true, isRequired: true),
        HeaderParam(
          'size',
          type: 'int',
          isFinal: false,
          isNamed: true,
          defaultValue: '0',
        ),
      ],
      typeParameters: '<T>',
      isConst: true,
    );
    expect(
      header,
      'const Conv<T>(final int _secret, super.id, '
      '{required final String name, var int size = 0})',
    );
  });

  test('optional positional parameters go in brackets', () {
    final header = primaryHeader('Span', [
      HeaderParam('start', type: 'int'),
      HeaderParam(
        'end',
        type: 'int',
        isOptionalPositional: true,
        defaultValue: '0',
      ),
    ]);
    expect(header, 'Span(final int start, [final int end = 0])');
  });

  test('a doc comment ends its own line', () {
    final header = primaryHeader('Pair', [
      HeaderParam('left', type: 'int', metadata: '/// The left side.'),
    ]);
    expect(header, 'Pair(/// The left side.\n final int left)');
  });
}
```

Run: `cd core && dart test test/getter_test.dart test/primary_constructor_test.dart`
Expected: FAIL. The files do not load: `generateGetter`, `HeaderParam` and `primaryHeader` are not defined.

- [ ] **Step 2: Write the generators**

`core/lib/src/getter.dart`:

```dart
import 'model.dart';
import 'outcome.dart';

/// A public getter for a private field: `int get count => _count;`.
///
/// The plugin checks the cursor and a name clash before it calls this.
Outcome generateGetter(FieldModel field) {
  final name = publicName(field.name);
  return Generated([
    Member(name, '${field.type.code} get $name => ${field.name};'),
  ]);
}
```

`core/lib/src/primary_constructor.dart`:

```dart
/// One parameter of a primary constructor header.
final class HeaderParam(
  final String name, {

  /// The field type as written. `null` for a `super.` parameter.
  final String? type,
  final bool isFinal = true,
  final bool isNamed = false,
  final bool isOptionalPositional = false,

  /// Whether a named parameter has `required`.
  final bool isRequired = false,
  final String? defaultValue,

  /// Doc comments and annotations, as written, that move onto the parameter.
  final String metadata = '',
});

/// The primary constructor header that replaces the class name, for example
/// `const Pair(final int left, final int right)`.
String primaryHeader(
  String name,
  List<HeaderParam> params, {
  String typeParameters = '',
  bool isConst = false,
}) {
  String write(HeaderParam p) => [
    // A doc comment runs to the end of its line.
    if (p.metadata.isNotEmpty)
      p.metadata.contains('//') ? '${p.metadata}\n' : p.metadata,
    if (p.isRequired) 'required',
    if (p.type case final type?)
      '${p.isFinal ? 'final' : 'var'} $type ${p.name}'
    else
      'super.${p.name}',
    if (p.defaultValue case final value?) '= $value',
  ].join(' ');

  final positional = [
    for (final p in params)
      if (!p.isNamed && !p.isOptionalPositional) write(p),
  ];
  final optional = [
    for (final p in params)
      if (p.isOptionalPositional) write(p),
  ];
  final named = [
    for (final p in params)
      if (p.isNamed) write(p),
  ];
  final groups = [
    ...positional,
    if (optional.isNotEmpty) '[${optional.join(', ')}]',
    if (named.isNotEmpty) '{${named.join(', ')}}',
  ];
  return '${isConst ? 'const ' : ''}$name$typeParameters(${groups.join(', ')})';
}
```

Replace the exports in `core/lib/generate_core.dart` with the full sorted list:

```dart
export 'src/copy_with.dart';
export 'src/equality.dart';
export 'src/getter.dart';
export 'src/json.dart';
export 'src/model.dart';
export 'src/outcome.dart';
export 'src/primary_constructor.dart';
export 'src/to_string.dart';
```

- [ ] **Step 3: Run the tests and see them pass**

Run: `cd core && dart test && dart analyze`
Expected: `+44: All tests passed!` and `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add core/lib core/test
git commit -m "Generate getter and primary constructor header text

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Plugin, end-to-end test and Generate toString()

This task builds the plugin skeleton, the adapter, the placement rules, the base assist, the first assist and the whole end-to-end test. They form one deliverable: toString works in a real analysis server.

**Files:**
- Create: `plugin/pubspec.yaml`, `plugin/analysis_options.yaml`, `plugin/dart_test.yaml`
- Create: `plugin/lib/main.dart`, `plugin/lib/src/read_class.dart`, `plugin/lib/src/placement.dart`, `plugin/lib/src/assist.dart`, `plugin/lib/src/assists.dart`
- Create: `plugin/test/lsp.dart`, `plugin/test/markers.dart`, `plugin/test/e2e_test.dart`
- Create: `fixtures/pubspec.yaml`, `fixtures/analysis_options.yaml`
- Create: `fixtures/input/to_string.dart`, `fixtures/lib/to_string.dart`

**Interfaces:**
- Consumes: `generate_core` from Tasks 2 to 7.
- Produces:
  - `ClassModel readClass(ClassElement, TypeSystem)`.
  - `TypeModel readType(DartType, TypeSystem)`.
  - `bool writeMembers(DartFileEditBuilder, ClassDeclaration, List<Member>)`.
  - `ClassMember? findMember(ClassDeclaration, String)`.
  - `void replaceMember(DartFileEditBuilder, ClassMember, String)`.
  - `void insertAtEnd(DartFileEditBuilder, ClassDeclaration, String)`.
  - `abstract class GenerateAssist` with `String verb`, `Future<void> generate(ChangeBuilder draft)`, `ClassTarget? classTarget()`, `Future<void> write(ChangeBuilder, ClassDeclaration, Outcome)`.
  - `final class ClassTarget(ClassDeclaration node, ClassModel model, Set<String>? only)`.
  - `void writeLog(String generator, String file, Object error, StackTrace stack)`.
  - `const generatorNames`.
  - `AssistKind _kind(String name, String message)`.
  - End-to-end test helpers: `Lsp`, `position`, `offsetOf`, `applyEdit`, `Marker`, `parseMarkers`, `target`.

- [ ] **Step 1: Create the fixtures package**

`fixtures/pubspec.yaml`:

```yaml
name: fixtures
description: Expected generator output and its behavior tests.
publish_to: none

environment:
  sdk: ^3.13.0

dependencies:
  collection: ^1.19.1

dev_dependencies:
  lints: ^6.1.0
  test: ^1.31.0
```

`fixtures/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  # The inputs are incomplete on purpose: members arrive by generation.
  exclude:
    - input/**
```

`fixtures/input/to_string.dart`:

```dart
// A stale generated toString is replaced.
// @generate toString
class const Point(final int x, final int y) {
  @override
  String toString() => 'Point(x: $x)';
}

// A hand-written toString is domain text.
// @not toString customToString
class const Label(final String text) {
  @override
  String toString() => text;
}

// Only the selected fields.
// @generate toString select left..right
class const Triple(final int left, final int right, final int extra);

// @not toString noFields
class Empty {}

// @not toString notAClass
enum Size { small, large }
```

`fixtures/lib/to_string.dart`, the expected output:

```dart
// A stale generated toString is replaced.
// @generate toString
class const Point(final int x, final int y) {
  @override
  String toString() => 'Point(x: $x, y: $y)';
}

// A hand-written toString is domain text.
// @not toString customToString
class const Label(final String text) {
  @override
  String toString() => text;
}

// Only the selected fields.
// @generate toString select left..right
class const Triple(final int left, final int right, final int extra) {
  @override
  String toString() => 'Triple(left: $left, right: $right)';
}

// @not toString noFields
class Empty {}

// @not toString notAClass
enum Size { small, large }
```

Run: `cd fixtures && dart pub get && dart analyze`
Expected: `No issues found!`

- [ ] **Step 2: Create the plugin package**

`plugin/pubspec.yaml`:

```yaml
name: dart_generate
description: Analyzer plugin that adds Generate actions to the code action menu.
publish_to: none

environment:
  sdk: ^3.13.0

# Pinned exactly: the plugin API is young, and analysis_server_plugin pins
# analyzer and analyzer_plugin itself. Move all three together.
dependencies:
  analysis_server_plugin: 0.3.23
  analyzer: 14.4.0
  analyzer_plugin: 0.14.17
  generate_core:
    path: ../core

dev_dependencies:
  lints: ^6.1.0
  test: ^1.31.0
```

`plugin/analysis_options.yaml`: the same content as `core/analysis_options.yaml`.

`plugin/dart_test.yaml`:

```yaml
tags:
  # Starts the analysis server over LSP. Takes minutes on a cold plugin cache.
  e2e:
```

Run: `cd plugin && dart pub get`
Expected: `Changed ... dependencies!`

- [ ] **Step 3: Write the end-to-end test**

`plugin/test/lsp.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A minimal LSP client over `dart language-server`: enough to open files,
/// ask for code actions and apply their edits.
final class Lsp {
  Lsp._(this._process) {
    _process.stdout.listen(_onBytes);
    _process.stderr.drain<void>();
  }

  final Process _process;
  final _pending = <int, Completer<Object?>>{};
  final _buffer = <int>[];
  var _nextId = 0;

  /// Starts the server on [root]. [log] becomes `DART_GENERATE_LOG`.
  static Future<Lsp> start(String root, {required String log}) async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['language-server', '--protocol=lsp'],
      environment: {'DART_GENERATE_LOG': log},
    );
    final lsp = Lsp._(process);
    await lsp.request('initialize', {
      'processId': pid,
      'rootUri': Uri.directory(root).toString(),
      'capabilities': {
        'textDocument': {
          'codeAction': {
            'codeActionLiteralSupport': {
              'codeActionKind': {
                'valueSet': ['', 'quickfix', 'refactor', 'source'],
              },
            },
          },
        },
      },
    });
    lsp.notify('initialized', {});
    return lsp;
  }

  Future<Object?> request(String method, Map<String, Object?> params) {
    final id = ++_nextId;
    final completer = _pending[id] = Completer<Object?>();
    _send({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params});
    return completer.future;
  }

  void notify(String method, Map<String, Object?> params) =>
      _send({'jsonrpc': '2.0', 'method': method, 'params': params});

  Future<void> stop() async {
    _process.kill();
    await _process.exitCode;
  }

  void _send(Map<String, Object?> message) {
    final body = utf8.encode(jsonEncode(message));
    _process.stdin
      ..add(ascii.encode('Content-Length: ${body.length}\r\n\r\n'))
      ..add(body);
  }

  void _onBytes(List<int> bytes) {
    _buffer.addAll(bytes);
    while (true) {
      final text = latin1.decode(_buffer);
      final headerEnd = text.indexOf('\r\n\r\n');
      if (headerEnd < 0) return;
      final length = int.parse(
        RegExp(r'Content-Length: (\d+)').firstMatch(text)!.group(1)!,
      );
      final start = headerEnd + 4;
      if (_buffer.length < start + length) return;
      final body = utf8.decode(_buffer.sublist(start, start + length));
      _buffer.removeRange(0, start + length);
      _onMessage(jsonDecode(body) as Map<String, Object?>);
    }
  }

  void _onMessage(Map<String, Object?> message) {
    final id = message['id'];
    if (message.containsKey('method')) {
      // A request from the server, such as client/registerCapability.
      if (id != null) _send({'jsonrpc': '2.0', 'id': id, 'result': null});
      return;
    }
    final completer = _pending.remove(id);
    if (message['error'] case final error?) {
      completer?.completeError(StateError('LSP error: $error'));
    } else {
      completer?.complete(message['result']);
    }
  }
}

/// An LSP position for [offset] in [text]. The fixtures are ASCII, so UTF-16
/// columns equal byte columns.
Map<String, int> position(String text, int offset) {
  final before = text.substring(0, offset);
  final line = '\n'.allMatches(before).length;
  return {'line': line, 'character': offset - (before.lastIndexOf('\n') + 1)};
}

int offsetOf(String text, Map<String, Object?> position) {
  final lines = text.split('\n');
  final line = position['line']! as int;
  var offset = 0;
  for (var i = 0; i < line; i++) {
    offset += lines[i].length + 1;
  }
  return offset + (position['character']! as int);
}

/// Applies the text edits of a code action to [text].
String applyEdit(String text, String uri, Map<String, Object?> action) {
  final edit = action['edit']! as Map<String, Object?>;
  final changes = edit['changes']! as Map<String, Object?>;
  final edits = [
    for (final e in changes[uri]! as List<Object?>)
      if (e case {
        'range': final Map<String, Object?> range,
        'newText': final String text,
      })
        (range: range, text: text),
  ];
  int at(Object? position) => offsetOf(text, position! as Map<String, Object?>);
  // Apply from the end, so earlier offsets stay valid.
  edits.sort((a, b) => at(b.range['start']).compareTo(at(a.range['start'])));
  var result = text;
  for (final e in edits) {
    result = result.replaceRange(
      at(e.range['start']),
      at(e.range['end']),
      e.text,
    );
  }
  return result;
}
```

`plugin/test/markers.dart`:

```dart
/// One marker comment in a fixture.
///
/// `// @generate toString, equality` asks for actions on the next class.
/// `at _count` puts the cursor on a field instead, and `select a..b` selects
/// from field `a` to field `b`. `// @not copyWith noBuilder` asserts that an
/// action is absent, and names the reason.
final class Marker(
  /// The index of the marker line among all marker lines of the file.
  final int index,
  final bool expected,
  final List<String> names, {
  final String? reason,
  final String? at,
  final (String, String)? select,
});

final _line = RegExp(r'^\s*// @(generate|not) (.+)$', multiLine: true);

List<Marker> parseMarkers(String text) => [
  for (final (i, m) in _line.allMatches(text).indexed) _parse(i, m),
];

Marker _parse(int index, RegExpMatch match) {
  var rest = match.group(2)!;
  String? at;
  (String, String)? select;
  if (RegExp(r' at (\w+)$').firstMatch(rest) case final m?) {
    at = m.group(1);
    rest = rest.substring(0, m.start);
  }
  if (RegExp(r' select (\w+)\.\.(\w+)$').firstMatch(rest) case final m?) {
    select = (m.group(1)!, m.group(2)!);
    rest = rest.substring(0, m.start);
  }
  if (match.group(1) == 'generate') {
    final names = rest.split(',').map((n) => n.trim()).toList();
    return Marker(index, true, names, at: at, select: select);
  }
  final [name, reason] = rest.split(' ');
  return Marker(index, false, [name], reason: reason, at: at);
}

/// The selection that [marker] asks for in [text]: `(start, end)`.
(int, int) target(String text, Marker marker) {
  final after = _line.allMatches(text).elementAt(marker.index).end;
  int find(String pattern, int from) {
    final m = RegExp(pattern).allMatches(text, from).firstOrNull;
    if (m == null) throw StateError('marker ${marker.index}: no $pattern');
    return m.start;
  }

  if (marker.select case (final from, final to)) {
    final start = find('\\b$from\\b', after);
    return (start, find('\\b$to\\b', start) + to.length);
  }
  if (marker.at case final name?) {
    final start = find('\\b$name\\b', after);
    return (start, start);
  }
  final declaration = RegExp(r'\b(class|enum|mixin)\s+(const\s+)?(\w+)')
      .allMatches(text, after)
      .first;
  final start =
      declaration.start +
      declaration.group(0)!.lastIndexOf(declaration.group(3)!);
  return (start, start);
}
```

`plugin/test/e2e_test.dart`:

```dart
/// Runs every fixture through the real analysis server over LSP.
///
/// Run with `dart test -t e2e`. `DART_GENERATE_UPDATE=1` writes the output to
/// `fixtures/lib/` instead of comparing: review that diff before you commit.
@Tags(['e2e'])
@Timeout(Duration(minutes: 20))
library;

import 'dart:io';

import 'package:dart_generate/src/assists.dart';
import 'package:test/test.dart';

import 'lsp.dart';
import 'markers.dart';

final _input = Directory('../fixtures/input');
final _expected = Directory('../fixtures/lib');
final _update = Platform.environment['DART_GENERATE_UPDATE'] == '1';

List<String> _dartFiles(Directory dir) => dir.existsSync()
    ? ([
        for (final f in dir.listSync().whereType<File>())
          if (f.path.endsWith('.dart')) f.uri.pathSegments.last,
      ]..sort())
    : [];

void main() {
  final names = _dartFiles(_input);
  late Directory root;
  late File log;
  late Lsp lsp;

  setUpAll(() async {
    root = Directory.systemTemp.createTempSync('dart_generate_e2e');
    Directory('${root.path}/lib').createSync();
    for (final name in names) {
      File('${_input.path}/$name').copySync('${root.path}/lib/$name');
    }
    File('${root.path}/pubspec.yaml').writeAsStringSync('''
name: e2e
environment:
  sdk: ^3.13.0
dependencies:
  collection: ^1.19.1
dev_dependencies:
  lints: ^6.1.0
''');
    File('${root.path}/analysis_options.yaml').writeAsStringSync('''
include: package:lints/recommended.yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
plugins:
  dart_generate:
    path: ${Directory.current.absolute.path}
''');
    await _run(['pub', 'get', '--offline'], root.path);
    log = File('${root.path}/dart_generate.log');
    // `dart analyze` compiles the plugin and prints plugin errors, which the
    // editor never shows.
    final analyze = await _run(['analyze'], root.path, log: log.path);
    expect(
      analyze,
      isNot(contains('An error occurred while executing an analyzer plugin')),
    );
    lsp = await Lsp.start(root.path, log: log.path);
  });

  tearDownAll(() async {
    await lsp.stop();
    root.deleteSync(recursive: true);
  });

  test('markers cover every generator', () {
    expect(names, isNotEmpty, reason: 'fixtures/input is missing or empty');
    if (!_update) expect(_dartFiles(_expected), names);
    final markers = [
      for (final name in names)
        ...parseMarkers(File('${_input.path}/$name').readAsStringSync()),
    ];
    expect(markers, isNotEmpty);
    for (final m in markers) {
      expect(generatorNames, containsAll(m.names));
    }
    final generated = {
      for (final m in markers)
        if (m.expected) ...m.names,
    };
    expect(generated, containsAll(generatorNames));
  });

  for (final name in names) {
    test(name, () async {
      final path = '${root.path}/lib/$name';
      final uri = Uri.file(path).toString();
      var text = File(path).readAsStringSync();
      var version = 1;
      lsp.notify('textDocument/didOpen', {
        'textDocument': {
          'uri': uri,
          'languageId': 'dart',
          'version': version,
          'text': text,
        },
      });

      Future<List<Map<String, Object?>>> actions((int, int) selection) async {
        final (start, end) = selection;
        final result = await lsp.request('textDocument/codeAction', {
          'textDocument': {'uri': uri},
          'range': {'start': position(text, start), 'end': position(text, end)},
          'context': {
            'diagnostics': <Object?>[],
            'only': ['refactor.generate'],
          },
        });
        return [
          for (final a in (result as List<Object?>?) ?? const [])
            a! as Map<String, Object?>,
        ];
      }

      // Polls until [found] accepts the actions, or the time is up.
      Future<List<Map<String, Object?>>> poll(
        (int, int) Function() selection,
        bool Function(List<Map<String, Object?>>) found,
      ) async {
        final deadline = DateTime.now().add(const Duration(seconds: 120));
        while (true) {
          final result = await actions(selection());
          if (found(result) || DateTime.now().isAfter(deadline)) return result;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }

      final markers = parseMarkers(text);
      for (final marker in markers.where((m) => m.expected)) {
        for (final generator in marker.names) {
          final kind = 'refactor.generate.$generator';
          final result = await poll(
            () => target(text, marker),
            (r) => r.any((a) => a['kind'] == kind),
          );
          final action = result.where((a) => a['kind'] == kind).firstOrNull;
          if (action == null) fail('$name: marker ${marker.index}: no $kind');
          text = applyEdit(text, uri, action);
          lsp.notify('textDocument/didChange', {
            'textDocument': {'uri': uri, 'version': ++version},
            'contentChanges': [
              {'text': text},
            ],
          });
        }
      }

      final absent = markers.where((m) => !m.expected).toList();
      if (absent.isNotEmpty) {
        // An empty answer proves nothing until the plugin answers somewhere
        // in this file.
        final deadline = DateTime.now().add(const Duration(seconds: 120));
        var answered = false;
        while (!answered && DateTime.now().isBefore(deadline)) {
          for (final m in markers) {
            if ((await actions(target(text, m))).isNotEmpty) answered = true;
          }
          if (!answered) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
        }
        if (!answered) {
          fail('$name: no action appeared, so @not proves nothing');
        }
        for (final marker in absent) {
          final kinds = (await actions(
            target(text, marker),
          )).map((a) => a['kind']);
          expect(
            kinds,
            isNot(contains('refactor.generate.${marker.names.single}')),
            reason: '$name: marker ${marker.index}',
          );
        }
      }

      final expected = File('${_expected.path}/$name');
      if (_update) {
        expected.writeAsStringSync(text);
      } else {
        expect(text, expected.readAsStringSync());
      }
    });
  }

  test('the log is empty', () {
    expect(log.existsSync() ? log.readAsStringSync() : '', isEmpty);
  });
}

Future<String> _run(List<String> args, String dir, {String? log}) async {
  final result = await Process.run(
    Platform.resolvedExecutable,
    args,
    workingDirectory: dir,
    environment: {'DART_GENERATE_LOG': ?log},
  );
  return '${result.stdout}${result.stderr}';
}
```

- [ ] **Step 4: Write the adapter**

`plugin/lib/src/read_class.dart`:

```dart
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:generate_core/generate_core.dart';

/// Reads a resolved class into the model that the generators use.
///
/// Elements give the meaning. Positions come from the syntax tree elsewhere.
ClassModel readClass(ClassElement element, TypeSystem types) {
  final fieldTypes = <String, DartType>{};
  final fields = <FieldModel>[];

  void add(String name, DartType type, FieldElement? field) {
    if (fieldTypes.containsKey(name)) return;
    fieldTypes[name] = type;
    fields.add(
      FieldModel(
        name,
        readType(type, types),
        isFinal: field?.isFinal ?? true,
        isLate: field?.isLate ?? false,
        hasInitializer: field?.hasInitializer ?? false,
      ),
    );
  }

  // Header order first, so inherited fields keep their place.
  for (final p in element.primaryConstructor?.formalParameters ?? const []) {
    switch (p) {
      case SuperFormalParameterElement():
        if (_inheritedField(p) case final field?) {
          add(p.displayName, p.type, field);
        }
      case FieldFormalParameterElement(:final field?):
        add(field.displayName, field.type, field);
    }
  }
  for (final f in element.fields) {
    if (f.isStatic || f.isAbstract || f.isExternal) continue;
    if (!f.isOriginDeclaration && !f.isOriginDeclaringFormalParameter) continue;
    add(f.displayName, f.type, f);
  }

  final constructors = [
    for (final c in element.constructors)
      ConstructorModel(
        c.name == 'new'
            ? element.displayName
            : '${element.displayName}.${c.name}',
        [
          for (final p in c.formalParameters)
            ParamModel(
              p.displayName,
              readType(p.type, types),
              isNamed: p.isNamed,
              isRequired: p.isRequired,
              defaultValue: p.defaultValueCode,
              fitsField: switch (fieldTypes[p.displayName]) {
                final type? => types.isAssignableTo(type, p.type),
                null => false,
              },
            ),
        ],
        isPublic: c.isPublic,
        isCallable: c.isFactory || !element.isAbstract,
      ),
  ];
  return ClassModel(
    element.thisType.getDisplayString(),
    fields,
    chooseBuilder(fields, constructors),
  );
}

/// The field that a `super.` parameter sets, following `super.` chains.
FieldElement? _inheritedField(SuperFormalParameterElement parameter) {
  FormalParameterElement? p = parameter;
  while (p is SuperFormalParameterElement) {
    p = p.superConstructorParameter;
  }
  return p is FieldFormalParameterElement ? p.field : null;
}

/// Sorts [type] into the kinds that the JSON rules know.
TypeModel readType(DartType type, TypeSystem types) {
  final code = type.getDisplayString();
  final isNullable = types.isPotentiallyNullable(type);
  if (type is DynamicType) return PassthroughType(code, isNullable: true);
  if (type is TypeParameterType) {
    return TypeParameterModel(code, isNullable: isNullable);
  }
  if (type is! InterfaceType) return OtherType(code, isNullable: isNullable);
  if (type.isDartCoreInt ||
      type.isDartCoreString ||
      type.isDartCoreBool ||
      type.isDartCoreNum) {
    return PrimitiveType(code, isNullable: isNullable);
  }
  if (type.isDartCoreDouble) return DoubleType(code, isNullable: isNullable);
  if (type.isDartCoreObject) {
    return PassthroughType(code, isNullable: isNullable);
  }
  if (type.element is EnumElement) {
    return EnumType(code, isNullable: isNullable);
  }
  if (type.element.displayName == 'DateTime' &&
      type.element.library.isDartCore) {
    return DateTimeType(code, isNullable: isNullable);
  }
  final arguments = [for (final a in type.typeArguments) readType(a, types)];
  if (type.isDartCoreList) {
    return ListType(code, arguments.single, isNullable: isNullable);
  }
  if (type.isDartCoreSet) {
    return SetType(code, arguments.single, isNullable: isNullable);
  }
  if (type.isDartCoreMap) {
    return MapType(code, arguments[0], arguments[1], isNullable: isNullable);
  }
  return OtherType(code, isNullable: isNullable);
}
```

- [ ] **Step 5: Write the placement rules**

`plugin/lib/src/placement.dart`:

```dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:generate_core/generate_core.dart';

// `format` takes a range in original-file coordinates, and it replaces the
// range with the formatted text of the range. A range that starts or ends in
// whitespace loses that whitespace: the formatted text starts and ends at a
// token. So each insertion goes right after an existing token, and the range
// runs from that token to the next one.

/// Writes [members] into [cls]. An existing member with the same name is
/// replaced in place. The rest go at the end of the body. Returns whether
/// any member already existed.
bool writeMembers(
  DartFileEditBuilder builder,
  ClassDeclaration cls,
  List<Member> members,
) {
  var replaced = false;
  final atEnd = <String>[];
  for (final member in members) {
    final existing = findMember(cls, member.name);
    if (existing != null) {
      replaced = true;
      replaceMember(builder, existing, member.code);
    } else {
      atEnd.add(member.code);
    }
  }
  if (atEnd.isNotEmpty) insertAtEnd(builder, cls, atEnd.join('\n\n'));
  return replaced;
}

/// The member of [cls] named [name], or `null`.
ClassMember? findMember(ClassDeclaration cls, String name) {
  for (final member in cls.body.members) {
    final found = switch (member) {
      MethodDeclaration(name: final token) => token.lexeme == name,
      ConstructorDeclaration(name: final token?) => token.lexeme == name,
      FieldDeclaration(:final fields) => fields.variables.any(
        (v) => v.name.lexeme == name,
      ),
      _ => false,
    };
    if (found) return member;
  }
  return null;
}

/// Replaces [member], keeping its doc comment.
void replaceMember(
  DartFileEditBuilder builder,
  ClassMember member,
  String code,
) {
  final start = member.metadata.isEmpty
      ? member.firstTokenAfterCommentAndMetadata.offset
      : member.metadata.first.offset;
  final range = SourceRange(start, member.end - start);
  builder.addSimpleReplacement(range, code);
  builder.format(range);
}

/// Adds [code] at the end of the body of [cls], after one blank line.
void insertAtEnd(
  DartFileEditBuilder builder,
  ClassDeclaration cls,
  String code,
) {
  switch (cls.body) {
    case BlockClassBody(:final rightBracket, :final members):
      final gap = members.isEmpty ? '\n' : '\n\n';
      _insertAfter(builder, cls, rightBracket.previous!, '$gap$code');
    case EmptyClassBody(:final semicolon):
      _replaceSemicolon(builder, semicolon, code);
  }
}

/// Inserts [text] after [token] and any comment that ends its line.
/// [node] is any node of the unit, for line numbers.
void _insertAfter(
  DartFileEditBuilder builder,
  AstNode node,
  Token token,
  String text,
) {
  final lines = (node.root as CompilationUnit).lineInfo;
  final line = lines.getLocation(token.end).lineNumber;
  final next = token.next!;
  var offset = token.end;
  for (Token? c = next.precedingComments; c != null; c = c.next) {
    if (lines.getLocation(c.offset).lineNumber != line) break;
    offset = c.end;
  }
  builder.addSimpleInsertion(offset, text);
  builder.format(SourceRange(token.offset, next.end - token.offset));
}

/// Turns a `;` body into `{ code }`.
void _replaceSemicolon(
  DartFileEditBuilder builder,
  Token semicolon,
  String code,
) {
  builder.addSimpleReplacement(
    SourceRange(semicolon.offset, semicolon.length),
    ' {\n$code\n}',
  );
  final start = semicolon.previous!.offset;
  builder.format(SourceRange(start, semicolon.end - start));
}
```

- [ ] **Step 6: Write the base assist**

`plugin/lib/src/assist.dart`:

```dart
import 'dart:io';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:generate_core/generate_core.dart';

import 'placement.dart';
import 'read_class.dart';

/// The base of every dart_generate assist.
///
/// A failure stays inside its own assist (ADR 0006): the edit is built in a
/// draft, and only a finished draft reaches the server's builder. Any other
/// error goes to the log, and the menu shows the other actions.
abstract class GenerateAssist extends ResolvedCorrectionProducer {
  GenerateAssist({required super.context});

  /// `Generate`, or `Regenerate` when a member already exists.
  String verb = 'Generate';

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  List<String> get assistArguments => [verb];

  /// Adds the edit to [draft], or returns without one when the action does
  /// not apply here.
  Future<void> generate(ChangeBuilder draft);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    try {
      final draft = ChangeBuilder(
        session: unitResult.session,
        defaultEol: builder.defaultEol,
      );
      await generate(draft);
      final edits = [
        for (final fileEdit in draft.sourceChange.edits) ...fileEdit.edits,
      ];
      if (edits.isEmpty) return;
      await builder.addDartFileEdit(file, (b) {
        for (final e in edits) {
          b.addSimpleReplacement(
            SourceRange(e.offset, e.length),
            e.replacement,
          );
        }
      });
    } on InconsistentAnalysisException {
      rethrow;
    } on ConflictingEditException {
      rethrow;
    } catch (error, stack) {
      writeLog(assistKind!.id, file, error, stack);
    }
  }

  /// The class whose header or field the cursor is on, with its model.
  ///
  /// `null` when the cursor is anywhere else, or in an enum, mixin or
  /// extension type (`notAClass`).
  ClassTarget? classTarget() {
    final cls = node.thisOrAncestorOfType<ClassDeclaration>();
    if (cls == null) return null;
    final element = cls.declaredFragment?.element;
    if (element == null) return null;
    final names = _fieldNames(cls);
    final only = selectionLength == 0
        ? null
        : {
            for (final MapEntry(:key, :value) in names.entries)
              if (value >= selectionOffset && value < selectionEnd) key,
          };
    final bodyStart = cls.body.beginToken.offset;
    final onHeader =
        selectionOffset >= cls.offset && selectionOffset < bodyStart;
    final onField = node.thisOrAncestorOfType<FieldDeclaration>() != null;
    if (!onHeader && !onField && (only == null || only.isEmpty)) return null;
    return ClassTarget(
      cls,
      readClass(element, typeSystem),
      only == null || only.isEmpty ? null : only,
    );
  }

  /// Writes [outcome] into [cls] and sets [verb].
  Future<void> write(
    ChangeBuilder draft,
    ClassDeclaration cls,
    Outcome outcome,
  ) async {
    if (outcome case Generated(:final members, :final imports)) {
      await draft.addDartFileEdit(file, (b) {
        if (writeMembers(b, cls, members)) verb = 'Regenerate';
        for (final uri in imports) {
          b.importLibrary(Uri.parse(uri));
        }
      });
    }
  }
}

/// The class an action works on.
final class ClassTarget(
  final ClassDeclaration node,
  final ClassModel model,

  /// The names of the fields that the selection covers, or `null`.
  final Set<String>? only,
);

/// The name offset of each field that the class declares or takes through a
/// header `super.` parameter.
Map<String, int> _fieldNames(ClassDeclaration cls) => {
  if (cls.namePart case PrimaryConstructorDeclaration(:final formalParameters))
    for (final p in formalParameters.parameters)
      if (p.name case final name?) name.lexeme: name.offset,
  for (final member in cls.body.members)
    if (member is FieldDeclaration && !member.isStatic)
      for (final v in member.fields.variables) v.name.lexeme: v.name.offset,
};

/// Appends a failure to the log, and empties the log when it passes 1 MB.
///
/// The path is `DART_GENERATE_LOG`, or `~/.dartServer/dart_generate.log`.
void writeLog(String generator, String file, Object error, StackTrace stack) {
  try {
    final env = Platform.environment;
    final path =
        env['DART_GENERATE_LOG'] ??
        '${env['HOME']}/.dartServer/dart_generate.log';
    final log = File(path);
    if (log.existsSync() && log.lengthSync() > 1024 * 1024) {
      log.writeAsStringSync('');
    }
    log.writeAsStringSync(
      '${DateTime.now().toIso8601String()} $generator $file\n$error\n$stack\n',
      mode: FileMode.append,
    );
  } on FileSystemException {
    // The log is best effort. A failure here must not hide the other actions.
  }
}
```

- [ ] **Step 7: Run the e2e test and see it fail**

Create `plugin/lib/src/assists.dart` with only the list, so the test compiles:

```dart
/// The suffix of every assist ID: `generate.<name>`. The e2e markers use the
/// same names.
const generatorNames = <String>[];
```

Create `plugin/lib/main.dart` with no assists yet, so the server can load the plugin:

```dart
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

/// The entry point that the analysis server loads.
final plugin = DartGeneratePlugin();

final class DartGeneratePlugin extends Plugin {
  @override
  String get name => 'dart_generate';

  @override
  void register(PluginRegistry registry) {}
}
```

Run: `cd plugin && dart test -t e2e -N 'markers cover'`
Expected: FAIL in `markers cover every generator`: `toString` is not in `generatorNames`.

- [ ] **Step 8: Write the toString assist and the entry point**

Replace `plugin/lib/src/assists.dart` with:

```dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:generate_core/generate_core.dart';

import 'assist.dart';
import 'placement.dart';

/// The suffix of every assist ID: `generate.<name>`. The e2e markers use the
/// same names.
const generatorNames = ['toString'];

AssistKind _kind(String name, String message) =>
    AssistKind('generate.$name', 30, message);

final class GenerateToString extends GenerateAssist {
  GenerateToString({required super.context});

  @override
  AssistKind get assistKind => _kind('toString', '{0} toString()');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final target = classTarget();
    if (target == null) return;
    // customToString: a hand-written toString is domain text. Keep it.
    if (findMember(target.node, 'toString') case final MethodDeclaration m
        when !_isGenerated(m, target.model.name)) {
      return;
    }
    await write(
      draft,
      target.node,
      generateToString(target.model, only: target.only),
    );
  }

  /// Whether [method] returns `'ClassName(...`, the generated shape.
  static bool _isGenerated(MethodDeclaration method, String className) {
    final body = method.body;
    if (body is! ExpressionFunctionBody) return false;
    final text = body.expression.toSource();
    return text.startsWith("'$className(") || text.startsWith('"$className(');
  }
}
```

Replace `plugin/lib/main.dart` with:

```dart
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/assists.dart';

/// The entry point that the analysis server loads.
final plugin = DartGeneratePlugin();

final class DartGeneratePlugin extends Plugin {
  @override
  String get name => 'dart_generate';

  @override
  void register(PluginRegistry registry) {
    registry.registerAssist(GenerateToString.new);
  }
}
```

- [ ] **Step 9: Run the e2e test and see it pass**

Run: `cd plugin && dart analyze && dart test -t e2e`
Expected: `No issues found!`, then `+3: All tests passed!` in about 30 s. The first run compiles the plugin and takes longer.

If a file comparison fails, read the `Expected:` and `Actual:` text first. The formatter output must match `fixtures/lib/to_string.dart` byte for byte.

- [ ] **Step 10: Commit**

```bash
git add plugin fixtures
git commit -m "Add the plugin, the e2e test and Generate toString

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Generate ==() and hashCode

**Files:**
- Create: `fixtures/input/equality.dart`, `fixtures/lib/equality.dart`, `fixtures/test/equality_test.dart`
- Modify: `plugin/lib/src/assists.dart`, `plugin/lib/main.dart`

**Interfaces:**
- Consumes: Task 8 (`GenerateAssist`, `classTarget`, `write`, `_kind`) and `generateEquality` from Task 4.
- Produces: `GenerateEquality` with the ID `generate.equality`.

- [ ] **Step 1: Write the fixture and the expected output**

`fixtures/input/equality.dart`:

```dart
sealed class const Entry(final int pence);

// An inherited field through a super parameter.
// @generate toString, equality
class const Payment(super.pence, final String to) extends Entry;

// A generic class with a bound.
// @generate equality
class const Range<T extends Comparable<T>>(final T low, final T high);

// A collection field compares deeply and adds the import.
// @generate equality
class const Tagged(final String id, final List<String> tags);

// Only the selected fields.
// @generate equality select left..right
class const Span(final int left, final int right, final int extra);

// A mutable class gets no ==.
// @not equality mutableClass
class Tally {
  int count = 0;
}
```

`fixtures/lib/equality.dart`:

```dart
import 'package:collection/collection.dart';

sealed class const Entry(final int pence);

// An inherited field through a super parameter.
// @generate toString, equality
class const Payment(super.pence, final String to) extends Entry {
  @override
  String toString() => 'Payment(pence: $pence, to: $to)';

  @override
  bool operator ==(Object other) =>
      other is Payment && other.pence == pence && other.to == to;

  @override
  int get hashCode => Object.hash(pence, to);
}

// A generic class with a bound.
// @generate equality
class const Range<T extends Comparable<T>>(final T low, final T high) {
  @override
  bool operator ==(Object other) =>
      other is Range<T> && other.low == low && other.high == high;

  @override
  int get hashCode => Object.hash(low, high);
}

// A collection field compares deeply and adds the import.
// @generate equality
class const Tagged(final String id, final List<String> tags) {
  @override
  bool operator ==(Object other) =>
      other is Tagged &&
      other.id == id &&
      const DeepCollectionEquality().equals(other.tags, tags);

  @override
  int get hashCode =>
      Object.hash(id, const DeepCollectionEquality().hash(tags));
}

// Only the selected fields.
// @generate equality select left..right
class const Span(final int left, final int right, final int extra) {
  @override
  bool operator ==(Object other) =>
      other is Span && other.left == left && other.right == right;

  @override
  int get hashCode => Object.hash(left, right);
}

// A mutable class gets no ==.
// @not equality mutableClass
class Tally {
  int count = 0;
}
```

`fixtures/test/equality_test.dart`:

```dart
import 'package:fixtures/equality.dart';
import 'package:test/test.dart';

void main() {
  test('an inherited field takes part in == and hashCode', () {
    expect(Payment(3, 'bob'), Payment(3, 'bob'));
    expect(Payment(3, 'bob').hashCode, Payment(3, 'bob').hashCode);
    expect(Payment(3, 'bob'), isNot(Payment(4, 'bob')));
  });

  test('a list field compares by content', () {
    expect(Tagged('a', ['x']), Tagged('a', ['x']));
    expect(Tagged('a', ['x']).hashCode, Tagged('a', ['x']).hashCode);
    expect(Tagged('a', ['x']), isNot(Tagged('a', ['y'])));
  });

  test('a selection leaves the other fields out', () {
    expect(Span(1, 2, 3), Span(1, 2, 4));
  });
}
```

Run: `cd fixtures && dart analyze && dart test`
Expected: `No issues found!` and `+3: All tests passed!`

Run: `cd plugin && dart test -t e2e -N 'markers cover'`
Expected: FAIL: `equality` is not in `generatorNames`.

- [ ] **Step 2: Write the assist**

In `plugin/lib/src/assists.dart`, replace the list with:

```dart
const generatorNames = ['toString', 'equality'];
```

Append:

```dart
final class GenerateEquality extends GenerateAssist {
  GenerateEquality({required super.context});

  @override
  AssistKind get assistKind => _kind('equality', '{0} ==() and hashCode');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final target = classTarget();
    if (target == null) return;
    await write(
      draft,
      target.node,
      generateEquality(target.model, only: target.only),
    );
  }
}
```

In `plugin/lib/main.dart`, replace the body of `register` with:

```dart
    registry
      ..registerAssist(GenerateToString.new)
      ..registerAssist(GenerateEquality.new);
```

- [ ] **Step 3: Run the e2e test and see it pass**

Run: `cd plugin && dart analyze && dart test -t e2e`
Expected: `No issues found!` and `+4: All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add plugin fixtures
git commit -m "Add Generate == and hashCode

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Generate copyWith()

**Files:**
- Create: `fixtures/input/copy_with.dart`, `fixtures/lib/copy_with.dart`, `fixtures/test/copy_with_test.dart`
- Modify: `plugin/lib/src/placement.dart`, `plugin/lib/src/assists.dart`, `plugin/lib/main.dart`

**Interfaces:**
- Consumes: Task 8, and `generateCopyWith` from Task 5.
- Produces: `GenerateCopyWith` with the ID `generate.copyWith`. `writeMembers` keeps an existing `_unset`.

- [ ] **Step 1: Write the fixture and the expected output**

`fixtures/input/copy_with.dart`:

```dart
// A public unnamed factory is the builder, so copyWith validates.
// @generate copyWith
class const Limit._(final String category, final int pence) {
  factory Limit(String category, int pence) {
    if (category.isEmpty) throw ArgumentError.value(category, 'category');
    return Limit._(category, pence);
  }
}

// An abstract class has no builder.
// @not copyWith noBuilder
sealed class const Account(final int pence);

// A super parameter, and a nullable field that copyWith can clear.
// @generate copyWith
class const Deposit(super.pence, final String? note) extends Account;

// An unbounded type parameter, a private header field and a var field.
// @generate copyWith
class Box<T>(final T value, final int _count, var String note);

// State outside the constructor: no builder.
// @not copyWith noBuilder
class Store {
  final List<int> _recorded = [];

  void add(int value) => _recorded.add(value);
}

// copyWith no longer needs the sentinel, so it goes.
// @generate copyWith
class const Note(final String text) {
  static const _unset = Object();

  Note copyWith({Object? text = _unset}) =>
      Note(identical(text, _unset) ? this.text : text as String);
}
```

`fixtures/lib/copy_with.dart`:

```dart
// A public unnamed factory is the builder, so copyWith validates.
// @generate copyWith
class const Limit._(final String category, final int pence) {
  factory Limit(String category, int pence) {
    if (category.isEmpty) throw ArgumentError.value(category, 'category');
    return Limit._(category, pence);
  }

  Limit copyWith({String? category, int? pence}) =>
      Limit(category ?? this.category, pence ?? this.pence);
}

// An abstract class has no builder.
// @not copyWith noBuilder
sealed class const Account(final int pence);

// A super parameter, and a nullable field that copyWith can clear.
// @generate copyWith
class const Deposit(super.pence, final String? note) extends Account {
  static const _unset = Object();

  Deposit copyWith({int? pence, Object? note = _unset}) => Deposit(
    pence ?? this.pence,
    identical(note, _unset) ? this.note : note as String?,
  );
}

// An unbounded type parameter, a private header field and a var field.
// @generate copyWith
class Box<T>(final T value, final int _count, var String note) {
  static const _unset = Object();

  Box<T> copyWith({Object? value = _unset, int? count, String? note}) => Box(
    identical(value, _unset) ? this.value : value as T,
    count ?? _count,
    note ?? this.note,
  );
}

// State outside the constructor: no builder.
// @not copyWith noBuilder
class Store {
  final List<int> _recorded = [];

  void add(int value) => _recorded.add(value);
}

// copyWith no longer needs the sentinel, so it goes.
// @generate copyWith
class const Note(final String text) {
  Note copyWith({String? text}) => Note(text ?? this.text);
}
```

`fixtures/test/copy_with_test.dart`:

```dart
import 'package:fixtures/copy_with.dart';
import 'package:test/test.dart';

void main() {
  test('copyWith goes through the validating factory', () {
    expect(() => Limit('food', 5).copyWith(category: ''), throwsArgumentError);
    expect(Limit('food', 5).copyWith(pence: 7).pence, 7);
  });

  test('copyWith clears a nullable field and keeps it by default', () {
    final deposit = Deposit(5, 'tea');
    expect(deposit.copyWith(note: null).note, isNull);
    expect(deposit.copyWith(pence: 6).note, 'tea');
    expect(deposit.copyWith(pence: 6).pence, 6);
  });

  test('copyWith clears a nullable type parameter', () {
    final box = Box<int?>(5, 1, 'n');
    expect(box.copyWith(value: null).value, isNull);
    expect(box.copyWith(note: 'm').value, 5);
  });
}
```

Run: `cd fixtures && dart analyze && dart test`
Expected: `No issues found!` and `+6: All tests passed!`

Run: `cd plugin && dart test -t e2e -N 'markers cover'`
Expected: FAIL: `copyWith` is not in `generatorNames`.

- [ ] **Step 2: Keep an existing `_unset`**

In `plugin/lib/src/placement.dart`, in `writeMembers`, replace:

```dart
      replaced = true;
      replaceMember(builder, existing, member.code);
```

With:

```dart
      replaced = true;
      // `_unset` is the same text every time. Keep the one that is there.
      if (member.name != '_unset') {
        replaceMember(builder, existing, member.code);
      }
```

- [ ] **Step 3: Write the assist**

In `plugin/lib/src/assists.dart`, replace the list with:

```dart
const generatorNames = ['toString', 'equality', 'copyWith'];
```

Append:

```dart
final class GenerateCopyWith extends GenerateAssist {
  GenerateCopyWith({required super.context});

  @override
  AssistKind get assistKind => _kind('copyWith', '{0} copyWith()');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final target = classTarget();
    if (target == null) return;
    final outcome = generateCopyWith(target.model);
    if (outcome is! Generated) return;
    final cls = target.node;
    final old = findMember(cls, 'copyWith');
    final unset = findMember(cls, '_unset');
    await draft.addDartFileEdit(file, (b) {
      if (writeMembers(b, cls, outcome.members)) verb = 'Regenerate';
      final needsUnset = outcome.members.any((m) => m.name == '_unset');
      if (!needsUnset && old != null && unset != null) {
        if (!_usedElsewhere(cls, [unset, old])) b.deleteClassMember(unset);
      }
    });
  }

  /// Whether `_unset` appears in [cls] outside [skip].
  bool _usedElsewhere(ClassDeclaration cls, List<AstNode> skip) {
    final source = unitResult.content;
    for (final match in RegExp(r'\b_unset\b').allMatches(source)) {
      final at = match.start;
      if (at < cls.offset || at >= cls.end) continue;
      if (skip.any((n) => at >= n.offset && at < n.end)) continue;
      return true;
    }
    return false;
  }
}
```

In `plugin/lib/main.dart`, add `..registerAssist(GenerateCopyWith.new)` after the equality line.

- [ ] **Step 4: Run the e2e test and see it pass**

Run: `cd plugin && dart analyze && dart test -t e2e`
Expected: `No issues found!` and `+5: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add plugin fixtures
git commit -m "Add Generate copyWith

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Generate toJson() and fromJson()

**Files:**
- Create: `fixtures/input/money.dart`, `fixtures/input/expense.dart`, `fixtures/input/bag.dart`, `fixtures/input/json_limits.dart`
- Create: `fixtures/lib/money.dart`, `fixtures/lib/expense.dart`, `fixtures/lib/bag.dart`, `fixtures/lib/json_limits.dart`
- Create: `fixtures/test/json_test.dart`
- Modify: `plugin/lib/src/placement.dart`, `plugin/lib/src/assists.dart`, `plugin/lib/main.dart`

**Interfaces:**
- Consumes: Tasks 8 and 10, and `generateJson` from Task 6.
- Produces: `GenerateJson` with the ID `generate.json`. Placement gains `void insertAtStart(DartFileEditBuilder, ClassDeclaration, String)` and `void insertAfter(DartFileEditBuilder, AstNode, String)`, which Task 12 uses.

- [ ] **Step 1: Write the inputs**

`fixtures/input/money.dart`:

```dart
// A private primary constructor behind a validating factory. The factory is
// the builder, so copyWith and fromJson validate.
// @generate toString, equality, copyWith, json
class const Money._(final int pence) {
  factory Money.fromPence(int pence) {
    if (pence < 0) {
      throw ArgumentError.value(pence, 'pence', 'must not be negative');
    }
    return Money._(pence);
  }
}
```

`fixtures/input/expense.dart`:

```dart
import 'money.dart';

enum Kind { food, rent }

// Every JSON type rule at once.
// @generate toString, equality, copyWith, json
class const Expense(
  final Money amount,
  final Kind kind,
  final DateTime day,
  final double rate,
  final String? note,
  final Money? tip,
  final List<String> tags,
  final List<Money> parts, {
  final bool acknowledged = false,
});
```

`fixtures/input/bag.dart`:

```dart
import 'money.dart';

// Collections of every element rule, num, Object?, and a nullable field with
// a non-null default.
// @generate equality, json
class const Bag(
  final List<double> rates,
  final Set<String> tags,
  final List<DateTime> days,
  final List<String?> maybe,
  final Map<String, int> counts,
  final Map<String, Money> prices,
  final num n,
  final Object? raw, {
  final String? label = 'none',
});
```

`fixtures/input/json_limits.dart`, and the same text as `fixtures/lib/json_limits.dart`:

```dart
// JSON cannot write a type parameter.
// @not json typeParameterField
class const Wrapper<T>(final T value);

// @not json nestedCollection
class const Grid(final List<List<int>> rows);

// @not json nonStringMapKey
class const ByDay(final Map<int, int> totals);
```

- [ ] **Step 2: Write the expected output**

`fixtures/lib/money.dart`:

```dart
// A private primary constructor behind a validating factory. The factory is
// the builder, so copyWith and fromJson validate.
// @generate toString, equality, copyWith, json
class const Money._(final int pence) {
  factory Money.fromPence(int pence) {
    if (pence < 0) {
      throw ArgumentError.value(pence, 'pence', 'must not be negative');
    }
    return Money._(pence);
  }

  factory Money.fromJson(Object? json) => switch (json) {
    {'pence': final int pence} => Money.fromPence(pence),
    _ => throw FormatException('Invalid Money JSON', json),
  };

  @override
  String toString() => 'Money(pence: $pence)';

  @override
  bool operator ==(Object other) => other is Money && other.pence == pence;

  @override
  int get hashCode => pence.hashCode;

  Money copyWith({int? pence}) => Money.fromPence(pence ?? this.pence);

  Map<String, Object?> toJson() => {'pence': pence};
}
```

`fixtures/lib/expense.dart`:

```dart
import 'package:collection/collection.dart';

import 'money.dart';

enum Kind { food, rent }

// Every JSON type rule at once.
// @generate toString, equality, copyWith, json
class const Expense(
  final Money amount,
  final Kind kind,
  final DateTime day,
  final double rate,
  final String? note,
  final Money? tip,
  final List<String> tags,
  final List<Money> parts, {
  final bool acknowledged = false,
}) {
  factory Expense.fromJson(Object? json) => switch (json) {
    final Map<String, Object?> map &&
        {
          'amount': final Object amount,
          'kind': final String kind,
          'day': final String day,
          'rate': final num rate,
          'tags': final List<Object?> tags,
          'parts': final List<Object?> parts,
        } =>
      Expense(
        Money.fromJson(amount),
        Kind.values.asNameMap()[kind] ??
            (throw FormatException('Invalid "kind" in Expense JSON', json)),
        DateTime.tryParse(day) ??
            (throw FormatException('Invalid "day" in Expense JSON', json)),
        rate.toDouble(),
        switch (map['note']) {
          null => null,
          final String v => v,
          _ => throw FormatException('Invalid "note" in Expense JSON', json),
        },
        switch (map['tip']) {
          null => null,
          final Object v => Money.fromJson(v),
        },
        [
          for (final e in tags)
            e is String
                ? e
                : throw FormatException('Invalid "tags" in Expense JSON', json),
        ],
        [for (final e in parts) Money.fromJson(e)],
        acknowledged: switch (map['acknowledged']) {
          null => false,
          final bool v => v,
          _ => throw FormatException(
            'Invalid "acknowledged" in Expense JSON',
            json,
          ),
        },
      ),
    _ => throw FormatException('Invalid Expense JSON', json),
  };

  @override
  String toString() =>
      'Expense(amount: $amount, kind: $kind, day: $day, rate: $rate, '
      'note: $note, tip: $tip, tags: $tags, parts: $parts, '
      'acknowledged: $acknowledged)';

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.amount == amount &&
      other.kind == kind &&
      other.day == day &&
      other.rate == rate &&
      other.note == note &&
      other.tip == tip &&
      const DeepCollectionEquality().equals(other.tags, tags) &&
      const DeepCollectionEquality().equals(other.parts, parts) &&
      other.acknowledged == acknowledged;

  @override
  int get hashCode => Object.hash(
    amount,
    kind,
    day,
    rate,
    note,
    tip,
    const DeepCollectionEquality().hash(tags),
    const DeepCollectionEquality().hash(parts),
    acknowledged,
  );

  static const _unset = Object();

  Expense copyWith({
    Money? amount,
    Kind? kind,
    DateTime? day,
    double? rate,
    Object? note = _unset,
    Object? tip = _unset,
    List<String>? tags,
    List<Money>? parts,
    bool? acknowledged,
  }) => Expense(
    amount ?? this.amount,
    kind ?? this.kind,
    day ?? this.day,
    rate ?? this.rate,
    identical(note, _unset) ? this.note : note as String?,
    identical(tip, _unset) ? this.tip : tip as Money?,
    tags ?? this.tags,
    parts ?? this.parts,
    acknowledged: acknowledged ?? this.acknowledged,
  );

  Map<String, Object?> toJson() => {
    'amount': amount.toJson(),
    'kind': kind.name,
    'day': day.toIso8601String(),
    'rate': rate,
    'note': note,
    'tip': tip?.toJson(),
    'tags': tags,
    'parts': [for (final e in parts) e.toJson()],
    'acknowledged': acknowledged,
  };
}
```

`fixtures/lib/bag.dart`:

```dart
import 'package:collection/collection.dart';

import 'money.dart';

// Collections of every element rule, num, Object?, and a nullable field with
// a non-null default.
// @generate equality, json
class const Bag(
  final List<double> rates,
  final Set<String> tags,
  final List<DateTime> days,
  final List<String?> maybe,
  final Map<String, int> counts,
  final Map<String, Money> prices,
  final num n,
  final Object? raw, {
  final String? label = 'none',
}) {
  factory Bag.fromJson(Object? json) => switch (json) {
    final Map<String, Object?> map &&
        {
          'rates': final List<Object?> rates,
          'tags': final List<Object?> tags,
          'days': final List<Object?> days,
          'maybe': final List<Object?> maybe,
          'counts': final Map<String, Object?> counts,
          'prices': final Map<String, Object?> prices,
          'n': final num n,
        } =>
      Bag(
        [
          for (final e in rates)
            e is num
                ? e.toDouble()
                : throw FormatException('Invalid "rates" in Bag JSON', json),
        ],
        {
          for (final e in tags)
            e is String
                ? e
                : throw FormatException('Invalid "tags" in Bag JSON', json),
        },
        [
          for (final e in days)
            (e is String ? DateTime.tryParse(e) : null) ??
                (throw FormatException('Invalid "days" in Bag JSON', json)),
        ],
        [
          for (final e in maybe)
            e is String?
                ? e
                : throw FormatException('Invalid "maybe" in Bag JSON', json),
        ],
        {
          for (final MapEntry(:key, :value) in counts.entries)
            key: value is int
                ? value
                : throw FormatException('Invalid "counts" in Bag JSON', json),
        },
        {
          for (final MapEntry(:key, :value) in prices.entries)
            key: Money.fromJson(value),
        },
        n,
        map['raw'],
        label: map.containsKey('label')
            ? switch (map['label']) {
                null => null,
                final String v => v,
                _ => throw FormatException('Invalid "label" in Bag JSON', json),
              }
            : 'none',
      ),
    _ => throw FormatException('Invalid Bag JSON', json),
  };

  @override
  bool operator ==(Object other) =>
      other is Bag &&
      const DeepCollectionEquality().equals(other.rates, rates) &&
      const DeepCollectionEquality().equals(other.tags, tags) &&
      const DeepCollectionEquality().equals(other.days, days) &&
      const DeepCollectionEquality().equals(other.maybe, maybe) &&
      const DeepCollectionEquality().equals(other.counts, counts) &&
      const DeepCollectionEquality().equals(other.prices, prices) &&
      other.n == n &&
      other.raw == raw &&
      other.label == label;

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(rates),
    const DeepCollectionEquality().hash(tags),
    const DeepCollectionEquality().hash(days),
    const DeepCollectionEquality().hash(maybe),
    const DeepCollectionEquality().hash(counts),
    const DeepCollectionEquality().hash(prices),
    n,
    raw,
    label,
  );

  Map<String, Object?> toJson() => {
    'rates': rates,
    'tags': tags.toList(),
    'days': [for (final e in days) e.toIso8601String()],
    'maybe': maybe,
    'counts': counts,
    'prices': {
      for (final MapEntry(:key, :value) in prices.entries) key: value.toJson(),
    },
    'n': n,
    'raw': raw,
    'label': label,
  };
}
```

`fixtures/test/json_test.dart`:

```dart
import 'dart:convert';

import 'package:fixtures/bag.dart';
import 'package:fixtures/expense.dart';
import 'package:fixtures/money.dart';
import 'package:test/test.dart';

/// A JSON round trip through text, as a file or a server does it.
Object? _wire(Object? value) => jsonDecode(jsonEncode(value));

Expense _expense() => Expense(
  Money.fromPence(250),
  Kind.food,
  DateTime.utc(2026, 9, 28),
  1.5,
  'tea',
  null,
  ['a', 'b'],
  [Money.fromPence(1)],
);

/// A valid Expense JSON map with [key] set to [value].
Map<String, Object?> _expenseJsonWith(String key, Object? value) =>
    (_wire(_expense()) as Map<String, Object?>)..[key] = value;

void main() {
  group('Expense', () {
    test('survives a JSON round trip with equal value and hash', () {
      final expense = _expense();
      final back = Expense.fromJson(_wire(expense));
      expect(back, expense);
      expect(back.hashCode, expense.hashCode);
    });

    test('copyWith clears a nullable field and keeps the others', () {
      final expense = _expense();
      expect(expense.copyWith(note: null).note, isNull);
      expect(expense.copyWith(kind: Kind.rent).note, 'tea');
    });

    test('a file without the defaulted key reads the default', () {
      final json = _expenseJsonWith('note', null)..remove('acknowledged');
      expect(Expense.fromJson(json).acknowledged, isFalse);
    });

    test('JSON 1 reads as the double 1.0', () {
      final rate = Expense.fromJson(_expenseJsonWith('rate', 1)).rate;
      expect(rate, 1.0);
      expect(rate, isA<double>());
    });

    for (final (key, value) in [
      ('kind', 'nope'),
      ('day', 'not a date'),
      ('tags', [1]),
      ('note', 5),
      ('acknowledged', 'yes'),
    ]) {
      test('a bad "$key" throws a FormatException that names it', () {
        expect(
          () => Expense.fromJson(_expenseJsonWith(key, value)),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('"$key"'),
            ),
          ),
        );
      });
    }

    test('a JSON value that is not a map throws a FormatException', () {
      expect(() => Expense.fromJson([]), throwsFormatException);
    });
  });

  group('Bag', () {
    Bag bag({String? label}) => Bag(
      [1.5],
      {'a'},
      [DateTime.utc(2026)],
      [null, 'x'],
      {'k': 1},
      {'p': Money.fromPence(2)},
      3,
      // An Object? field compares with ==, so a map here would compare by
      // identity. A string keeps the round trip equal.
      'any',
      label: label,
    );

    test('an explicit null survives a non-null default', () {
      expect(Bag.fromJson(_wire(bag())).label, isNull);
    });

    test('a missing key reads the default', () {
      final json = _wire(bag()) as Map<String, Object?>..remove('label');
      expect(Bag.fromJson(json).label, 'none');
    });

    test('collections survive a round trip', () {
      final value = bag(label: 'x');
      expect(Bag.fromJson(_wire(value)), value);
    });
  });

  test('copyWith and fromJson go through the validating factory', () {
    expect(() => Money.fromPence(1).copyWith(pence: -1), throwsArgumentError);
    expect(() => Money.fromJson({'pence': -1}), throwsArgumentError);
  });
}
```

Run: `cd fixtures && dart analyze && dart test`
Expected: `No issues found!` and `+20: All tests passed!`

Run: `cd plugin && dart test -t e2e -N 'markers cover'`
Expected: FAIL: `json` is not in `generatorNames`.

- [ ] **Step 3: Place fromJson after the constructors**

In `plugin/lib/src/placement.dart`, replace the whole `writeMembers` function, including its doc comment, with:

```dart
/// Writes [members] into [cls]. An existing member with the same name is
/// replaced in place. `fromJson` goes after the last constructor. The rest
/// go at the end of the body. Returns whether any member already existed.
bool writeMembers(
  DartFileEditBuilder builder,
  ClassDeclaration cls,
  List<Member> members,
) {
  var replaced = false;
  final atStart = <String>[];
  final atEnd = <String>[];
  for (final member in members) {
    final existing = findMember(cls, member.name);
    if (existing != null) {
      replaced = true;
      // `_unset` is the same text every time. Keep the one that is there.
      if (member.name != '_unset') {
        replaceMember(builder, existing, member.code);
      }
    } else if (member.name == 'fromJson') {
      final last = _lastConstructor(cls);
      if (last == null) {
        atStart.add(member.code);
      } else {
        insertAfter(builder, last, member.code);
      }
    } else {
      atEnd.add(member.code);
    }
  }
  // A `;` body is one token, so it takes one edit.
  if (cls.body is EmptyClassBody) {
    atEnd.insertAll(0, atStart);
    atStart.clear();
  }
  if (atStart.isNotEmpty) insertAtStart(builder, cls, atStart.join('\n\n'));
  if (atEnd.isNotEmpty) insertAtEnd(builder, cls, atEnd.join('\n\n'));
  return replaced;
}

ClassMember? _lastConstructor(ClassDeclaration cls) => cls.body.members
    .where((m) => m is ConstructorDeclaration || m is PrimaryConstructorBody)
    .lastOrNull;
```

After `insertAtEnd`, add:

```dart
/// Adds [code] at the start of the body of [cls].
void insertAtStart(
  DartFileEditBuilder builder,
  ClassDeclaration cls,
  String code,
) {
  switch (cls.body) {
    case BlockClassBody(:final leftBracket, :final members):
      final gap = members.isEmpty ? '\n' : '\n\n';
      _insertAfter(builder, cls, leftBracket, '\n$code$gap');
    case EmptyClassBody(:final semicolon):
      _replaceSemicolon(builder, semicolon, code);
  }
}

/// Adds [code] after [node], after one blank line.
void insertAfter(DartFileEditBuilder builder, AstNode node, String code) =>
    _insertAfter(builder, node, node.endToken, '\n\n$code');
```

- [ ] **Step 4: Write the assist**

In `plugin/lib/src/assists.dart`, replace the list with:

```dart
const generatorNames = ['toString', 'equality', 'copyWith', 'json'];
```

Append:

```dart
final class GenerateJson extends GenerateAssist {
  GenerateJson({required super.context});

  @override
  AssistKind get assistKind => _kind('json', '{0} toJson() and fromJson()');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final target = classTarget();
    if (target == null) return;
    await write(draft, target.node, generateJson(target.model));
  }
}
```

In `plugin/lib/main.dart`, add `..registerAssist(GenerateJson.new)` after the copyWith line.

- [ ] **Step 5: Run the e2e test and see it pass**

Run: `cd plugin && dart analyze && dart test -t e2e`
Expected: `No issues found!` and `+9: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add plugin fixtures
git commit -m "Add Generate toJson and fromJson

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: Generate getter

**Files:**
- Create: `fixtures/input/getter.dart`, `fixtures/lib/getter.dart`
- Modify: `plugin/lib/src/assists.dart`, `plugin/lib/main.dart`

**Interfaces:**
- Consumes: Tasks 8 and 11 (`insertAfter`, `insertAtStart`, `readType`), and `generateGetter` from Task 7.
- Produces: `GenerateGetter` with the ID `generate.getter`.

- [ ] **Step 1: Write the fixture and the expected output**

`fixtures/input/getter.dart`:

```dart
// A getter for a body field goes after the field.
// @generate getter at _count
class Counter {
  int _count = 0;

  void bump() => _count++;
}

// A getter for a header field goes at the start of the body.
// @generate getter at _secret
class const Vault(final String _secret);

// The public name is taken.
// @not getter publicNameTaken at _size
class Sized {
  final int _size = 0;

  int get size => _size + 1;
}
```

`fixtures/lib/getter.dart`:

```dart
// A getter for a body field goes after the field.
// @generate getter at _count
class Counter {
  int _count = 0;

  int get count => _count;

  void bump() => _count++;
}

// A getter for a header field goes at the start of the body.
// @generate getter at _secret
class const Vault(final String _secret) {
  String get secret => _secret;
}

// The public name is taken.
// @not getter publicNameTaken at _size
class Sized {
  final int _size = 0;

  int get size => _size + 1;
}
```

Run: `cd fixtures && dart analyze`
Expected: `No issues found!`

Run: `cd plugin && dart test -t e2e -N 'markers cover'`
Expected: FAIL: `getter` is not in `generatorNames`.

- [ ] **Step 2: Write the assist**

In `plugin/lib/src/assists.dart`, add these imports in sorted order:

```dart
import 'package:analyzer/dart/element/element.dart';
```

```dart
import 'read_class.dart';
```

Replace the list with:

```dart
const generatorNames = ['toString', 'equality', 'copyWith', 'json', 'getter'];
```

Append:

```dart
final class GenerateGetter extends GenerateAssist {
  GenerateGetter({required super.context});

  @override
  AssistKind get assistKind => _kind('getter', 'Generate getter');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final cls = node.thisOrAncestorOfType<ClassDeclaration>();
    final element = cls?.declaredFragment?.element;
    if (cls == null || element == null) return;

    // The field under the cursor: in the body, or declared in the header.
    String? name;
    FieldDeclaration? declaration;
    final variable = node.thisOrAncestorOfType<VariableDeclaration>();
    final parameter = node.thisOrAncestorOfType<FormalParameter>();
    if (variable?.parent?.parent case final FieldDeclaration d
        when !d.isStatic) {
      name = variable!.name.lexeme;
      declaration = d;
    } else if (parameter?.declaredFragment?.element
        case FieldFormalParameterElement(isDeclaring: true)) {
      name = parameter!.name?.lexeme;
    }
    if (name == null || !name.startsWith('_')) return;
    final field = element.getField(name);
    if (field == null) return;
    // publicNameTaken: the class already has this public name.
    final public = publicName(name);
    if (element.getGetter(public) != null ||
        element.getMethod(public) != null) {
      return;
    }

    final outcome = generateGetter(
      FieldModel(name, readType(field.type, typeSystem)),
    );
    if (outcome is! Generated) return;
    final code = outcome.members.single.code;
    await draft.addDartFileEdit(file, (b) {
      if (declaration != null) {
        insertAfter(b, declaration, code);
      } else {
        insertAtStart(b, cls, code);
      }
    });
  }
}
```

In `plugin/lib/main.dart`, add `..registerAssist(GenerateGetter.new)` after the JSON line.

- [ ] **Step 3: Run the e2e test and see it pass**

Run: `cd plugin && dart format lib && dart analyze && dart test -t e2e`
Expected: `No issues found!` and `+10: All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add plugin fixtures
git commit -m "Add Generate getter

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13: Convert to primary constructor

**Files:**
- Create: `fixtures/input/primary_constructor.dart`, `fixtures/lib/primary_constructor.dart`
- Modify: `plugin/lib/src/assists.dart`, `plugin/lib/main.dart`

**Interfaces:**
- Consumes: Task 8, and `HeaderParam` and `primaryHeader` from Task 7.
- Produces: `ConvertToPrimaryConstructor` with the ID `generate.primaryConstructor`.

- [ ] **Step 1: Write the fixture and the expected output**

`fixtures/input/primary_constructor.dart`:

```dart
// @generate primaryConstructor
class Pair {
  /// The left side.
  final int left;

  final int right;

  /// Makes a pair.
  const Pair(this.left, this.right);
}

// @generate primaryConstructor
/// A tag with defaults.
class Tag {
  final String name;

  @Deprecated('Use name')
  int size;

  Tag(this.name, {this.size = 0});

  int get length => name.length;
}

// An initializer list does not move. Only this. and super. parameters do.
// @not primaryConstructor notConvertible
class Checked {
  final int value;

  Checked(this.value) : assert(value >= 0);
}
```

`fixtures/lib/primary_constructor.dart`:

```dart
// @generate primaryConstructor
/// Makes a pair.
class const Pair(
  /// The left side.
  final int left,
  final int right,
) {}

// @generate primaryConstructor
/// A tag with defaults.
class Tag(final String name, {@Deprecated('Use name') var int size = 0}) {
  int get length => name.length;
}

// An initializer list does not move. Only this. and super. parameters do.
// @not primaryConstructor notConvertible
class Checked {
  final int value;

  Checked(this.value) : assert(value >= 0);
}
```

Run: `cd fixtures && dart analyze`
Expected: `No issues found!`

Run: `cd plugin && dart test -t e2e -N 'markers cover'`
Expected: FAIL: `primaryConstructor` is not in `generatorNames`.

- [ ] **Step 2: Write the assist**

In `plugin/lib/src/assists.dart`, add this import in sorted order:

```dart
import 'package:analyzer/source/source_range.dart';
```

Replace the list with:

```dart
const generatorNames = [
  'toString',
  'equality',
  'copyWith',
  'json',
  'getter',
  'primaryConstructor',
];
```

Append:

```dart
final class ConvertToPrimaryConstructor extends GenerateAssist {
  ConvertToPrimaryConstructor({required super.context});

  @override
  AssistKind get assistKind =>
      _kind('primaryConstructor', 'Convert to primary constructor');

  @override
  Future<void> generate(ChangeBuilder draft) async {
    final cls = node.thisOrAncestorOfType<ClassDeclaration>();
    if (cls == null) return;
    final namePart = cls.namePart;
    if (namePart is! NameWithTypeParameters) return;
    if (selectionOffset < cls.offset ||
        selectionOffset >= cls.body.beginToken.offset) {
      return;
    }
    // notConvertible: anything the rules below reject.
    final plan = _plan(cls);
    if (plan == null) return;
    final (:constructor, :params, :moved) = plan;

    final content = unitResult.content;
    await draft.addDartFileEdit(file, (b) {
      b.addSimpleReplacement(
        SourceRange(namePart.offset, namePart.length),
        primaryHeader(
          namePart.typeName.lexeme,
          params,
          typeParameters: namePart.typeParameters?.toSource() ?? '',
          isConst: constructor.constKeyword != null,
        ),
      );
      for (final member in [...moved, constructor]) {
        b.addDeletion(SourceRange(member.offset, member.length));
      }
      if (constructor.documentationComment case final doc?) {
        final text = content.substring(doc.offset, doc.end);
        if (cls.documentationComment case final classDoc?) {
          b.addSimpleInsertion(classDoc.end, '\n///\n$text');
        } else {
          b.addSimpleInsertion(cls.offset, '$text\n');
        }
      }
      b.format(SourceRange(cls.offset, cls.length));
    });
  }

  /// The constructor to remove, the header parameters, and the fields that
  /// move into the header. `null` when the class is not convertible.
  ({
    ConstructorDeclaration constructor,
    List<HeaderParam> params,
    List<FieldDeclaration> moved,
  })?
  _plan(ClassDeclaration cls) {
    final generative = [
      for (final m in cls.body.members)
        if (m is ConstructorDeclaration && m.factoryKeyword == null) m,
    ];
    if (generative.length != 1) return null;
    final constructor = generative.single;
    if (constructor.name != null ||
        constructor.metadata.isNotEmpty ||
        constructor.initializers.isNotEmpty ||
        constructor.externalKeyword != null ||
        constructor.body is! EmptyFunctionBody) {
      return null;
    }

    final fields = {
      for (final m in cls.body.members)
        if (m is FieldDeclaration && !m.isStatic)
          for (final v in m.fields.variables) v.name.lexeme: m,
    };
    final params = <HeaderParam>[];
    final moved = <FieldDeclaration>{};
    for (final p in constructor.parameters.parameters) {
      if (p.functionTypedSuffix != null) return null;
      final defaultValue = p.declaredFragment?.element.defaultValueCode;
      switch (p) {
        case FieldFormalParameter(:final name):
          final declaration = fields[name.lexeme];
          if (declaration == null) return null;
          final list = declaration.fields;
          if (list.isLate || list.variables.any((v) => v.initializer != null)) {
            return null;
          }
          moved.add(declaration);
          params.add(
            HeaderParam(
              name.lexeme,
              type:
                  list.type?.toSource() ??
                  p.declaredFragment!.element.type.getDisplayString(),
              isFinal: list.isFinal,
              isNamed: p.isNamed,
              isOptionalPositional: p.isOptionalPositional,
              isRequired: p.isRequiredNamed,
              defaultValue: defaultValue,
              metadata: [
                _metadata(declaration),
                _metadata(p),
              ].where((m) => m.isNotEmpty).join('\n'),
            ),
          );
        case SuperFormalParameter(:final name):
          params.add(
            HeaderParam(
              name.lexeme,
              isNamed: p.isNamed,
              isOptionalPositional: p.isOptionalPositional,
              isRequired: p.isRequiredNamed,
              defaultValue: defaultValue,
              metadata: _metadata(p),
            ),
          );
        default:
          return null;
      }
    }
    // A declaration with two variables moves only if both move.
    final names = {for (final p in params) p.name};
    for (final d in moved) {
      if (!d.fields.variables.every((v) => names.contains(v.name.lexeme))) {
        return null;
      }
    }
    return (constructor: constructor, params: params, moved: moved.toList());
  }

  /// The doc comment and annotations of [node], as written.
  String _metadata(AnnotatedNode node) => unitResult.content
      .substring(node.offset, node.firstTokenAfterCommentAndMetadata.offset)
      .trim();
}
```

In `plugin/lib/main.dart`, add `..registerAssist(ConvertToPrimaryConstructor.new)` after the getter line.

- [ ] **Step 3: Run the e2e test and see it pass**

Run: `cd plugin && dart format lib && dart analyze && dart test -t e2e`
Expected: `No issues found!` and `+11: All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add plugin fixtures
git commit -m "Add Convert to primary constructor

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 14: Close the loop

**Files:**
- Modify: `plugin/test/e2e_test.dart`

**Interfaces:**
- Consumes: everything above.
- Produces: the final e2e coverage rule, and proof that each safety net turns red.

- [ ] **Step 1: Require a `@not` marker for each adapter reason**

In `plugin/test/e2e_test.dart`, add this import after the `assists.dart` import:

```dart
import 'package:generate_core/generate_core.dart';
```

Rename the test `markers cover every generator` to `markers cover every generator and adapter reason`. At the end of its body, add:

```dart
    final reasons = {
      for (final m in markers)
        if (!m.expected) m.reason,
    };
    for (final r in Reason.values.where((r) => r.owner == Owner.adapter)) {
      expect(reasons, contains(r.name));
    }
```

Run: `cd plugin && dart analyze && dart test -t e2e`
Expected: `No issues found!` and `+11: All tests passed!`

- [ ] **Step 2: Prove the reason check can fail**

Delete the line `// @not getter publicNameTaken at _size` from `fixtures/input/getter.dart` and from `fixtures/lib/getter.dart`.

Run: `cd plugin && dart test -t e2e -N 'markers cover'`
Expected: FAIL with `publicNameTaken` in the message.

Run: `git checkout fixtures`

- [ ] **Step 3: Prove the four safety nets from the spec**

Do each change, run the command, see red, then undo it with `git checkout plugin fixtures`.

1. In `fixtures/lib/equality.dart`, change `other.to == to` to `other.to != to`. Run `cd plugin && dart test -t e2e`. Expected: FAIL in `equality.dart` with an `Expected:`/`Actual:` diff.
2. In `plugin/test/e2e_test.dart`, delete the three lines of the `plugins:` block in the options text. Run `cd plugin && dart test -t e2e -N to_string`. Expected: FAIL after about 120 s with `no refactor.generate.toString`.
3. In `plugin/lib/src/assists.dart`, add `'setter'` to `generatorNames`. Run `cd plugin && dart test -t e2e -N 'markers cover'`. Expected: FAIL with `setter` in the message.
4. In `GenerateJson.generate`, add `throw StateError('planted failure');` after the `await write(...)` line. Run `cd plugin && dart test -t e2e`. It takes about 7 minutes, because each of three files waits 120 s. Expected: FAIL with `no refactor.generate.json` for `bag.dart`, `expense.dart` and `money.dart`, and `the log is empty` fails with `planted failure`. The other actions in those files still apply.

Run: `git status --short`
Expected: no output.

- [ ] **Step 4: Run every suite once more**

Run: `cd core && dart test && dart analyze`
Expected: `+44: All tests passed!` and `No issues found!`

Run: `cd fixtures && dart test && dart analyze && dart format --output=none --set-exit-if-changed lib`
Expected: `+20: All tests passed!`, `No issues found!` and `0 changed`.

Run: `cd plugin && dart test -t e2e && dart analyze`
Expected: `+11: All tests passed!` and `No issues found!`

- [ ] **Step 5: Try both editors by hand**

1. Make a scratch project: `dart create -t package /tmp/generate_try`.
2. Copy `fixtures/input/money.dart` into `/tmp/generate_try/lib/`.
3. Add the `plugins:` block from the README to `/tmp/generate_try/analysis_options.yaml`, and run `dart analyze` there.
4. In Zed, open the folder, put the cursor on `Money` and press Cmd+. The menu shows the four Generate actions.
5. In VS Code, add the README key binding. Press Cmd+N on `Money`. The menu shows only the Generate actions.
6. Apply "Generate toString()" in each editor. The result matches the toString member in `fixtures/lib/money.dart`.

If an action is missing, follow the README Troubleshooting steps before you change code.

- [ ] **Step 6: Commit**

```bash
git add plugin/test/e2e_test.dart
git commit -m "Require a @not marker for every adapter reason

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Decisions

The user answered these on 2026-09-28. Task 1 records the first three in the spec.

- A class without a generative constructor gets no "Convert to primary constructor". Converting adds only `()`.
- fromJson reads a `DateTime` with `tryParse`, so the error names the key and the class.
- A toString text over 70 characters splits into adjacent string literals after a comma.
- The plan runs with superpowers:subagent-driven-development: one subagent per task, with a review after each.
