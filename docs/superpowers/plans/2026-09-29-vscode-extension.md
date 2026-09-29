# dart_generate VS Code Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the VS Code extension of the spec. A Dart helper runs the plugin's assists, and a TypeScript extension adds Generate…, field pickers, a refactor preview and marks on stale members.

**Architecture:** Two new packages sit beside `core/` and `plugin/`. `helper/` (package `dart_generate_helper`) is a process that speaks JSON-RPC 2.0 over stdin and stdout. It resolves files with analyzer 14.4.0 and runs the plugin's own assists through `CorrectionProducerContext.createResolved`. `vscode/` is a TypeScript extension that owns the UI and starts the compiled helper. The plugin gains four public fields and a public API file, and its behavior does not change.

**Tech Stack:** Dart 3.13.2, `analyzer` 14.4.0, `analysis_server_plugin` 0.3.23, `analyzer_plugin` 0.14.17, `package:test`. TypeScript 6.0.3, the VS Code API 1.139, `vscode-jsonrpc` 9.0.3, esbuild 0.28.2, Mocha 12.0.2, `@vscode/test-electron` 3.1.0, `@vscode/vsce` 4.0.0.

**Source of truth:** `docs/superpowers/specs/2026-09-28-vscode-extension-design.md`, ADRs 0007 and 0008, and the amendments at the end of ADRs 0001 and 0006. Commit `69110bc` corrected them with the prototype findings.

**Evidence:** On 2026-09-29, a replay applied the tasks of this plan, one after another, to a fresh clone at `69110bc`. After each task, it ran that task's tests, and each run passed. The last step of each task gives the counts. Every code block and every patch in this plan comes from that replay.

## Global Constraints

- All paths are relative to `~/Projects/dart_generate`. Commit on the branch `vscode-extension`, or on a worktree of it. The repo has no remote.
- End each commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The SDK constraint is `^3.13.0` in every `pubspec.yaml`. The machine has Dart 3.13.2, Node v26.7.0 and npm 11.19.0.
- `plugin/pubspec.yaml` and `helper/pubspec.yaml` pin `analysis_server_plugin: 0.3.23`, `analyzer: 14.4.0` and `analyzer_plugin: 0.14.17` exactly.
- `core/` never depends on `analyzer`.
- Every Dart package uses `include: package:lints/recommended.yaml` with `strict-casts`, `strict-inference` and `strict-raw-types`. Before each commit, `dart analyze` prints `No issues found!` in each package that the task changes. `dart format --output=none --set-exit-if-changed .` exits with 0 there too.
- `vscode/package.json` pins these npm versions exactly: `vscode-jsonrpc` 9.0.3, `@types/vscode` 1.138.0, `@vscode/vsce` 4.0.0, `@vscode/test-electron` 3.1.0, `esbuild` 0.28.2, `typescript` 6.0.3, `eslint` 10.11.0, `typescript-eslint` 8.71.0, `@eslint/js` 10.0.1, `mocha` 12.0.2, `@types/mocha` 10.0.10, `@types/node` 24.19.0.
- Do not move to TypeScript 7. `typescript-eslint` 8.71.0 supports TypeScript below 6.1.
- `engines.vscode` is `^1.139.0`. The tests run in VS Code 1.139.1.
- Before each commit in `vscode/`, `npm run check` exits with 0. It runs `tsc --noEmit` in strict mode and ESLint.
- The plugin's behavior does not change. `dart test` in `plugin/` passes with its e2e test, and no existing test changes.
- The action IDs are `dataClass`, `toString`, `equality`, `copyWith`, `json`, `getter` and `primaryConstructor`. The kinds are `refactor.generate.dartGenerate.<id>` and `quickfix.dartGenerate`.
- Never enable the plugin in `~/Projects/darty`. Never commit a `plugins:` block in any repo. The tests write theirs into temporary folders.
- The `simple-english` hook lints each Markdown file that you write. Fix each problem that it reports.
- If a patch does not apply because a review fix changed the lines around it, make the same change by hand. The patch shows the result.

## File Structure

```
.gitignore                         gains the Node and VS Code build folders
README.md                          gains the extension section, loses the cmd+n binding
core/lib/src/outcome.dart          Reason gains message
plugin/lib/assists.dart            (new) the API for the helper
plugin/lib/src/assist.dart         four public fields, enclosingClass, public fieldNames
plugin/lib/src/assists.dart        a reason on each path, public isGenerated
plugin/test/assist_api_test.dart   (new) the four fields, outside the server
helper/                            (new) package dart_generate_helper
  pubspec.yaml
  analysis_options.yaml
  bin/helper.dart                  entry point: stdin, stdout and stderr
  lib/src/connection.dart          framing, the queue, cancellation, error codes
  lib/src/workspace.dart           analysis contexts, overlays, package files, SDK check
  lib/src/helper.dart              the request table and the one retry
  lib/src/actions.dart             the menu, the pickers, generate, composite actions
  lib/src/stale.dart               the stale-member scan (ADR 0008)
  test/client.dart                 a JSON-RPC client over the helper process
  test/connection_test.dart        the transport, in memory
  test/workspace_test.dart         the SDK version warning
  test/e2e_test.dart               every fixture marker through the helper
  test/cases_test.dart             the helper's own behavior
  test/cases/input/*.dart          case inputs
  test/cases/expected/*.dart       generated files that the cases compare
vscode/                            (new) the extension
  package.json
  package-lock.json
  tsconfig.json
  eslint.config.mjs
  .vscodeignore
  scripts/package.sh               builds the .vsix file and tests its helper mode
  src/protocol.ts                  message types, request params, workspace edits
  src/helper.ts                    the helper process and its restart policy
  src/sdk.ts                       the SDK path
  src/actions.ts                   Generate…, the code actions, quick fixes, pickers
  src/stale.ts                     the diagnostics
  src/extension.ts                 activate and register
  test/run.ts                      starts VS Code 1.139.1 with the suite
  test/stub/package.json           an empty extension for the test window
  test/workspace/                  the folder that the test window opens
  test/suite/*.ts                  the Mocha suite
```

Each Dart class uses a Dart 3.13 primary constructor where the code below has one. The helper imports the plugin only through `package:dart_generate/assists.dart`.

---

### Task 1: Give each Reason its menu message

**Files:**
- Modify: `core/lib/src/outcome.dart`
- Test: `core/test/outcome_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `Reason.message`, a `String`. The helper shows `'${r.message} (${r.name})'` beside a greyed-out action.

- [ ] **Step 1: Write the failing test**

Apply this patch from the repo root:

```bash
git apply <<'PATCH'
--- a/core/test/outcome_test.dart
+++ b/core/test/outcome_test.dart
@@ -18,4 +18,23 @@
     };
     expect(byOwner, {Owner.core: 6, Owner.adapter: 4});
   });
+
+  test('each reason has the message that the Generate… menu shows', () {
+    expect(
+      {for (final r in Reason.values) r.name: r.message},
+      {
+        'noFields': 'the class has no field that this action can use',
+        'noBuilder': 'no public constructor covers every field',
+        'mutableClass': 'a field is not final',
+        'typeParameterField': 'a field has a type parameter type',
+        'nestedCollection': 'a collection holds a collection',
+        'nonStringMapKey': 'a map key is not String',
+        'customToString': 'toString is hand-written',
+        'notConvertible': 'the constructor cannot move into the class header',
+        'publicNameTaken':
+            'the class already has a member with the public name',
+        'notAClass': 'the cursor is in an enum, a mixin or an extension type',
+      },
+    );
+  });
 }
PATCH
```

- [ ] **Step 2: Run the test to see it fail**

Run: `cd core && dart test test/outcome_test.dart`
Expected: FAIL with `Error: The getter 'message' isn't defined for the type 'Reason'.`

- [ ] **Step 3: Add the messages**

Apply this patch from the repo root:

```bash
git apply <<'PATCH'
--- a/core/lib/src/outcome.dart
+++ b/core/lib/src/outcome.dart
@@ -4,20 +4,32 @@
 
 /// Why an action is not offered. The README has one row per value.
 enum Reason {
-  noFields(Owner.core),
-  noBuilder(Owner.core),
-  mutableClass(Owner.core),
-  typeParameterField(Owner.core),
-  nestedCollection(Owner.core),
-  nonStringMapKey(Owner.core),
-  customToString(Owner.adapter),
-  notConvertible(Owner.adapter),
-  publicNameTaken(Owner.adapter),
-  notAClass(Owner.adapter);
+  noFields(Owner.core, 'the class has no field that this action can use'),
+  noBuilder(Owner.core, 'no public constructor covers every field'),
+  mutableClass(Owner.core, 'a field is not final'),
+  typeParameterField(Owner.core, 'a field has a type parameter type'),
+  nestedCollection(Owner.core, 'a collection holds a collection'),
+  nonStringMapKey(Owner.core, 'a map key is not String'),
+  customToString(Owner.adapter, 'toString is hand-written'),
+  notConvertible(
+    Owner.adapter,
+    'the constructor cannot move into the class header',
+  ),
+  publicNameTaken(
+    Owner.adapter,
+    'the class already has a member with the public name',
+  ),
+  notAClass(
+    Owner.adapter,
+    'the cursor is in an enum, a mixin or an extension type',
+  );
 
-  const Reason(this.owner);
+  const Reason(this.owner, this.message);
 
   final Owner owner;
+
+  /// Why the action is greyed out, as the VS Code menu shows it.
+  final String message;
 }
 
 /// What a generator returns.
PATCH
```

- [ ] **Step 4: Run the core package**

Run: `cd core && dart format --output=none --set-exit-if-changed . && dart analyze && dart test`
Expected: `No issues found!`, then `+51: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add core/lib/src/outcome.dart core/test/outcome_test.dart
git commit -m "Give each Reason the message that the Generate… menu shows

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Open the plugin to the helper

`GenerateAssist` gains `fields`, `anywhereInClass`, `reason` and `onError`, and the method `enclosingClass`. Each assist sets `reason` on each path that gives no edit for a known reason. `lib/assists.dart` exports what the helper needs. The server never sets the new fields, so the plugin e2e test passes unchanged.

**Files:**
- Create: `plugin/lib/assists.dart`
- Modify: `plugin/lib/src/assist.dart`, `plugin/lib/src/assists.dart`
- Test: `plugin/test/assist_api_test.dart`

**Interfaces:**
- Consumes: `Reason` from Task 1.
- Produces, through `package:dart_generate/assists.dart`:
  - `GenerateAssist`, with `Set<String>? fields`, `bool anywhereInClass`, `Reason? reason`, `void Function(String generator, String file, Object error, StackTrace stack) onError`, `String verb` and `ClassDeclaration? enclosingClass()`.
  - `List<(String, int)> fieldNames(ClassDeclaration cls)`: each field's name and name offset.
  - The six assists: `GenerateToString`, `GenerateEquality`, `GenerateCopyWith`, `GenerateJson`, `GenerateGetter`, `ConvertToPrimaryConstructor`. Each has the constructor `({required CorrectionProducerContext context})`.
  - `static bool GenerateToString.isGenerated(MethodDeclaration method, String className)`.
  - `generatorNames`, `ClassMember? findMember(ClassDeclaration cls, String name)`, `ClassModel readClass(ClassElement element, TypeSystem types)`.

- [ ] **Step 1: Write the failing test**

Create `plugin/test/assist_api_test.dart`:

```dart
/// The API that the VS Code helper uses: the four fields of GenerateAssist,
/// run outside the analysis server as the helper runs them.
library;

import 'dart:io';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:dart_generate/assists.dart';
import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

typedef Make = GenerateAssist Function({
  required CorrectionProducerContext context,
});

void main() {
  final dir = Directory(
    Directory.systemTemp
        .createTempSync('dart_generate_api_')
        .resolveSymbolicLinksSync(),
  );
  final collection = AnalysisContextCollection(includedPaths: [dir.path]);
  var files = 0;

  tearDownAll(() => dir.deleteSync(recursive: true));

  /// Runs [make] on [source] with the cursor at [at], and returns the
  /// assist and the source after its edits.
  Future<(GenerateAssist, String)> run(
    Make make,
    String source,
    String at, {
    Set<String>? fields,
    bool anywhere = false,
  }) async {
    final path = '${dir.path}/file${files++}.dart';
    File(path).writeAsStringSync(source);
    final session = collection.contextFor(path).currentSession;
    final library =
        await session.getResolvedLibrary(path) as ResolvedLibraryResult;
    final assist = make(
      context: CorrectionProducerContext.createResolved(
        libraryResult: library,
        unitResult: library.units.single,
        selectionOffset: source.indexOf(at),
      ),
    );
    assist
      ..fields = fields
      ..anywhereInClass = anywhere;
    final builder = ChangeBuilder(session: session);
    await assist.compute(builder);
    final edits = [for (final f in builder.sourceChange.edits) ...f.edits];
    return (assist, SourceEdit.applySequence(source, edits));
  }

  const point = '''
class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

  int get sum => x + y;
}
''';

  test('fields replaces the fields of the selection', () async {
    final (_, result) = await run(
      GenerateToString.new,
      point,
      'Point {',
      fields: {'y'},
    );
    expect(result, contains(r"String toString() => 'Point(y: $y)';"));
  });

  test('anywhereInClass accepts a position inside a method', () async {
    final (plain, before) = await run(GenerateToString.new, point, 'x + y');
    expect((before, plain.reason), (point, null));
    final (_, after) = await run(
      GenerateToString.new,
      point,
      'x + y',
      anywhere: true,
    );
    expect(after, contains('String toString()'));
  });

  test('reason names why an action gives no edit', () async {
    final (equality, _) = await run(
      GenerateEquality.new,
      'class Counter {\n  int count = 0;\n}\n',
      'Counter',
    );
    expect(equality.reason, Reason.mutableClass);
    final (inEnum, _) = await run(
      GenerateToString.new,
      'enum Size { small, large }\n',
      'small',
    );
    expect(inEnum.reason, Reason.notAClass);
    final (convert, _) = await run(
      ConvertToPrimaryConstructor.new,
      'class const Money(final int pence);\n',
      'Money',
    );
    expect(convert.reason, Reason.notConvertible);
  });

  test('onError receives a failure', () async {
    final failures = <String>[];
    final (_, result) = await run(
      ({required context}) {
        return _Broken(context: context)
          ..onError = (generator, file, error, stack) =>
              failures.add('$generator $error');
      },
      point,
      'Point {',
    );
    expect(result, point);
    expect(failures, ['generate.broken Bad state: broken']);
  });
}

/// An assist that always fails.
final class _Broken extends GenerateAssist {
  _Broken({required super.context});

  @override
  AssistKind get assistKind => AssistKind('generate.broken', 30, 'Broken');

  @override
  Future<void> generate(ChangeBuilder draft) async =>
      throw StateError('broken');
}
```

- [ ] **Step 2: Run the test to see it fail**

Run: `cd plugin && dart test test/assist_api_test.dart`
Expected: FAIL with `Error when reading 'lib/assists.dart': No such file or directory`

- [ ] **Step 3: Add the fields and the reasons**

Apply these two patches from the repo root:

```bash
git apply <<'PATCH'
--- a/plugin/lib/src/assist.dart
+++ b/plugin/lib/src/assist.dart
@@ -23,6 +23,22 @@
   /// `Generate`, or `Regenerate` when a member already exists.
   String verb = 'Generate';
 
+  /// The fields for toString and `==`, in place of the fields that the
+  /// selection covers. The VS Code helper sets it from its field picker.
+  Set<String>? fields;
+
+  /// Whether any position inside the class counts, not only the header, a
+  /// field or a selection. The VS Code helper sets it for an explicit choice.
+  bool anywhereInClass = false;
+
+  /// Why the action gives no edit. `null` when it gives an edit, or when it
+  /// does not apply at this position.
+  Reason? reason;
+
+  /// Receives a failure. The VS Code helper writes it to stderr.
+  void Function(String generator, String file, Object error, StackTrace stack)
+  onError = writeLog;
+
   @override
   CorrectionApplicability get applicability =>
       CorrectionApplicability.singleLocation;
@@ -57,21 +73,22 @@
     } catch (error, stack) {
       // This includes ConflictingEditException. The edits are built in the
       // draft, so a conflict comes from our own placement code: our bug.
-      writeLog(assistKind!.id, file, error, stack);
+      onError(assistKind!.id, file, error, stack);
     }
   }
 
   /// The class whose header or field the cursor is on, with its model.
   ///
   /// `null` when the cursor is anywhere else, or in an enum, mixin or
-  /// extension type (`notAClass`).
+  /// extension type (`notAClass`). With [anywhereInClass], any position in
+  /// the class counts.
   ClassTarget? classTarget() {
-    final cls = node.thisOrAncestorOfType<ClassDeclaration>();
+    final cls = enclosingClass();
     if (cls == null) return null;
     final element = cls.declaredFragment?.element;
     if (element == null) return null;
-    final names = _fieldNames(cls);
-    final only = selectionLength == 0
+    final names = fieldNames(cls);
+    final selected = selectionLength == 0
         ? null
         : {
             for (final (name, offset) in names)
@@ -81,27 +98,48 @@
     final onHeader =
         selectionOffset >= cls.offset && selectionOffset < bodyStart;
     final onField = node.thisOrAncestorOfType<FieldDeclaration>() != null;
-    if (!onHeader && !onField && (only == null || only.isEmpty)) return null;
+    final onSelection = selected != null && selected.isNotEmpty;
+    if (!anywhereInClass && !onHeader && !onField && !onSelection) return null;
     return ClassTarget(
       cls,
       readClass(element, typeSystem),
-      only == null || only.isEmpty ? null : only,
+      fields ?? (onSelection ? selected : null),
     );
   }
 
-  /// Writes [outcome] into [cls] and sets [verb].
+  /// The class around the cursor, or `null`. In an enum, a mixin or an
+  /// extension type, it sets [reason] to `notAClass`.
+  ClassDeclaration? enclosingClass() {
+    final cls = node.thisOrAncestorOfType<ClassDeclaration>();
+    if (cls == null &&
+        node.thisOrAncestorMatching(
+              (n) =>
+                  n is EnumDeclaration ||
+                  n is MixinDeclaration ||
+                  n is ExtensionTypeDeclaration,
+            ) !=
+            null) {
+      reason = Reason.notAClass;
+    }
+    return cls;
+  }
+
+  /// Writes [outcome] into [cls] and sets [verb], or sets [reason].
   Future<void> write(
     ChangeBuilder draft,
     ClassDeclaration cls,
     Outcome outcome,
   ) async {
-    if (outcome case Generated(:final members, :final imports)) {
-      await draft.addDartFileEdit(file, (b) {
-        if (writeMembers(b, cls, members)) verb = 'Regenerate';
-        for (final uri in imports) {
-          b.importLibrary(Uri.parse(uri));
-        }
-      });
+    switch (outcome) {
+      case Generated(:final members, :final imports):
+        await draft.addDartFileEdit(file, (b) {
+          if (writeMembers(b, cls, members)) verb = 'Regenerate';
+          for (final uri in imports) {
+            b.importLibrary(Uri.parse(uri));
+          }
+        });
+      case NotOffered(reason: final why):
+        reason = why;
     }
   }
 }
@@ -118,7 +156,7 @@
 /// The name and name offset of each field of the class: body fields, header
 /// fields, and header `this.` and `super.` parameters. A plain header
 /// parameter is not a field.
-List<(String, int)> _fieldNames(ClassDeclaration cls) => [
+List<(String, int)> fieldNames(ClassDeclaration cls) => [
   if (cls.namePart case PrimaryConstructorDeclaration(:final formalParameters))
     for (final p in formalParameters.parameters)
       if (p.name case final name?)
PATCH
```

```bash
git apply <<'PATCH'
--- a/plugin/lib/src/assists.dart
+++ b/plugin/lib/src/assists.dart
@@ -35,7 +35,8 @@
     if (target == null) return;
     // customToString: a hand-written toString is domain text. Keep it.
     if (findMember(target.node, 'toString') case final MethodDeclaration m
-        when !_isGenerated(m, target.model.name)) {
+        when !isGenerated(m, target.model.name)) {
+      reason = Reason.customToString;
       return;
     }
     await write(
@@ -47,7 +48,7 @@
 
   /// Whether [method] returns `'ClassName(field: ...`, the generated shape.
   /// `'Money(${format()})'` starts like it, but it is hand-written.
-  static bool _isGenerated(MethodDeclaration method, String className) {
+  static bool isGenerated(MethodDeclaration method, String className) {
     final body = method.body;
     if (body is! ExpressionFunctionBody) return false;
     final generated = RegExp(
@@ -87,7 +88,10 @@
     final target = classTarget();
     if (target == null) return;
     final outcome = generateCopyWith(target.model);
-    if (outcome is! Generated) return;
+    if (outcome is! Generated) {
+      reason = (outcome as NotOffered).reason;
+      return;
+    }
     final cls = target.node;
     final old = findMember(cls, 'copyWith');
     final unset = findMember(cls, '_unset');
@@ -140,7 +144,7 @@
 
   @override
   Future<void> generate(ChangeBuilder draft) async {
-    final cls = node.thisOrAncestorOfType<ClassDeclaration>();
+    final cls = enclosingClass();
     final element = cls?.declaredFragment?.element;
     if (cls == null || element == null) return;
 
@@ -171,6 +175,7 @@
     final public = publicName(name);
     if (element.getGetter(public) != null ||
         element.getMethod(public) != null) {
+      reason = Reason.publicNameTaken;
       return;
     }
 
@@ -196,17 +201,21 @@
 
   @override
   Future<void> generate(ChangeBuilder draft) async {
-    final cls = node.thisOrAncestorOfType<ClassDeclaration>();
+    final cls = enclosingClass();
     if (cls == null) return;
+    if (!anywhereInClass &&
+        (selectionOffset < cls.offset ||
+            selectionOffset >= cls.body.beginToken.offset)) {
+      return;
+    }
+    // notConvertible: a primary constructor exists, or the rules below
+    // reject the class.
     final namePart = cls.namePart;
-    if (namePart is! NameWithTypeParameters) return;
-    if (selectionOffset < cls.offset ||
-        selectionOffset >= cls.body.beginToken.offset) {
+    final plan = namePart is NameWithTypeParameters ? _plan(cls) : null;
+    if (namePart is! NameWithTypeParameters || plan == null) {
+      reason = Reason.notConvertible;
       return;
     }
-    // notConvertible: anything the rules below reject.
-    final plan = _plan(cls);
-    if (plan == null) return;
     final (:constructor, :params, :moved) = plan;
 
     final content = unitResult.content;
PATCH
```

- [ ] **Step 4: Add the API file**

Create `plugin/lib/assists.dart`:

```dart
/// The assists and the class reader, for the VS Code helper.
///
/// The analysis server loads `main.dart`, not this file.
library;

export 'src/assist.dart' show GenerateAssist, fieldNames;
export 'src/assists.dart';
export 'src/placement.dart' show findMember;
export 'src/read_class.dart' show readClass;
```

- [ ] **Step 5: Run the plugin package, with its e2e test**

Run: `cd plugin && dart format --output=none --set-exit-if-changed . && dart analyze && dart test`
Expected: `No issues found!`, then `+21: All tests passed!` The e2e test takes about 20 s with a warm plugin cache and minutes with a cold one.

- [ ] **Step 6: Commit**

```bash
git add plugin/lib/assists.dart plugin/lib/src/assist.dart plugin/lib/src/assists.dart plugin/test/assist_api_test.dart
git commit -m "Open the plugin's assists to the VS Code helper

GenerateAssist gains fields, anywhereInClass, reason and onError, and
enclosingClass. lib/assists.dart exports what the helper needs. The
server never sets the new fields, so the plugin behaves as before.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The helper package and its transport

The helper does not use `json_rpc_2`, because it gives a handler no request ID. So `$/cancelRequest` cannot find a waiting request. `Connection` frames the messages, runs them one at a time, and answers them.

**Files:**
- Create: `helper/pubspec.yaml`, `helper/analysis_options.yaml`, `helper/lib/src/connection.dart`
- Test: `helper/test/connection_test.dart`
- Generated: `helper/pubspec.lock`

**Interfaces:**
- Produces: `typedef Handler = Future<Object?> Function(String method, Map<String, Object?> params)`, and `Connection(Stream<List<int>> input, Sink<List<int>> output, Handler handle, {required void Function(String method, Object error, StackTrace stack) onError})` with `Future<void> get done`.
- Error codes: `-32800` for a cancelled request, `-32603` for a handler that throws.

- [ ] **Step 1: Create the package**

Create `helper/pubspec.yaml`:

```yaml
name: dart_generate_helper
description: The process that runs the dart_generate assists for VS Code.
publish_to: none

environment:
  sdk: ^3.13.0

# Pinned exactly, as in the plugin. Move all three together.
dependencies:
  analysis_server_plugin: 0.3.23
  analyzer: 14.4.0
  analyzer_plugin: 0.14.17
  dart_generate:
    path: ../plugin
  generate_core:
    path: ../core

dev_dependencies:
  lints: ^6.1.0
  test: ^1.31.0
```

Create `helper/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  # The cases are inputs and expected outputs, not code of this package.
  exclude:
    - test/cases/**
```

Run: `cd helper && dart pub get --offline`
Expected: `Changed 54 dependencies!` and a new `helper/pubspec.lock`.

- [ ] **Step 2: Write the failing test**

Create `helper/test/connection_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:dart_generate_helper/src/connection.dart';
import 'package:test/test.dart';

/// One framed message, as `vscode-jsonrpc` writes it.
List<int> frame(Map<String, Object?> message) {
  final body = utf8.encode(jsonEncode({'jsonrpc': '2.0', ...message}));
  return [...ascii.encode('Content-Length: ${body.length}\r\n\r\n'), ...body];
}

void main() {
  late StreamController<List<int>> input;
  late List<Map<String, Object?>> replies;
  late List<String> errors;
  late Completer<void> gate;

  setUp(() {
    input = StreamController<List<int>>();
    final output = StreamController<List<int>>();
    replies = [];
    errors = [];
    gate = Completer<void>();
    Connection(
      input.stream,
      output.sink,
      (method, params) async => switch (method) {
        'echo' => params['text'],
        'slow' => gate.future.then((_) => 'slow'),
        'fail' => throw StateError('broken'),
        _ => null,
      },
      onError: (method, error, stack) => errors.add('$method: $error'),
    );
    final buffer = <int>[];
    output.stream.listen((bytes) {
      buffer.addAll(bytes);
      while (true) {
        final text = latin1.decode(buffer);
        final headerEnd = text.indexOf('\r\n\r\n');
        if (headerEnd < 0) return;
        final length = int.parse(text.substring(16, headerEnd));
        if (buffer.length < headerEnd + 4 + length) return;
        final body = buffer.sublist(headerEnd + 4, headerEnd + 4 + length);
        buffer.removeRange(0, headerEnd + 4 + length);
        replies.add(jsonDecode(utf8.decode(body)) as Map<String, Object?>);
      }
    });
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'a message split across chunks, with UTF-8 text, gets its answer',
    () async {
      final bytes = frame({
        'id': 1,
        'method': 'echo',
        'params': {'text': 'Generate…'},
      });
      input
        ..add(bytes.sublist(0, 10))
        ..add(bytes.sublist(10, bytes.length - 3))
        ..add(bytes.sublist(bytes.length - 3));
      await settle();
      await settle();
      expect(replies, [
        {'jsonrpc': '2.0', 'id': 1, 'result': 'Generate…'},
      ]);
    },
  );

  test('requests answer in arrival order, one at a time', () async {
    input
      ..add(frame({'id': 1, 'method': 'slow'}))
      ..add(
        frame({
          'id': 2,
          'method': 'echo',
          'params': {'text': 'fast'},
        }),
      );
    await settle();
    expect(replies, isEmpty);
    gate.complete();
    await settle();
    await settle();
    expect([for (final r in replies) r['id']], [1, 2]);
  });

  test('a cancelled request that waits gets -32800', () async {
    input
      ..add(frame({'id': 1, 'method': 'slow'}))
      ..add(
        frame({
          'id': 2,
          'method': 'echo',
          'params': {'text': 'late'},
        }),
      )
      ..add(
        frame({
          'method': r'$/cancelRequest',
          'params': {'id': 2},
        }),
      );
    await settle();
    gate.complete();
    await settle();
    await settle();
    expect(replies[0]['result'], 'slow');
    expect(replies[1]['id'], 2);
    expect((replies[1]['error']! as Map)['code'], -32800);
  });

  test('a failing handler gets -32603 and reaches onError', () async {
    input.add(frame({'id': 7, 'method': 'fail'}));
    await settle();
    await settle();
    expect(replies.single['id'], 7);
    expect((replies.single['error']! as Map)['code'], -32603);
    expect(errors, ['fail: Bad state: broken']);
  });

  test('a notification gets no answer', () async {
    input.add(
      frame({
        'method': 'echo',
        'params': {'text': 'x'},
      }),
    );
    await settle();
    await settle();
    expect(replies, isEmpty);
  });
}
```

- [ ] **Step 3: Run the test to see it fail**

Run: `cd helper && dart test test/connection_test.dart`
Expected: FAIL with `Error when reading 'lib/src/connection.dart': No such file or directory`

- [ ] **Step 4: Write the connection**

Create `helper/lib/src/connection.dart`:

```dart
import 'dart:async';
import 'dart:convert';

/// Answers one request or notification: the method name and its params.
typedef Handler = Future<Object?> Function(
  String method,
  Map<String, Object?> params,
);

/// A JSON-RPC 2.0 connection with `Content-Length` framing, the format of
/// `vscode-jsonrpc`.
///
/// Messages run one at a time, in arrival order, so a new overlay never lands
/// while an older request resolves. `$/cancelRequest` skips a request that
/// still waits, and it gets the error code -32800.
final class Connection {
  Connection(
    Stream<List<int>> input,
    this._output,
    this._handle, {
    required this.onError,
  }) {
    input.listen(_onBytes, onDone: _closed.complete);
  }

  final Sink<List<int>> _output;
  final Handler _handle;

  /// Receives the failure of a handler. The connection answers the request
  /// with the error code -32603.
  final void Function(String method, Object error, StackTrace stack) onError;

  final _buffer = <int>[];
  final _closed = Completer<void>();

  /// The IDs of requests that wait in the queue.
  final _waiting = <Object>{};
  var _queue = Future<void>.value();

  /// Completes when the input closes and every queued message ran.
  Future<void> get done => _closed.future.then((_) => _queue);

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
    // A message without a method is a response. The helper sends no
    // requests, so it ignores responses.
    if (message['method'] case final String method) {
      final id = message['id'];
      final params = message['params'] as Map<String, Object?>? ?? const {};
      if (method == r'$/cancelRequest') {
        _waiting.remove(params['id']);
        return;
      }
      if (id != null) _waiting.add(id);
      _queue = _queue.then((_) => _run(id, method, params));
    }
  }

  Future<void> _run(
    Object? id,
    String method,
    Map<String, Object?> params,
  ) async {
    if (id != null && !_waiting.remove(id)) {
      _send({
        'id': id,
        'error': {'code': -32800, 'message': 'The request was cancelled.'},
      });
      return;
    }
    try {
      final result = await _handle(method, params);
      if (id != null) _send({'id': id, 'result': result});
    } catch (error, stack) {
      onError(method, error, stack);
      if (id != null) {
        _send({
          'id': id,
          'error': {'code': -32603, 'message': '$error'},
        });
      }
    }
  }

  void _send(Map<String, Object?> message) {
    final body = utf8.encode(jsonEncode({'jsonrpc': '2.0', ...message}));
    _output
      ..add(ascii.encode('Content-Length: ${body.length}\r\n\r\n'))
      ..add(body);
  }
}
```

- [ ] **Step 5: Run the helper package**

Run: `cd helper && dart format --output=none --set-exit-if-changed . && dart analyze && dart test`
Expected: `No issues found!`, then `+5: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add helper/pubspec.yaml helper/pubspec.lock helper/analysis_options.yaml helper/lib/src/connection.dart helper/test/connection_test.dart
git commit -m "Add the helper package and its JSON-RPC connection

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: The helper answers actions and generate

The helper resolves the request's file with its editor text on an overlay. Then it runs the six assists at the cursor and turns their results into the Generate… menu or the Cmd+. list. This task ends with every fixture marker running through the helper process.

**Files:**
- Create: `helper/lib/src/workspace.dart`, `helper/lib/src/actions.dart`, `helper/lib/src/helper.dart`, `helper/bin/helper.dart`
- Test: `helper/test/client.dart`, `helper/test/workspace_test.dart`, `helper/test/e2e_test.dart`, `helper/test/cases_test.dart`
- Test data: `helper/test/cases/input/gaps.dart`, `getters.dart`, `shapes.dart`, `colors.dart`, `paint.dart`, and `helper/test/cases/expected/gaps.dart`

**Interfaces:**
- Consumes: `Connection` from Task 3. From Task 2: `GenerateAssist` and its fields, the six assists, `fieldNames`, `findMember` and `readClass`.
- Produces:
  - `Workspace(String sdkPath, List<String> folders)` with `sdkWarning()`, `refresh()`, `pluginEnabled(path)`, `resolve(path, text)` returning `(ResolvedLibraryResult, ResolvedUnitResult)?`, `changed(paths)`, `closed(path)` and `dispose()`. Also `String? versionWarning(String sdk, String built)`.
  - `Document(library, unit, eol, onError)` with `Future<Result> run(String id, int offset, int length, {bool anywhere, Set<String>? fields})`.
  - `actions(Document doc, int offset, int length, {required bool explicit})`, and `generate(Document doc, String action, int offset, int length, List<String>? fields)`. Task 5 adds a `Resolve` parameter to `generate`.
  - `Helper(void Function(String line) log)` with `Future<Object?> handle(String method, Map<String, Object?> params)`.
  - The test helpers `Client`, `applyEdits` and `package` in `helper/test/client.dart`.
- The requests: `initialize {sdkPath, folders}` gives `{warning}`. `actions {path, text, eol, offset, length, explicit}` gives a list of `{id, title, disabledReason, edits?, replaces?, pick?}`. `generate {…, action, fields}` gives `{edits, replaces, skipped}`. The notifications are `filesChanged {paths}` and `closed {path}`.

- [ ] **Step 1: Write the test client**

Create `helper/test/client.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A JSON-RPC client over the helper's stdin and stdout, with its stderr
/// kept for the checks.
final class Client {
  Client._(this._process) {
    _process.stdout.listen(_onBytes);
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(log.add);
    _process.exitCode.then(_onExit);
  }

  final Process _process;
  final _pending = <int, Completer<Object?>>{};
  final _buffer = <int>[];
  var _nextId = 0;
  StateError? _exited;

  /// The helper's stderr lines.
  final log = <String>[];

  /// The SDK of the Dart that runs the tests.
  static final sdkPath = File(Platform.resolvedExecutable).parent.parent.path;

  /// Starts `bin/helper.dart` and initializes it on [folders].
  static Future<Client> start(List<String> folders) async {
    final process = await Process.start(Platform.resolvedExecutable, [
      'bin/helper.dart',
    ]);
    final client = Client._(process);
    await client.request('initialize', {
      'sdkPath': sdkPath,
      'folders': folders,
    });
    return client;
  }

  Future<Object?> request(String method, Map<String, Object?> params) {
    if (_exited case final error?) return Future.error(error);
    final id = ++_nextId;
    final completer = _pending[id] = Completer<Object?>();
    _send({'id': id, 'method': method, 'params': params});
    return completer.future;
  }

  void notify(String method, Map<String, Object?> params) =>
      _send({'method': method, 'params': params});

  Future<void> stop() async {
    await _process.stdin.close();
    await _process.exitCode;
  }

  void _send(Map<String, Object?> message) {
    final body = utf8.encode(jsonEncode({'jsonrpc': '2.0', ...message}));
    _process.stdin
      ..add(ascii.encode('Content-Length: ${body.length}\r\n\r\n'))
      ..add(body);
  }

  void _onExit(int code) {
    final error = _exited = StateError('The helper exited with code $code.');
    for (final completer in _pending.values) {
      completer.completeError(error);
    }
    _pending.clear();
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
      final message = jsonDecode(body) as Map<String, Object?>;
      final completer = _pending.remove(message['id']);
      if (message['error'] case final error?) {
        completer?.completeError(StateError('helper error: $error'));
      } else {
        completer?.complete(message['result']);
      }
    }
  }
}

/// Applies `{offset, length, text}` edits to [text].
String applyEdits(String text, Object? edits) {
  final list = [
    for (final e in edits! as List<Object?>) e! as Map<String, Object?>,
  ]..sort((a, b) => (b['offset']! as int).compareTo(a['offset']! as int));
  var result = text;
  for (final e in list) {
    final offset = e['offset']! as int;
    result = result.replaceRange(
      offset,
      offset + (e['length']! as int),
      e['text']! as String,
    );
  }
  return result;
}

/// A temporary package with [files] under `lib/`, after `dart pub get`.
Future<Directory> package(
  Map<String, String> files, {
  String options = '',
}) async {
  final root = Directory.systemTemp.createTempSync('dart_generate_helper_');
  final dir = Directory(root.resolveSymbolicLinksSync());
  Directory('${dir.path}/lib').createSync();
  for (final MapEntry(:key, :value) in files.entries) {
    File('${dir.path}/lib/$key').writeAsStringSync(value);
  }
  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: cases
environment:
  sdk: ^3.13.0
dependencies:
  collection: ^1.19.1
''');
  if (options.isNotEmpty) {
    File('${dir.path}/analysis_options.yaml').writeAsStringSync(options);
  }
  final pubGet = await Process.run(Platform.resolvedExecutable, [
    'pub',
    'get',
    '--offline',
  ], workingDirectory: dir.path);
  if (pubGet.exitCode != 0) {
    throw StateError('dart pub get failed:\n${pubGet.stdout}${pubGet.stderr}');
  }
  return dir;
}
```

- [ ] **Step 2: Write the failing tests**

Create `helper/test/workspace_test.dart`:

```dart
import 'package:dart_generate_helper/src/workspace.dart';
import 'package:test/test.dart';

void main() {
  const built =
      '3.13.2 (stable) (Tue Aug 25 01:01:12 2026 -0700) on "macos_arm64"';

  test('a patch release gives no warning', () {
    expect(versionWarning('3.13.5\n', built), isNull);
  });

  test('another minor version gives the rebuild warning', () {
    expect(
      versionWarning('3.14.0\n', built),
      'Dart Generate was built for Dart 3.13 and your SDK is 3.14. '
      'Rebuild the extension.',
    );
  });
}
```

Create `helper/test/e2e_test.dart`. It imports the plugin's marker parser by a relative path, so both e2e tests read the markers the same way.

```dart
/// Runs every fixture marker through the helper process, as the plugin e2e
/// test runs them through the analysis server.
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../plugin/test/markers.dart';
import 'client.dart';

final _input = Directory('../fixtures/input');
final _expected = Directory('../fixtures/lib');

void main() {
  final names = [
    for (final f in _input.listSync().whereType<File>())
      if (f.path.endsWith('.dart')) f.uri.pathSegments.last,
  ]..sort();
  late Directory root;
  late Client helper;

  setUpAll(() async {
    root = await package({
      for (final name in names)
        name: File('${_input.path}/$name').readAsStringSync(),
    });
    helper = await Client.start([root.path]);
  });

  tearDownAll(() async {
    await helper.stop();
    root.deleteSync(recursive: true);
  });

  Future<List<Map<String, Object?>>> actions(
    String path,
    String text,
    (int, int) selection, {
    required bool explicit,
  }) async {
    final (start, end) = selection;
    final result = await helper.request('actions', {
      'path': path,
      'text': text,
      'eol': '\n',
      'offset': start,
      'length': end - start,
      'explicit': explicit,
    });
    return [
      for (final a in result! as List<Object?>) a! as Map<String, Object?>,
    ];
  }

  for (final name in names) {
    test(name, () async {
      final path = '${root.path}/lib/$name';
      var text = File(path).readAsStringSync();
      final markers = parseMarkers(text);
      for (final marker in markers.where((m) => m.expected)) {
        for (final generator in marker.names) {
          final found = await actions(
            path,
            text,
            target(text, marker),
            explicit: false,
          );
          final action = found.where((a) => a['id'] == generator).firstOrNull;
          if (action == null) {
            fail('$name: marker ${marker.index}: no $generator');
          }
          final fixed = switch (generator) {
            'getter' => 'Generate getter',
            'primaryConstructor' => 'Convert to primary constructor',
            _ => null,
          };
          expect(
            action['title'],
            fixed ?? startsWith('${marker.verb} '),
            reason: '$name: marker ${marker.index}: $generator title',
          );
          expect(
            action['replaces'],
            marker.verb == 'Regenerate' || generator == 'primaryConstructor',
            reason: '$name: marker ${marker.index}: $generator replaces',
          );
          text = applyEdits(text, action['edits']);
        }
      }
      for (final marker in markers.where((m) => !m.expected)) {
        final selection = target(text, marker);
        final generator = marker.names.single;
        final quiet = await actions(path, text, selection, explicit: false);
        expect(
          quiet.map((a) => a['id']),
          isNot(contains(generator)),
          reason: '$name: marker ${marker.index}: Cmd+. shows $generator',
        );
        final menu = await actions(path, text, selection, explicit: true);
        final action = menu.firstWhere((a) => a['id'] == generator);
        expect(
          action['disabledReason'],
          endsWith('(${marker.reason})'),
          reason: '$name: marker ${marker.index}: $generator reason',
        );
      }
      expect(text, File('${_expected.path}/$name').readAsStringSync());
    });
  }

  test('the helper logged no error', () {
    expect(helper.log.where((l) => l.startsWith('ERROR')), isEmpty);
  });
}
```

Create `helper/test/cases_test.dart`:

```dart
/// The helper's own behavior: pickers, composite actions, stale members,
/// plugin folders and files from disk. Inputs are in `test/cases/input/`.
///
/// `DART_GENERATE_UPDATE=1` writes each generated file to
/// `test/cases/expected/` instead of comparing: review that diff.
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:test/test.dart';

import 'client.dart';

final _update = Platform.environment['DART_GENERATE_UPDATE'] == '1';

String _input(String name) => File('test/cases/input/$name').readAsStringSync();

void _expect(String name, String actual) {
  final file = File('test/cases/expected/$name');
  if (_update) {
    file.writeAsStringSync(actual);
  } else {
    expect(actual, file.readAsStringSync());
  }
}

void main() {
  late Directory root;
  late Directory plugin;
  late Client helper;

  setUpAll(() async {
    root = await package({
      for (final f in Directory(
        'test/cases/input',
      ).listSync().whereType<File>())
        f.uri.pathSegments.last: f.readAsStringSync(),
    });
    // The options name the plugin. The helper only reads the name, so the
    // path does not need to exist.
    plugin = await package({
      'gaps.dart': _input('gaps.dart'),
    }, options: 'plugins:\n  dart_generate:\n    path: /nowhere\n');
    helper = await Client.start([root.path, plugin.path]);
  });

  tearDownAll(() async {
    await helper.stop();
    root.deleteSync(recursive: true);
    plugin.deleteSync(recursive: true);
  });

  String path(String name) => '${root.path}/lib/$name';

  Future<List<Map<String, Object?>>> actions(
    String file,
    String text,
    int offset, {
    int length = 0,
    required bool explicit,
  }) async {
    final result = await helper.request('actions', {
      'path': file,
      'text': text,
      'eol': '\n',
      'offset': offset,
      'length': length,
      'explicit': explicit,
    });
    return [
      for (final a in result! as List<Object?>) a! as Map<String, Object?>,
    ];
  }

  Future<Map<String, Object?>> generate(
    String name,
    String text,
    String action,
    int offset, {
    List<String>? fields,
  }) async =>
      (await helper.request('generate', {
            'path': path(name),
            'text': text,
            'eol': '\n',
            'offset': offset,
            'length': 0,
            'action': action,
            'fields': fields,
          }))!
          as Map<String, Object?>;

  Map<String, Object?> byId(List<Map<String, Object?>> list, String id) =>
      list.firstWhere((a) => a['id'] == id);

  test(
    'Generate… lists every action in menu order, from inside a method',
    () async {
      final text = _input('gaps.dart');
      final menu = await actions(
        path('gaps.dart'),
        text,
        text.indexOf('width *'),
        explicit: true,
      );
      expect(
        [for (final a in menu) a['id']],
        [
          'dataClass',
          'toString',
          'equality',
          'copyWith',
          'json',
          'getter',
          'primaryConstructor',
        ],
      );
      expect(
        [for (final a in menu) a['title']],
        [
          'Generate data class',
          'Generate toString()…',
          'Generate ==() and hashCode…',
          'Generate copyWith()',
          'Generate toJson() and fromJson()',
          'Generate getter…',
          'Convert to primary constructor',
        ],
      );
      expect(byId(menu, 'toString')['pick'], {
        'fields': [
          {'name': 'width', 'type': 'int'},
          {'name': 'height', 'type': 'int'},
          {'name': 'depth', 'type': 'int'},
        ],
        'ticked': ['width', 'height', 'depth'],
      });
      expect(
        byId(menu, 'getter')['disabledReason'],
        'the class has no field that this action can use (noFields)',
      );
      expect(byId(menu, 'primaryConstructor')['disabledReason'], isNull);
    },
  );

  test('toString with picked fields that have a gap', () async {
    final text = _input('gaps.dart');
    final result = await generate(
      'gaps.dart',
      text,
      'toString',
      text.indexOf('width *'),
      fields: ['width', 'depth'],
    );
    expect(result['replaces'], false);
    _expect('gaps.dart', applyEdits(text, result['edits']));
  });

  test('the getter picker lists private fields without a getter', () async {
    final text = _input('getters.dart');
    final menu = await actions(
      path('getters.dart'),
      text,
      text.indexOf('Counter'),
      explicit: false,
    );
    expect(byId(menu, 'getter'), {
      'id': 'getter',
      'title': 'Generate getter…',
      'disabledReason': null,
      'pick': {
        'fields': [
          {'name': '_count', 'type': 'int'},
          {'name': '_step', 'type': 'int'},
        ],
        'ticked': <String>[],
      },
    });
  });

  test(
    'in an enum every action is greyed out, outside a class none shows',
    () async {
      final text = _input('shapes.dart');
      final menu = await actions(
        path('shapes.dart'),
        text,
        text.indexOf('circle,'),
        explicit: true,
      );
      expect(menu, hasLength(7));
      for (final a in menu) {
        expect(
          a['disabledReason'],
          'the cursor is in an enum, a mixin or an extension type (notAClass)',
          reason: '${a['id']}',
        );
      }
      expect(
        await actions(path('shapes.dart'), text, 0, explicit: true),
        isEmpty,
      );
    },
  );

  test('a plugin folder hides Cmd+. actions and keeps Generate…', () async {
    final file = '${plugin.path}/lib/gaps.dart';
    final text = _input('gaps.dart');
    final at = text.indexOf('Box');
    expect(await actions(file, text, at, explicit: false), isEmpty);
    expect(await actions(file, text, at, explicit: true), hasLength(7));
    // A changed analysis_options.yaml rebuilds the analysis.
    File('${plugin.path}/analysis_options.yaml').writeAsStringSync('');
    expect(await actions(file, text, at, explicit: false), isNotEmpty);
  });

  test(
    'other files: an overlay stays until closed, disk after filesChanged',
    () async {
      final paint = _input('paint.dart');
      Future<String> toJson() async {
        final result = await generate(
          'paint.dart',
          paint,
          'json',
          paint.indexOf('Paint'),
        );
        return applyEdits(paint, result['edits']);
      }

      expect(await toJson(), contains("'color': color.name"));
      // A request for colors.dart puts its editor text on the overlay.
      await actions(
        path('colors.dart'),
        'class Color {\n  String toJson() => "";\n}\n',
        0,
        explicit: false,
      );
      expect(await toJson(), contains("'color': color.toJson()"));
      helper.notify('closed', {'path': path('colors.dart')});
      expect(await toJson(), contains("'color': color.name"));
      File(path('colors.dart'))
          .writeAsStringSync('class Color {\n  String toJson() => "";\n}\n');
      helper.notify('filesChanged', {
        'paths': [path('colors.dart')],
      });
      expect(await toJson(), contains("'color': color.toJson()"));
    },
  );

  test('the helper logged no error', () {
    expect(helper.log.where((l) => l.startsWith('ERROR')), isEmpty);
  });
}
```

- [ ] **Step 3: Write the case inputs and the expected file**

Create `helper/test/cases/input/gaps.dart`:

```dart
class Box {
  final int width;
  final int height;
  final int depth;

  const Box(this.width, this.height, this.depth);

  int get volume => width * height * depth;
}
```

Create `helper/test/cases/input/getters.dart`:

```dart
class Counter {
  int _count = 0;
  String _label;
  int _step;

  Counter(this._label, this._step);

  String get label => _label;
}
```

Create `helper/test/cases/input/shapes.dart`:

```dart
import 'dart:math';

enum Shape { circle, square }

class Circle {
  final double radius;

  const Circle(this.radius);

  double get area => pi * radius * radius;
}
```

Create `helper/test/cases/input/colors.dart`:

```dart
enum Color { red, green }
```

Create `helper/test/cases/input/paint.dart`:

```dart
import 'colors.dart';

class Paint {
  final Color color;

  const Paint({required this.color});
}
```

Create `helper/test/cases/expected/gaps.dart`:

```dart
class Box {
  final int width;
  final int height;
  final int depth;

  const Box(this.width, this.height, this.depth);

  int get volume => width * height * depth;

  @override
  String toString() => 'Box(width: $width, depth: $depth)';
}
```

- [ ] **Step 4: Run the tests to see them fail**

Run: `cd helper && dart test`
Expected: FAIL. `workspace_test.dart` fails with `Error when reading 'lib/src/workspace.dart'`. The e2e and case tests fail with `The helper exited with code 254.`, because `bin/helper.dart` does not exist yet.

- [ ] **Step 5: Write the workspace**

Create `helper/lib/src/workspace.dart`:

```dart
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
// pluginConfigurations has no public getter.
// ignore: implementation_imports
import 'package:analyzer/src/analysis_options/analysis_options.dart';

/// The analysis of the workspace folders, with the editor's text on top.
final class Workspace {
  Workspace(this.sdkPath, this.folders) {
    _collection = _open();
    _stamps = _readStamps();
  }

  final String sdkPath;
  final List<String> folders;

  final _provider = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

  late AnalysisContextCollection _collection;

  /// The modification time of each package file when [_collection] was built.
  Map<String, DateTime?> _stamps = const {};

  /// The text of each overlay.
  final _texts = <String, String>{};
  var _stamp = 0;

  AnalysisContextCollection _open() => AnalysisContextCollection(
    includedPaths: folders,
    resourceProvider: _provider,
    sdkPath: sdkPath,
  );

  /// The warning for an SDK that the helper was not built for, or `null`.
  String? sdkWarning() => versionWarning(
    File('$sdkPath/version').readAsStringSync(),
    Platform.version,
  );

  /// Rebuilds the collection when a package file changed. The helper calls
  /// it before each request. A file watcher can miss a change under
  /// `.dart_tool/`.
  Future<void> refresh() async {
    final stamps = _readStamps();
    final changed =
        stamps.length != _stamps.length ||
        stamps.entries.any((e) => _stamps[e.key] != e.value);
    if (!changed) return;
    await _collection.dispose();
    _collection = _open();
    _stamps = _readStamps();
    _texts.clear();
  }

  Map<String, DateTime?> _readStamps() => {
    for (final context in _collection.contexts)
      for (final name in [
        '.dart_tool/package_config.json',
        'analysis_options.yaml',
      ])
        '${context.contextRoot.root.path}/$name': _modified(
          '${context.contextRoot.root.path}/$name',
        ),
  };

  static DateTime? _modified(String path) {
    final stat = FileStat.statSync(path);
    return stat.type == FileSystemEntityType.notFound ? null : stat.modified;
  }

  AnalysisContext? _contextFor(String path) {
    try {
      return _collection.contextFor(path);
    } on StateError {
      // Outside every folder, or excluded by analysis_options.yaml.
      return null;
    }
  }

  /// Whether the analysis options at the root of [path]'s package or
  /// workspace enable the dart_generate plugin.
  bool pluginEnabled(String path) {
    final context = _contextFor(path);
    if (context == null) return false;
    final root = context.contextRoot.root.path;
    final options = context.getAnalysisOptionsForFile(
      _provider.getFile('$root/pubspec.yaml'),
    );
    return (options as AnalysisOptionsImpl).pluginConfigurations.any(
      (c) => c.name == 'dart_generate',
    );
  }

  /// Resolves the library of [path] with [text] as its content, or `null`
  /// when no folder analyzes [path].
  Future<(ResolvedLibraryResult, ResolvedUnitResult)?> resolve(
    String path,
    String text,
  ) async {
    final context = _contextFor(path);
    if (context == null) return null;
    if (_texts[path] != text) {
      _texts[path] = text;
      _provider.setOverlay(path, content: text, modificationStamp: ++_stamp);
      context.changeFile(path);
    }
    await context.applyPendingFileChanges();
    final library = await context.currentSession.getResolvedLibraryContaining(
      path,
    );
    if (library is! ResolvedLibraryResult) return null;
    return (library, library.units.firstWhere((u) => u.path == path));
  }

  /// Reads [paths] from disk again.
  Future<void> changed(List<String> paths) async {
    for (final context in _collection.contexts) {
      for (final path in paths) {
        context.changeFile(path);
      }
      await context.applyPendingFileChanges();
    }
  }

  /// Drops the overlay of [path], so its text comes from disk again.
  Future<void> closed(String path) async {
    _texts.remove(path);
    _provider.removeOverlay(path);
    await changed([path]);
  }

  Future<void> dispose() => _collection.dispose();
}

/// The warning when [sdk] and [built] differ in the major or minor version,
/// or `null`. [built] is `Platform.version` of the helper, such as
/// `3.13.2 (stable) (...) on "macos_arm64"`.
String? versionWarning(String sdk, String built) {
  String minor(String v) => v.trim().split(RegExp(r'[ .]')).take(2).join('.');
  if (minor(sdk) == minor(built)) return null;
  return 'Dart Generate was built for Dart ${minor(built)} and your SDK is '
      '${minor(sdk)}. Rebuild the extension.';
}
```

- [ ] **Step 6: Write the actions**

Create `helper/lib/src/actions.dart`:

```dart
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:dart_generate/assists.dart';
import 'package:generate_core/generate_core.dart';

/// Receives the failure of an assist.
typedef OnError = void Function(
  String generator,
  String file,
  Object error,
  StackTrace stack,
);

const internalError = 'internal error: see Output › Dart Generate';

/// The assists, by action ID, in menu order.
final _assists =
    <
      String,
      GenerateAssist Function({required CorrectionProducerContext context})
    >{
      'toString': GenerateToString.new,
      'equality': GenerateEquality.new,
      'copyWith': GenerateCopyWith.new,
      'json': GenerateJson.new,
      'getter': GenerateGetter.new,
      'primaryConstructor': ConvertToPrimaryConstructor.new,
    };

/// The steps of "Generate data class", in order, with the names that a
/// skipped-step message uses.
const _steps = {
  'toString': 'toString()',
  'equality': '==() and hashCode',
  'copyWith': 'copyWith()',
  'json': 'JSON',
};

/// What one assist gives at one position.
final class Result(
  final GenerateAssist assist,
  final List<SourceEdit> edits,
  final bool failed,
) {
  String get title => assist.assistKind!.message.replaceAll('{0}', assist.verb);

  bool get regenerates => assist.verb == 'Regenerate';

  /// The greyed-out text, or `null` when the action gives an edit or does
  /// not apply here.
  String? get disabled => failed
      ? internalError
      : switch (assist.reason) {
          final r? => describe(r),
          null => null,
        };
}

/// The reason text that the menu shows: `a field is not final (mutableClass)`.
String describe(Reason r) => '${r.message} (${r.name})';

/// One request's file, resolved, with its line ending.
final class Document(
  final ResolvedLibraryResult library,
  final ResolvedUnitResult unit,
  final String eol,
  final OnError onError,
) {
  /// Runs the assist of [id] at [offset] and [length].
  Future<Result> run(
    String id,
    int offset,
    int length, {
    bool anywhere = false,
    Set<String>? fields,
  }) async {
    var failed = false;
    final assist = _assists[id]!(
      context: CorrectionProducerContext.createResolved(
        libraryResult: library,
        unitResult: unit,
        selectionOffset: offset,
        selectionLength: length,
      ),
    );
    assist
      ..anywhereInClass = anywhere
      ..fields = fields
      ..onError = (generator, file, error, stack) {
        failed = true;
        onError(generator, file, error, stack);
      };
    final builder = ChangeBuilder(session: unit.session, defaultEol: eol);
    await assist.compute(builder);
    final edits = [for (final f in builder.sourceChange.edits) ...f.edits];
    return Result(assist, edits, failed);
  }
}

/// The actions at [offset], in menu order. Empty when the offset is not in
/// a class, an enum, a mixin or an extension type.
///
/// [explicit] is a Generate… request: every action shows, greyed out with
/// its reason when it gives no edit, and toString and `==` open a picker.
/// Otherwise (Cmd+.) only the actions that give an edit show.
Future<List<Map<String, Object?>>> actions(
  Document doc,
  int offset,
  int length, {
  required bool explicit,
}) async {
  final results = {
    for (final id in _assists.keys)
      id: await doc.run(id, offset, length, anywhere: explicit),
  };
  if (results.values.every(
    (r) => r.edits.isEmpty && r.assist.reason == null && !r.failed,
  )) {
    return const [];
  }
  final cls = _classAt(doc.unit, offset);
  final element = cls?.declaredFragment?.element;
  final out = <Map<String, Object?>>[];

  // "Generate data class" carries no edit: choosing it sends `generate`.
  final steps = [for (final id in _steps.keys) results[id]!];
  final applies = steps.any((r) => r.edits.isNotEmpty);
  if (explicit || applies) {
    final reasons = {for (final r in steps) r.disabled};
    out.add({
      'id': 'dataClass',
      'title':
          '${steps.any((r) => r.regenerates) ? 'Regenerate' : 'Generate'} '
          'data class',
      'disabledReason': applies
          ? null
          : reasons.length == 1
          ? reasons.single
          : 'no step applies',
    });
  }

  for (final id in ['toString', 'equality']) {
    final r = results[id]!;
    if (explicit) {
      out.add({
        'id': id,
        'title': '${r.title}…',
        'disabledReason': r.disabled,
        if (r.disabled == null && cls != null && element != null)
          'pick': _pick(cls, element, doc.unit, offset, length),
      });
    } else if (r.edits.isNotEmpty) {
      out.add(_withEdits(id, r));
    }
  }

  for (final id in ['copyWith', 'json']) {
    final r = results[id]!;
    if (explicit || r.edits.isNotEmpty) out.add(_withEdits(id, r));
  }

  // The getter: at once for the private field under the cursor, or with a
  // picker from the class header or from Generate….
  final getter = results['getter']!;
  final onField =
      getter.edits.isNotEmpty ||
      getter.assist.reason == Reason.publicNameTaken ||
      getter.failed;
  final onHeader =
      cls != null &&
      offset >= cls.offset &&
      offset < cls.body.beginToken.offset;
  if (onField) {
    if (explicit || getter.edits.isNotEmpty) {
      out.add(_withEdits('getter', getter));
    }
  } else if (cls != null && element != null && (explicit || onHeader)) {
    final fields = _getterFields(cls, element);
    if (explicit || fields.isNotEmpty) {
      final anyPrivate = fieldNames(cls).any((f) => f.$1.startsWith('_'));
      out.add({
        'id': 'getter',
        'title': 'Generate getter…',
        'disabledReason': fields.isNotEmpty
            ? null
            : describe(anyPrivate ? Reason.publicNameTaken : Reason.noFields),
        if (fields.isNotEmpty)
          'pick': {
            'fields': [
              for (final (name, type) in fields) {'name': name, 'type': type},
            ],
            'ticked': const <String>[],
          },
      });
    }
  } else if (explicit) {
    out.add(_withEdits('getter', getter));
  }

  final convert = results['primaryConstructor']!;
  if (explicit || convert.edits.isNotEmpty) {
    out.add(_withEdits('primaryConstructor', convert));
  }
  return out;
}

Map<String, Object?> _withEdits(String id, Result r) => {
  'id': id,
  'title': r.title,
  'disabledReason': r.disabled,
  'edits': _encode(r.edits),
  'replaces': r.regenerates || id == 'primaryConstructor',
};

/// [edits] as the JSON that the extension reads.
List<Map<String, Object?>> _encode(List<SourceEdit> edits) => [
  for (final e in edits)
    {'offset': e.offset, 'length': e.length, 'text': e.replacement},
];

/// The picker of toString or `==`: the fields that the action can use, and
/// the ones ticked at the start. A selection ticks the fields that it
/// covers. Otherwise every field is ticked.
Map<String, Object?> _pick(
  ClassDeclaration cls,
  ClassElement element,
  ResolvedUnitResult unit,
  int offset,
  int length,
) {
  final fields = usedFields(readClass(element, unit.typeSystem), null);
  final names = {for (final f in fields) f.name};
  final selected = {
    for (final (name, at) in fieldNames(cls))
      if (length > 0 && at >= offset && at < offset + length) name,
  }.intersection(names);
  final ticked = selected.isNotEmpty ? selected : names;
  return {
    'fields': [
      for (final f in fields) {'name': f.name, 'type': f.type.code},
    ],
    'ticked': [
      for (final f in fields)
        if (ticked.contains(f.name)) f.name,
    ],
  };
}

/// The private fields of [cls] that have no public getter yet, with their
/// types, in declaration order.
List<(String, String)> _getterFields(
  ClassDeclaration cls,
  ClassElement element,
) {
  final seen = <String>{};
  return [
    for (final (name, _) in fieldNames(cls))
      if (name.startsWith('_') && seen.add(name))
        if (element.getField(name) case final field?)
          if (element.getGetter(publicName(name)) == null &&
              element.getMethod(publicName(name)) == null)
            (name, field.type.getDisplayString()),
  ];
}

/// Runs [action] as an explicit choice: a picker result or a quick fix.
/// [fields] are the picked fields.
Future<Map<String, Object?>> generate(
  Document doc,
  String action,
  int offset,
  int length,
  List<String>? fields,
) async {
  final r = await doc.run(
    action,
    offset,
    length,
    anywhere: true,
    fields: fields?.toSet(),
  );
  return {
    'edits': _encode(r.edits),
    'replaces': r.regenerates || action == 'primaryConstructor',
    'skipped': [
      if (r.edits.isEmpty && r.disabled != null)
        '${_steps[action] ?? action}: ${r.disabled}',
    ],
  };
}

ClassDeclaration? _classAt(ResolvedUnitResult unit, int offset) => unit.unit
    .nodeCovering(offset: offset)
    ?.thisOrAncestorOfType<ClassDeclaration>();
```

- [ ] **Step 7: Write the request table and the entry point**

Create `helper/lib/src/helper.dart`:

```dart
import 'package:analyzer/dart/analysis/session.dart';

import 'actions.dart';
import 'workspace.dart';

/// The requests and notifications of the helper.
final class Helper(
  /// Writes one log line to stderr.
  final void Function(String line) log,
) {
  Workspace? _workspace;

  Workspace get _ready =>
      _workspace ?? (throw StateError('initialize has not run'));

  /// Answers [method]. A request that meets a changed file while it resolves
  /// runs once more.
  Future<Object?> handle(String method, Map<String, Object?> params) async {
    try {
      return await _handle(method, params);
    } on InconsistentAnalysisException {
      return _handle(method, params);
    }
  }

  Future<Object?> _handle(String method, Map<String, Object?> p) async {
    if (method != 'initialize') await _ready.refresh();
    switch (method) {
      case 'initialize':
        await _workspace?.dispose();
        final workspace = _workspace = Workspace(p['sdkPath']! as String, [
          for (final f in p['folders']! as List<Object?>) f! as String,
        ]);
        log('initialize: ${workspace.folders.join(', ')}');
        return {'warning': workspace.sdkWarning()};
      case 'actions':
        final path = p['path']! as String;
        final explicit = p['explicit']! as bool;
        // Under a root that enables the plugin, Cmd+. shows the plugin's
        // actions. Generate… still works there.
        if (!explicit && _ready.pluginEnabled(path)) return const <Object?>[];
        final doc = await _document(p);
        if (doc == null) return const <Object?>[];
        return actions(
          doc,
          p['offset']! as int,
          p['length']! as int,
          explicit: explicit,
        );
      case 'generate':
        final doc = await _document(p);
        if (doc == null) {
          return {
            'edits': const <Object?>[],
            'replaces': false,
            'skipped': const <Object?>[],
          };
        }
        return generate(
          doc,
          p['action']! as String,
          p['offset']! as int,
          p['length']! as int,
          switch (p['fields']) {
            final List<Object?> list => [for (final f in list) f! as String],
            _ => null,
          },
        );
      case 'filesChanged':
        await _ready.changed([
          for (final f in p['paths']! as List<Object?>) f! as String,
        ]);
        return null;
      case 'closed':
        await _ready.closed(p['path']! as String);
        return null;
      default:
        throw UnsupportedError('unknown method $method');
    }
  }

  Future<Document?> _document(Map<String, Object?> p) async {
    final resolved = await _ready.resolve(
      p['path']! as String,
      p['text']! as String,
    );
    if (resolved == null) return null;
    return Document(
      resolved.$1,
      resolved.$2,
      p['eol']! as String,
      (generator, file, error, stack) =>
          log('ERROR $generator $file\n$error\n$stack'),
    );
  }
}
```

Create `helper/bin/helper.dart`:

```dart
import 'dart:io';

import 'package:dart_generate_helper/src/connection.dart';
import 'package:dart_generate_helper/src/helper.dart';

/// The dart_generate helper for VS Code: JSON-RPC over stdin and stdout, and
/// the log on stderr.
Future<void> main() async {
  final helper = Helper(stderr.writeln);
  final connection = Connection(
    stdin,
    stdout,
    helper.handle,
    onError: (method, error, stack) =>
        stderr.writeln('ERROR $method\n$error\n$stack'),
  );
  await connection.done;
  exit(0);
}
```

- [ ] **Step 8: Run the helper package**

Run: `cd helper && dart format --output=none --set-exit-if-changed . && dart analyze && dart test`
Expected: `No issues found!`, then `+26: All tests passed!` in about 10 s.

If a generated case file differs from `helper/test/cases/expected/`, run `DART_GENERATE_UPDATE=1 dart test test/cases_test.dart`. Then read the diff before you commit. This plan's expected files came from the replay, so there is normally no diff.

- [ ] **Step 9: Commit**

```bash
git add helper/lib/src/workspace.dart helper/lib/src/actions.dart helper/lib/src/helper.dart helper/bin/helper.dart helper/test/client.dart helper/test/workspace_test.dart helper/test/e2e_test.dart helper/test/cases_test.dart helper/test/cases
git commit -m "Answer actions and generate in the helper

Every fixture marker runs through the helper process, and each @not
marker reports its reason in the Generate… menu.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Composite actions: data class and the getter picker

"Generate data class" runs toString, `==`, copyWith and JSON in order. The getter picker runs the getter once for each picked field. The helper resolves the file again after each step and returns one edit over the changed span.

**Files:**
- Modify: `helper/lib/src/actions.dart`, `helper/lib/src/helper.dart`
- Test: `helper/test/cases_test.dart`
- Test data: `helper/test/cases/input/data_class.dart`, `helper/test/cases/expected/data_class.dart`, `helper/test/cases/expected/getters.dart`

**Interfaces:**
- Consumes: `Document`, `Result` and `Workspace.resolve` from Task 4.
- Produces: `typedef Resolve = Future<(ResolvedLibraryResult, ResolvedUnitResult)?> Function(String text)`. `generate` becomes `generate(Document doc, Resolve resolve, String action, int offset, int length, List<String>? fields)`.

- [ ] **Step 1: Write the failing tests**

Apply this patch from the repo root:

```bash
git apply <<'PATCH'
--- a/helper/test/cases_test.dart
+++ b/helper/test/cases_test.dart
@@ -249,6 +249,35 @@
     },
   );
 
+  test('data class adds the collection import and skips JSON', () async {
+    final text = _input('data_class.dart');
+    final result = await generate(
+      'data_class.dart',
+      text,
+      'dataClass',
+      text.indexOf('id;'),
+    );
+    expect(result['edits'], hasLength(1));
+    expect(result['replaces'], false);
+    expect(result['skipped'], [
+      'JSON: a map key is not String (nonStringMapKey)',
+    ]);
+    _expect('data_class.dart', applyEdits(text, result['edits']));
+  });
+
+  test('the getter picker adds two getters', () async {
+    final text = _input('getters.dart');
+    final result = await generate(
+      'getters.dart',
+      text,
+      'getter',
+      text.indexOf('Counter'),
+      fields: ['_count', '_step'],
+    );
+    expect(result['skipped'], isEmpty);
+    _expect('getters.dart', applyEdits(text, result['edits']));
+  });
+
   test('the helper logged no error', () {
     expect(helper.log.where((l) => l.startsWith('ERROR')), isEmpty);
   });
PATCH
```

Create `helper/test/cases/input/data_class.dart`:

```dart
class Order {
  final String id;
  final List<String> items;
  final Map<int, String> notes;

  const Order({required this.id, required this.items, required this.notes});
}
```

Create `helper/test/cases/expected/data_class.dart`:

```dart
import 'package:collection/collection.dart';

class Order {
  final String id;
  final List<String> items;
  final Map<int, String> notes;

  const Order({required this.id, required this.items, required this.notes});

  @override
  String toString() => 'Order(id: $id, items: $items, notes: $notes)';

  @override
  bool operator ==(Object other) =>
      other is Order &&
      other.id == id &&
      const DeepCollectionEquality().equals(other.items, items) &&
      const DeepCollectionEquality().equals(other.notes, notes);

  @override
  int get hashCode => Object.hash(
    id,
    const DeepCollectionEquality().hash(items),
    const DeepCollectionEquality().hash(notes),
  );

  Order copyWith({String? id, List<String>? items, Map<int, String>? notes}) =>
      Order(
        id: id ?? this.id,
        items: items ?? this.items,
        notes: notes ?? this.notes,
      );
}
```

Create `helper/test/cases/expected/getters.dart`:

```dart
class Counter {
  int _count = 0;

  int get count => _count;

  String _label;
  int _step;

  int get step => _step;

  Counter(this._label, this._step);

  String get label => _label;
}
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `cd helper && dart test test/cases_test.dart`
Expected: FAIL. The data class test fails with `helper error: {code: -32603, message: Null check operator used on a null value}`. The getter test finds no getter in the text.

- [ ] **Step 3: Add the composite actions**

Apply these two patches from the repo root:

```bash
git apply <<'PATCH'
--- a/helper/lib/src/actions.dart
+++ b/helper/lib/src/actions.dart
@@ -1,3 +1,5 @@
+import 'dart:math';
+
 import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
 import 'package:analyzer/dart/analysis/results.dart';
 import 'package:analyzer/dart/ast/ast.dart';
@@ -13,6 +15,11 @@
   String file,
   Object error,
   StackTrace stack,
+);
+
+/// Resolves the request's file again, with new text.
+typedef Resolve = Future<(ResolvedLibraryResult, ResolvedUnitResult)?> Function(
+  String text,
 );
 
 const internalError = 'internal error: see Output › Dart Generate';
@@ -268,15 +275,26 @@
   ];
 }
 
-/// Runs [action] as an explicit choice: a picker result or a quick fix.
-/// [fields] are the picked fields.
+/// Runs [action] as an explicit choice: a picker result, a quick fix or
+/// "Generate data class". [fields] are the picked fields.
 Future<Map<String, Object?>> generate(
   Document doc,
+  Resolve resolve,
   String action,
   int offset,
   int length,
   List<String>? fields,
 ) async {
+  if (action == 'dataClass') {
+    return _composite(doc, resolve, offset, [
+      for (final id in _steps.keys) (id, null),
+    ]);
+  }
+  if (action == 'getter' && fields != null) {
+    return _composite(doc, resolve, offset, [
+      for (final f in fields) ('getter', f),
+    ]);
+  }
   final r = await doc.run(
     action,
     offset,
@@ -291,9 +309,89 @@
       if (r.edits.isEmpty && r.disabled != null)
         '${_steps[action] ?? action}: ${r.disabled}',
     ],
+  };
+}
+
+/// Runs [steps] one after another. Each step is an assist ID, with a field
+/// name for a getter. The file is resolved again after each step. The
+/// result is one edit over the changed span, which includes an import that
+/// a step adds at the top of the file.
+Future<Map<String, Object?>> _composite(
+  Document doc,
+  Resolve resolve,
+  int offset,
+  List<(String, String?)> steps,
+) async {
+  final before = doc.unit.content;
+  // The class name: no step edits it, and only an import moves it.
+  final start = _classAt(doc.unit, offset)?.namePart.typeName.offset;
+  if (start == null) {
+    return {
+      'edits': const <Object?>[],
+      'replaces': false,
+      'skipped': const <Object?>[],
+    };
+  }
+  var at = start;
+  var text = before;
+  var current = doc;
+  var replaces = false;
+  final skipped = <String>[];
+  for (final (id, field) in steps) {
+    var position = at;
+    if (field != null) {
+      final cls = _classAt(current.unit, at);
+      final found = cls == null
+          ? null
+          : fieldNames(cls).where((f) => f.$1 == field).firstOrNull;
+      if (found == null) {
+        skipped.add('$field: the field is gone');
+        continue;
+      }
+      position = found.$2;
+    }
+    final r = await current.run(id, position, 0, anywhere: true);
+    if (r.edits.isEmpty) {
+      skipped.add('${field ?? _steps[id]}: ${r.disabled ?? 'no edit'}');
+      continue;
+    }
+    replaces |= r.regenerates;
+    for (final e in r.edits) {
+      if (e.offset + e.length <= at) at += e.replacement.length - e.length;
+    }
+    text = SourceEdit.applySequence(text, r.edits);
+    final resolved = await resolve(text);
+    if (resolved == null) break;
+    current = Document(resolved.$1, resolved.$2, doc.eol, doc.onError);
+  }
+  return {
+    'edits': [if (text != before) _span(before, text)],
+    'replaces': replaces,
+    'skipped': skipped,
   };
 }
 
 ClassDeclaration? _classAt(ResolvedUnitResult unit, int offset) => unit.unit
     .nodeCovering(offset: offset)
     ?.thisOrAncestorOfType<ClassDeclaration>();
+
+/// One edit from [before] to [after]: the span between their common prefix
+/// and their common suffix.
+Map<String, Object?> _span(String before, String after) {
+  final most = min(before.length, after.length);
+  var start = 0;
+  while (start < most && before.codeUnitAt(start) == after.codeUnitAt(start)) {
+    start++;
+  }
+  var end = 0;
+  while (end < most - start &&
+      before.codeUnitAt(before.length - 1 - end) ==
+          after.codeUnitAt(after.length - 1 - end)) {
+    end++;
+  }
+  return {
+    'offset': start,
+    'length': before.length - start - end,
+    'text': after.substring(start, after.length - end),
+  };
+}
PATCH
```

```bash
git apply <<'PATCH'
--- a/helper/lib/src/helper.dart
+++ b/helper/lib/src/helper.dart
@@ -56,8 +56,10 @@
             'skipped': const <Object?>[],
           };
         }
+        final path = p['path']! as String;
         return generate(
           doc,
+          (text) => _ready.resolve(path, text),
           p['action']! as String,
           p['offset']! as int,
           p['length']! as int,
PATCH
```

- [ ] **Step 4: Run the helper package**

Run: `cd helper && dart format --output=none --set-exit-if-changed . && dart analyze && dart test`
Expected: `No issues found!`, then `+28: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add helper/lib/src/actions.dart helper/lib/src/helper.dart helper/test/cases_test.dart helper/test/cases
git commit -m "Run Generate data class and the getter picker as one edit

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: The stale scan and the Regenerate ticks

The `stale` request marks a generated member that no longer covers every field (ADR 0008). The same reference rule gives the picker its start: Regenerate from Generate… ticks the fields that the member uses.

**Files:**
- Create: `helper/lib/src/stale.dart`
- Modify: `helper/lib/src/actions.dart`, `helper/lib/src/helper.dart`
- Test: `helper/test/cases_test.dart`
- Test data: `helper/test/cases/input/stale.dart`

**Interfaces:**
- Consumes: `findMember`, `readClass`, `GenerateToString.isGenerated` from Task 2, and the core generators.
- Produces: `Map<String, Object?> stale(ResolvedUnitResult unit)`, which gives `{items: [{offset, length, id, severity, message, missing}]}` or `{skipped: true}`. Also `Set<String> usedBy(ClassDeclaration cls, ClassElement element, String name)`.
- The request: `stale {path, text}`.

- [ ] **Step 1: Write the failing tests**

Apply this patch from the repo root:

```bash
git apply <<'PATCH'
--- a/helper/test/cases_test.dart
+++ b/helper/test/cases_test.dart
@@ -278,6 +278,93 @@
     _expect('getters.dart', applyEdits(text, result['edits']));
   });
 
+  test('Regenerate ticks the fields that the member uses', () async {
+    final text = _input('stale.dart');
+    final at = text.indexOf('class Point') + 6;
+    final menu = await actions(path('stale.dart'), text, at, explicit: true);
+    expect(byId(menu, 'toString')['title'], 'Regenerate toString()…');
+    expect((byId(menu, 'toString')['pick']! as Map)['ticked'], ['x']);
+    expect((byId(menu, 'equality')['pick']! as Map)['ticked'], ['x']);
+    final field = text.indexOf('final int y;');
+    final selected = await actions(
+      path('stale.dart'),
+      text,
+      field,
+      length: 'final int y;'.length,
+      explicit: true,
+    );
+    expect((byId(selected, 'toString')['pick']! as Map)['ticked'], ['y']);
+    final money = text.indexOf('class Money') + 6;
+    final read = await actions(path('stale.dart'), text, money, explicit: true);
+    expect((byId(read, 'toString')['pick']! as Map)['ticked'], ['_pence']);
+  });
+
+  test('each stale member gets its mark', () async {
+    final text = _input('stale.dart');
+    final result = await helper.request('stale', {
+      'path': path('stale.dart'),
+      'text': text,
+    });
+    final items = [
+      for (final i in (result! as Map)['items'] as List<Object?>)
+        i! as Map<String, Object?>,
+    ];
+    expect(
+      [
+        for (final i in items)
+          (
+            text.substring(
+              i['offset']! as int,
+              (i['offset']! as int) + (i['length']! as int),
+            ),
+            i['severity'],
+            i['message'],
+          ),
+      ],
+      [
+        ('copyWith', 'warning', 'copyWith() does not cover note.'),
+        ('toJson', 'warning', 'toJson() does not cover note.'),
+        ('fromJson', 'warning', 'fromJson() does not cover note.'),
+        ('toString', 'hint', 'toString() does not show y.'),
+        ('==', 'hint', '==() and hashCode do not use y.'),
+      ],
+    );
+  });
+
+  test('a syntax error skips the scan', () async {
+    final result = await helper.request('stale', {
+      'path': path('stale.dart'),
+      'text': 'class A {\n  final int x;\n  String toString() =>\n}\n',
+    });
+    expect(result, {'skipped': true});
+  });
+
+  test('overlapping requests each answer for their own text', () async {
+    final text = _input('stale.dart');
+    final fixed = text.replaceFirst(
+      "'Point(x: \$x)'",
+      "'Point(x: \$x, y: \$y)'",
+    );
+    final answers = await Future.wait([
+      for (var i = 0; i < 10; i++)
+        helper.request('stale', {
+          'path': path('stale.dart'),
+          'text': i.isEven ? text : fixed,
+        }),
+    ]);
+    for (final (i, answer) in answers.indexed) {
+      final messages = [
+        for (final item in (answer! as Map)['items'] as List<Object?>)
+          (item! as Map)['message'],
+      ];
+      expect(
+        messages.contains('toString() does not show y.'),
+        i.isEven,
+        reason: 'request $i',
+      );
+    }
+  });
+
   test('the helper logged no error', () {
     expect(helper.log.where((l) => l.startsWith('ERROR')), isEmpty);
   });
PATCH
```

Create `helper/test/cases/input/stale.dart`:

```dart
// copyWith and toJson leave out note: two warnings.
class Task {
  final String title;
  final String? note;

  const Task(this.title, {this.note});

  Task copyWith({String? title}) => Task(title ?? this.title);

  Map<String, Object?> toJson() => {'title': title};
}

// fromJson leaves out note: a warning on fromJson.
class Tag {
  final String name;
  final String? note;

  const Tag(this.name, {this.note});

  factory Tag.fromJson(Map<String, Object?> json) =>
      Tag(json['name']! as String);

  Map<String, Object?> toJson() => {'name': name, 'note': note};
}

// toString and == leave out y: a hint on each.
class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

  @override
  String toString() => 'Point(x: $x)';

  @override
  bool operator ==(Object other) => other is Point && other.x == x;

  @override
  int get hashCode => x.hashCode;
}

// A hand-written fromJson with its own keys covers every field: no mark.
class Reading {
  final double temperature;
  final int code;

  const Reading({required this.temperature, required this.code});

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
    temperature: json['temperature_2m'] as double,
    code: json['weather_code'] as int,
  );
}

// A mutable class gets no == hint. A hand-written toString gets no hint.
class Counter {
  int count;
  int step;

  Counter(this.count, this.step);

  @override
  String toString() => 'count is $count';

  @override
  bool operator ==(Object other) => other is Counter && other.count == count;

  @override
  int get hashCode => count.hashCode;
}

// toString and == read the private field through its getter: no mark.
class Money {
  final int _pence;

  const Money(this._pence);

  int get pence => _pence;

  @override
  String toString() => 'Money(pence: $pence)';

  @override
  bool operator ==(Object other) => other is Money && other.pence == pence;

  @override
  int get hashCode => pence.hashCode;
}
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `cd helper && dart test test/cases_test.dart`
Expected: FAIL. The stale tests fail with `helper error: {code: -32603, message: Unsupported operation: unknown method stale}`. The Regenerate test finds every field ticked, not `['x']`.

- [ ] **Step 3: Write the scan**

Create `helper/lib/src/stale.dart`:

```dart
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:dart_generate/assists.dart';
import 'package:generate_core/generate_core.dart';

/// The generated members that no longer cover every field (ADR 0008), or
/// `{skipped: true}` when the file has a syntax error.
Map<String, Object?> stale(ResolvedUnitResult unit) {
  if (unit.diagnostics.any(
    (d) => d.diagnosticCode.type == DiagnosticType.SYNTACTIC_ERROR,
  )) {
    return {'skipped': true};
  }
  return {
    'items': [
      for (final cls in unit.unit.declarations.whereType<ClassDeclaration>())
        ..._staleIn(cls, unit),
    ],
  };
}

List<Map<String, Object?>> _staleIn(
  ClassDeclaration cls,
  ResolvedUnitResult unit,
) {
  final element = cls.declaredFragment?.element;
  if (element == null) return const [];
  final model = readClass(element, unit.typeSystem);
  final all = [for (final f in usedFields(model, null)) f.name];
  final built = [
    for (final p in model.builder?.params ?? const <ParamModel>[]) p.name,
  ];
  final items = <Map<String, Object?>>[];

  void check(
    String name,
    String id,
    Outcome outcome,
    List<String> expected,
    String Function(String fields) message,
  ) {
    final member = findMember(cls, name);
    if (member == null || outcome is! Generated) return;
    final used = usedBy(cls, element, name);
    final missing = [
      for (final f in expected)
        if (!used.contains(f)) f,
    ];
    if (missing.isEmpty) return;
    final token = switch (member) {
      MethodDeclaration(name: final t) => t,
      ConstructorDeclaration(name: final t?) => t,
      _ => member.beginToken,
    };
    items.add({
      'offset': token.offset,
      'length': token.length,
      'id': id,
      'severity': id == 'toString' || id == 'equality' ? 'hint' : 'warning',
      'message': message(_join(missing)),
      'missing': missing,
    });
  }

  // customToString: a hand-written toString keeps its text and gets no mark.
  if (findMember(cls, 'toString') case final MethodDeclaration m
      when GenerateToString.isGenerated(m, model.name)) {
    check(
      'toString',
      'toString',
      generateToString(model),
      all,
      (f) => 'toString() does not show $f.',
    );
  }
  check(
    '==',
    'equality',
    generateEquality(model),
    all,
    (f) => '==() and hashCode do not use $f.',
  );
  final copyWith = generateCopyWith(model);
  check(
    'copyWith',
    'copyWith',
    copyWith,
    built,
    (f) => 'copyWith() does not cover $f.',
  );
  final json = generateJson(model);
  check('toJson', 'json', json, built, (f) => 'toJson() does not cover $f.');
  check(
    'fromJson',
    'json',
    json,
    built,
    (f) => 'fromJson() does not cover $f.',
  );
  return items;
}

/// The fields that the member named [name] references. For `==`, a field
/// counts only when hashCode uses it too.
Set<String> usedBy(ClassDeclaration cls, ClassElement element, String name) {
  Set<String> of(String name) {
    final member = findMember(cls, name);
    if (member == null) return const {};
    final visitor = _References(cls, element);
    member.accept(visitor);
    return visitor.names;
  }

  return name == '==' ? of('==').intersection(of('hashCode')) : of(name);
}

/// "a", "a and b", "a, b and c".
String _join(List<String> names) => names.length == 1
    ? names.single
    : '${names.take(names.length - 1).join(', ')} and ${names.last}';

/// Collects the fields of a class that a member references: a read of the
/// field or its getter, and an argument to a `this.` or `super.` parameter.
final class _References extends RecursiveAstVisitor<void> {
  _References(this._cls, this._element)
    : _owners = {_element, for (final t in _element.allSupertypes) t.element};

  final ClassDeclaration _cls;
  final ClassElement _element;

  /// The class and its supertypes. A field of another class does not count.
  final Set<InterfaceElement> _owners;
  final names = <String>{};

  /// The getters of the class whose bodies this visitor read.
  final _followed = <MethodDeclaration>{};

  void _add(FieldElement? field) {
    if (field == null || field.isStatic) return;
    if (!_owners.contains(field.enclosingElement)) return;
    if (field.name case final name?) names.add(name);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element case PropertyAccessorElement(
      variable: final FieldElement field,
    )) {
      _add(field);
      _follow(field);
    }
    super.visitSimpleIdentifier(node);
  }

  /// Reads the body of a getter that the class declares, once. So
  /// `int get pence => _pence;` makes a read of `pence` a read of `_pence`.
  void _follow(FieldElement field) {
    if (field.enclosingElement != _element) return;
    if (findMember(_cls, field.name ?? '') case final MethodDeclaration getter
        when getter.isGetter && _followed.add(getter)) {
      getter.body.accept(this);
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (final argument in node.arguments) {
      FormalParameterElement? p = argument.correspondingParameter;
      while (p is SuperFormalParameterElement) {
        p = p.superConstructorParameter;
      }
      if (p is FieldFormalParameterElement) _add(p.field);
    }
    super.visitArgumentList(node);
  }
}
```

- [ ] **Step 4: Use the scan in the picker and in the request table**

Apply these two patches from the repo root:

```bash
git apply <<'PATCH'
--- a/helper/lib/src/actions.dart
+++ b/helper/lib/src/actions.dart
@@ -9,6 +9,8 @@
 import 'package:dart_generate/assists.dart';
 import 'package:generate_core/generate_core.dart';
 
+import 'stale.dart';
+
 /// Receives the failure of an assist.
 typedef OnError = void Function(
   String generator,
@@ -159,7 +161,7 @@
         'title': '${r.title}…',
         'disabledReason': r.disabled,
         if (r.disabled == null && cls != null && element != null)
-          'pick': _pick(cls, element, doc.unit, offset, length),
+          'pick': _pick(cls, element, doc.unit, id, offset, length),
       });
     } else if (r.edits.isNotEmpty) {
       out.add(_withEdits(id, r));
@@ -232,11 +234,13 @@
 
 /// The picker of toString or `==`: the fields that the action can use, and
 /// the ones ticked at the start. A selection ticks the fields that it
-/// covers. Otherwise every field is ticked.
+/// covers. Otherwise an existing member ticks the fields that it uses, so a
+/// deliberate subset stays. Otherwise every field is ticked.
 Map<String, Object?> _pick(
   ClassDeclaration cls,
   ClassElement element,
   ResolvedUnitResult unit,
+  String id,
   int offset,
   int length,
 ) {
@@ -246,7 +250,12 @@
     for (final (name, at) in fieldNames(cls))
       if (length > 0 && at >= offset && at < offset + length) name,
   }.intersection(names);
-  final ticked = selected.isNotEmpty ? selected : names;
+  final member = id == 'equality' ? '==' : id;
+  final ticked = selected.isNotEmpty
+      ? selected
+      : findMember(cls, member) != null
+      ? usedBy(cls, element, member).intersection(names)
+      : names;
   return {
     'fields': [
       for (final f in fields) {'name': f.name, 'type': f.type.code},
PATCH
```

```bash
git apply <<'PATCH'
--- a/helper/lib/src/helper.dart
+++ b/helper/lib/src/helper.dart
@@ -1,6 +1,7 @@
 import 'package:analyzer/dart/analysis/session.dart';
 
 import 'actions.dart';
+import 'stale.dart';
 import 'workspace.dart';
 
 /// The requests and notifications of the helper.
@@ -68,6 +69,14 @@
             _ => null,
           },
         );
+      case 'stale':
+        final resolved = await _ready.resolve(
+          p['path']! as String,
+          p['text']! as String,
+        );
+        return resolved == null
+            ? {'items': const <Object?>[]}
+            : stale(resolved.$2);
       case 'filesChanged':
         await _ready.changed([
           for (final f in p['paths']! as List<Object?>) f! as String,
PATCH
```

- [ ] **Step 5: Run the helper package**

Run: `cd helper && dart format --output=none --set-exit-if-changed . && dart analyze && dart test`
Expected: `No issues found!`, then `+32: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add helper/lib/src/stale.dart helper/lib/src/actions.dart helper/lib/src/helper.dart helper/test/cases_test.dart helper/test/cases
git commit -m "Mark stale generated members, and tick used fields on Regenerate

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: The extension scaffold, the helper process and the SDK path

The test window loads `vscode/test/stub`, an empty extension. The tests import the modules directly, so the real extension starts no helper in that window.

**Files:**
- Create: `vscode/package.json`, `vscode/tsconfig.json`, `vscode/eslint.config.mjs`, `vscode/src/protocol.ts`, `vscode/src/helper.ts`, `vscode/src/sdk.ts`
- Create: `vscode/test/run.ts`, `vscode/test/suite/index.ts`, `vscode/test/stub/package.json`, `vscode/test/workspace/pubspec.yaml`, `vscode/test/workspace/lib/point.dart`
- Modify: `.gitignore`
- Test: `vscode/test/suite/helper.test.ts`
- Generated: `vscode/package-lock.json`

**Interfaces:**
- Produces:
  - In `protocol.ts`: the types `Edit`, `Pick`, `Action`, `Generated`, `StaleItem`, `StaleResult` and `Helper`, and the functions `documentParams(document, range)`, `served(document)` and `workspaceEdit(document, edits, replaces)`.
  - In `helper.ts`: `HelperProcess(command, args, setup: () => Setup | undefined, channel, onFailed: (message: string) => void, onStarted?)`, with `start()`, `request<T>(method, params, explicit, token?)`, `notify(method, params)` and `dispose()`.
  - In `sdk.ts`: `DartApi`, `dartApi()`, `sdkFromPath()` and `sdkOf(dart)`.

- [ ] **Step 1: Write the manifest and the build files**

Create `vscode/package.json`:

```json
{
  "name": "dart-generate",
  "displayName": "Dart Generate",
  "description": "Generate toString, ==, copyWith, JSON and getters for Dart classes.",
  "version": "0.1.0",
  "publisher": "local",
  "private": true,
  "engines": {
    "vscode": "^1.139.0"
  },
  "categories": [
    "Programming Languages"
  ],
  "main": "./dist/extension.js",
  "activationEvents": [
    "onLanguage:dart"
  ],
  "capabilities": {
    "untrustedWorkspaces": {
      "supported": true
    }
  },
  "contributes": {
    "commands": [
      {
        "command": "dartGenerate.generate",
        "title": "Generate…",
        "category": "Dart Generate"
      },
      {
        "command": "dartGenerate.restartHelper",
        "title": "Restart Helper",
        "category": "Dart Generate"
      },
      {
        "command": "dartGenerate.showOutput",
        "title": "Show Output",
        "category": "Dart Generate"
      }
    ],
    "keybindings": [
      {
        "command": "dartGenerate.generate",
        "key": "cmd+n",
        "when": "editorTextFocus && editorLangId == dart && resourceScheme == file && !editorReadonly"
      }
    ],
    "menus": {
      "commandPalette": [
        {
          "command": "dartGenerate.generate",
          "when": "editorLangId == dart"
        }
      ],
      "editor/context": [
        {
          "command": "dartGenerate.generate",
          "when": "editorLangId == dart",
          "group": "1_modification"
        }
      ]
    }
  },
  "scripts": {
    "compile": "esbuild src/extension.ts --bundle --platform=node --format=cjs --target=node22 --external:vscode --outfile=dist/extension.js",
    "check": "tsc --noEmit -p . && eslint .",
    "pretest": "tsc -p .",
    "test": "node out/test/run.js",
    "package": "sh scripts/package.sh"
  },
  "devDependencies": {
    "@eslint/js": "10.0.1",
    "@types/mocha": "10.0.10",
    "@types/node": "24.19.0",
    "@types/vscode": "1.138.0",
    "@vscode/test-electron": "3.1.0",
    "@vscode/vsce": "4.0.0",
    "esbuild": "0.28.2",
    "eslint": "10.11.0",
    "mocha": "12.0.2",
    "typescript": "6.0.3",
    "typescript-eslint": "8.71.0",
    "vscode-jsonrpc": "9.0.3"
  }
}
```

Create `vscode/tsconfig.json`:

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "es2023",
    "lib": [
      "es2023"
    ],
    "types": [
      "node",
      "mocha"
    ],
    "strict": true,
    "rootDir": ".",
    "outDir": "out",
    "sourceMap": true,
    "skipLibCheck": true,
    "esModuleInterop": true
  },
  "include": [
    "src",
    "test"
  ]
}
```

Create `vscode/eslint.config.mjs`:

```js
import js from '@eslint/js';
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig([
  { ignores: ['bin/', 'dist/', 'out/', '.vscode-test/'] },
  js.configs.recommended,
  tseslint.configs.recommended,
]);
```

Append the build folders to `.gitignore` from the repo root. If the worktree setup added a line there first, an append still works:

```bash
cat >> .gitignore <<'EOF'
.vscode-test/
node_modules/
dist/
out/
vscode/bin/
*.vsix
EOF
```

Run: `cd vscode && npm install`
Expected: a new `vscode/package-lock.json`. npm 11 warns that it did not run the install script of `@vscode/vsce-sign`. `vsce package` works without that script.

- [ ] **Step 2: Write the test runner**

Create `vscode/test/run.ts`:

```ts
// Runs the Mocha suite in VS Code 1.139.1. The window opens test/workspace
// with the stub extension, so no real helper starts by itself.
import { runTests } from '@vscode/test-electron';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const root = resolve(__dirname, '../..');
// macOS limits a socket path to 103 characters, and VS Code puts its socket
// in the user data folder. A folder under the temp folder stays short.
const userData = mkdtempSync(join(tmpdir(), 'dart-generate-test-'));

runTests({
  version: '1.139.1',
  extensionDevelopmentPath: resolve(root, 'test/stub'),
  extensionTestsPath: resolve(__dirname, 'suite/index'),
  launchArgs: [
    resolve(root, 'test/workspace'),
    '--disable-extensions',
    `--user-data-dir=${userData}`,
  ],
}).catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
```

Create `vscode/test/suite/index.ts`:

```ts
import Mocha from 'mocha';
import { readdirSync } from 'node:fs';
import { join } from 'node:path';

export function run(): Promise<void> {
  const mocha = new Mocha({ ui: 'bdd', timeout: 20_000 });
  for (const file of readdirSync(__dirname)) {
    if (file.endsWith('.test.js')) mocha.addFile(join(__dirname, file));
  }
  return new Promise((resolve, reject) =>
    mocha.run((failures) =>
      failures > 0 ? reject(new Error(`${failures} tests failed`)) : resolve(),
    ),
  );
}
```

Create `vscode/test/stub/package.json`:

```json
{
  "name": "stub",
  "publisher": "test",
  "version": "0.0.0",
  "description": "An empty extension. The tests load the modules themselves, so the real extension does not start a helper in the test window.",
  "engines": {
    "vscode": "^1.139.0"
  }
}
```

Create `vscode/test/workspace/pubspec.yaml`:

```yaml
name: smoke
environment:
  sdk: ^3.13.0
```

Create `vscode/test/workspace/lib/point.dart`:

```dart
class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);
}
```

- [ ] **Step 3: Write the failing test**

Create `vscode/test/suite/helper.test.ts`:

```ts
import * as assert from 'node:assert';
import { mkdirSync, mkdtempSync, realpathSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import * as vscode from 'vscode';
import { HelperProcess } from '../../src/helper';
import { served } from '../../src/protocol';
import { sdkOf } from '../../src/sdk';

describe('the helper process', () => {
  it('restarts a crashing helper 3 times, then gives up', async () => {
    const channel = vscode.window.createOutputChannel('Dart Generate test', { log: true });
    let starts = 0;
    const gaveUp = new Promise<string>((resolve) => {
      const helper = new HelperProcess(
        '/bin/sh',
        ['-c', 'exit 3'],
        () => {
          starts++;
          return { sdkPath: '/sdk', folders: [] };
        },
        channel,
        resolve,
      );
      void helper.start();
    });
    assert.strictEqual(await gaveUp, 'the helper keeps crashing.');
    assert.strictEqual(starts, 4);
    channel.dispose();
  });

  it('without an SDK, says so and answers undefined', async () => {
    const channel = vscode.window.createOutputChannel('Dart Generate test', { log: true });
    const failures: string[] = [];
    const helper = new HelperProcess('/bin/sh', [], () => undefined, channel, (m) =>
      failures.push(m),
    );
    await helper.start();
    assert.deepStrictEqual(failures, ['the helper did not start.']);
    assert.strictEqual(await helper.request('actions', {}, false), undefined);
    channel.dispose();
  });
});

describe('the SDK path', () => {
  // realpath: on macOS, /var is a link to /private/var.
  const root = realpathSync(mkdtempSync(join(tmpdir(), 'dart_generate_sdk_')));

  it('is two levels above the real dart executable', () => {
    mkdirSync(join(root, 'sdk/bin'), { recursive: true });
    writeFileSync(join(root, 'sdk/bin/dart'), '');
    mkdirSync(join(root, 'links'));
    symlinkSync(join(root, 'sdk/bin/dart'), join(root, 'links/dart'));
    assert.strictEqual(sdkOf(join(root, 'links/dart')), join(root, 'sdk'));
  });

  it('is bin/cache/dart-sdk for the Flutter wrapper', () => {
    mkdirSync(join(root, 'flutter/bin/cache/dart-sdk'), { recursive: true });
    writeFileSync(join(root, 'flutter/bin/dart'), '');
    assert.strictEqual(
      sdkOf(join(root, 'flutter/bin/dart')),
      join(root, 'flutter/bin/cache/dart-sdk'),
    );
  });
});

describe('served documents', () => {
  it('skips generated files and files outside the workspace', async () => {
    const folder = vscode.workspace.workspaceFolders![0].uri;
    const generated = await vscode.workspace.openTextDocument(
      vscode.Uri.joinPath(folder, 'lib', 'point.g.dart').with({ scheme: 'untitled' }),
    );
    const header = await vscode.workspace.openTextDocument({
      language: 'dart',
      content: '// GENERATED CODE - DO NOT MODIFY BY HAND\nclass A {}\n',
    });
    const point = await vscode.workspace.openTextDocument(
      vscode.Uri.joinPath(folder, 'lib', 'point.dart'),
    );
    assert.deepStrictEqual(
      [served(generated), served(header), served(point)],
      [false, false, true],
    );
  });
});
```

- [ ] **Step 4: Run the test to see it fail**

Run: `cd vscode && npm test`
Expected: FAIL in `pretest` with `error TS2307: Cannot find module '../../src/helper'`.

- [ ] **Step 5: Write the modules**

Create `vscode/src/protocol.ts`:

```ts
// The JSON-RPC messages between the extension and the Dart helper. The
// helper's side is in helper/lib/src/helper.dart.

import * as vscode from 'vscode';

/** A replacement in the text of the request, in UTF-16 offsets. */
export interface Edit {
  offset: number;
  length: number;
  text: string;
}

export interface Pick {
  fields: { name: string; type: string }[];
  /** The fields ticked when the picker opens. */
  ticked: string[];
}

export interface Action {
  id: string;
  title: string;
  disabledReason: string | null;
  edits?: Edit[];
  replaces?: boolean;
  pick?: Pick;
}

export interface Generated {
  edits: Edit[];
  replaces: boolean;
  skipped: string[];
}

export interface StaleItem {
  offset: number;
  length: number;
  id: string;
  severity: 'warning' | 'hint';
  message: string;
  missing: string[];
}

export type StaleResult = { skipped: true } | { items: StaleItem[] };

/** The helper as the providers see it. */
export interface Helper {
  /**
   * Sends a request. It resolves to `undefined` when the helper is not
   * running, when it answers with an error, or when an automatic request
   * takes longer than 5 s. An explicit request waits and shows progress.
   */
  request<T>(
    method: string,
    params: object,
    explicit: boolean,
    token?: vscode.CancellationToken,
  ): Promise<T | undefined>;
  notify(method: string, params: object): void;
}

/** The path, text, line ending and selection of a request. */
export function documentParams(document: vscode.TextDocument, range: vscode.Range) {
  const offset = document.offsetAt(range.start);
  return {
    path: document.uri.fsPath,
    text: document.getText(),
    eol: document.eol === vscode.EndOfLine.CRLF ? '\r\n' : '\n',
    offset,
    length: document.offsetAt(range.end) - offset,
  };
}

/**
 * Whether the extension serves [document]: a Dart file inside a workspace
 * folder that is not generated code.
 */
export function served(document: vscode.TextDocument): boolean {
  return (
    document.languageId === 'dart' &&
    document.uri.scheme === 'file' &&
    vscode.workspace.getWorkspaceFolder(document.uri) !== undefined &&
    !/\.(g|freezed)\.dart$/.test(document.uri.path) &&
    !document.getText().slice(0, 500).includes('GENERATED CODE - DO NOT MODIFY')
  );
}

/** A workspace edit for [edits]. A replacement opens the refactor preview. */
export function workspaceEdit(
  document: vscode.TextDocument,
  edits: Edit[],
  replaces: boolean,
): vscode.WorkspaceEdit {
  const edit = new vscode.WorkspaceEdit();
  const metadata = replaces
    ? { label: 'Dart Generate', needsConfirmation: true }
    : undefined;
  for (const e of edits) {
    const range = new vscode.Range(
      document.positionAt(e.offset),
      document.positionAt(e.offset + e.length),
    );
    edit.replace(document.uri, range, e.text, metadata);
  }
  return edit;
}
```

Create `vscode/src/helper.ts`:

```ts
import { ChildProcess, spawn } from 'node:child_process';
import * as vscode from 'vscode';
import {
  CancellationTokenSource,
  createMessageConnection,
  ErrorCodes,
  MessageConnection,
  ResponseError,
  StreamMessageReader,
  StreamMessageWriter,
} from 'vscode-jsonrpc/node';
import { Helper } from './protocol';

/** What the helper needs at each start. */
export interface Setup {
  sdkPath: string;
  folders: string[];
}

/**
 * The helper process. A crash restarts it, up to 3 times in 3 minutes.
 * After that, or when the helper cannot start, [onFailed] runs.
 */
export class HelperProcess implements Helper, vscode.Disposable {
  private child?: ChildProcess;
  private connection?: MessageConnection;
  private crashes: number[] = [];
  private warned = false;

  constructor(
    private readonly command: string,
    private readonly args: string[],
    private readonly setup: () => Setup | undefined,
    private readonly channel: vscode.LogOutputChannel,
    /** Shows a failure that the user must act on. */
    private readonly onFailed: (message: string) => void,
    /** Runs after each start, for example to scan the visible editors. */
    private readonly onStarted: () => void = () => {},
  ) {}

  /** Starts the helper, or restarts it with a new setup. */
  async start(): Promise<void> {
    this.stop();
    const setup = this.setup();
    if (!setup) {
      this.onFailed('the helper did not start.');
      return;
    }
    const child = spawn(this.command, this.args, { stdio: 'pipe' });
    const connection = createMessageConnection(
      new StreamMessageReader(child.stdout),
      new StreamMessageWriter(child.stdin),
    );
    this.child = child;
    this.connection = connection;
    child.stderr.setEncoding('utf8');
    child.stderr.on('data', (text: string) => {
      for (const line of text.trimEnd().split('\n')) {
        if (line.startsWith('ERROR')) this.channel.error(line);
        else this.channel.info(line);
      }
    });
    // A failed spawn gives 'error' and no 'exit'. Either one ends this run.
    const ended = (why: string) => {
      if (this.child !== child) return;
      this.stop();
      this.channel.error(why);
      this.crashed();
    };
    child.on('error', (error) => ended(`The helper did not start: ${error}`));
    child.on('exit', (code) => ended(`The helper exited with code ${code}.`));
    connection.listen();
    let result: { warning: string | null };
    try {
      result = await connection.sendRequest('initialize', setup);
    } catch (error: unknown) {
      // The helper answered with an error, such as a wrong SDK path. A crash
      // rejects with another code and ends the run through 'exit'.
      if (error instanceof ResponseError && error.code === ErrorCodes.InternalError) {
        this.channel.error(`initialize: ${error.message}`);
        this.onFailed('the helper did not start.');
      }
      return;
    }
    if (result.warning && !this.warned) {
      this.warned = true;
      void vscode.window.showWarningMessage(result.warning);
    }
    this.onStarted();
  }

  private crashed(): void {
    const now = Date.now();
    this.crashes = this.crashes.filter((t) => now - t < 180_000);
    this.crashes.push(now);
    if (this.crashes.length > 3) {
      this.onFailed('the helper keeps crashing.');
      return;
    }
    void this.start();
  }

  async request<T>(
    method: string,
    params: object,
    explicit: boolean,
    token?: vscode.CancellationToken,
  ): Promise<T | undefined> {
    const connection = this.connection;
    if (!connection) return undefined;
    const source = new CancellationTokenSource();
    const cancel = token?.onCancellationRequested(() => source.cancel());
    const call = connection
      .sendRequest<T>(method, params, source.token)
      .catch((error: unknown) => {
        if (!source.token.isCancellationRequested) {
          this.channel.error(`${method}: ${error}`);
        }
        return undefined;
      });
    try {
      if (explicit) {
        return await vscode.window.withProgress(
          {
            location: vscode.ProgressLocation.Window,
            title: 'Dart Generate: analyzing…',
          },
          () => call,
        );
      }
      let timer: NodeJS.Timeout | undefined;
      const timeout = new Promise<undefined>((resolve) => {
        timer = setTimeout(() => {
          source.cancel();
          resolve(undefined);
        }, 5000);
      });
      const result = await Promise.race([call, timeout]);
      clearTimeout(timer);
      return result;
    } finally {
      cancel?.dispose();
      source.dispose();
    }
  }

  notify(method: string, params: object): void {
    void this.connection?.sendNotification(method, params);
  }

  private stop(): void {
    const child = this.child;
    this.child = undefined;
    this.connection?.dispose();
    this.connection = undefined;
    child?.kill();
  }

  dispose(): void {
    this.stop();
  }
}
```

Create `vscode/src/sdk.ts`:

```ts
import { existsSync, realpathSync } from 'node:fs';
import { delimiter, dirname, join } from 'node:path';
import * as vscode from 'vscode';

/** The part of the Dart extension's public API that this extension uses. */
export interface DartApi {
  sdks: { dart?: string };
  onSdksChanged: (listener: () => void) => vscode.Disposable;
}

/** The Dart extension's API, or `undefined` when it is not installed. */
export async function dartApi(): Promise<DartApi | undefined> {
  const extension = vscode.extensions.getExtension<DartApi>('Dart-Code.dart-code');
  if (!extension) return undefined;
  return extension.isActive ? extension.exports : await extension.activate();
}

/** The SDK of the first `dart` on PATH, or `undefined`. */
export function sdkFromPath(): string | undefined {
  for (const dir of (process.env.PATH ?? '').split(delimiter)) {
    const dart = join(dir, 'dart');
    if (existsSync(dart)) return sdkOf(dart);
  }
  return undefined;
}

/**
 * The SDK of a `dart` executable. For Flutter's wrapper script,
 * `<flutter>/bin/dart`, it is `<flutter>/bin/cache/dart-sdk`.
 */
export function sdkOf(dart: string): string {
  const bin = dirname(realpathSync(dart));
  const flutter = join(bin, 'cache', 'dart-sdk');
  return existsSync(flutter) ? flutter : dirname(bin);
}
```

- [ ] **Step 6: Run the checks and the suite**

Run: `cd vscode && npm run check && npm test`
Expected: `5 passing`. The first run downloads VS Code 1.139.1, 298.67 MB, into `vscode/.vscode-test/`. A VS Code window opens and closes during each run.

- [ ] **Step 7: Commit**

```bash
git add .gitignore vscode/package.json vscode/package-lock.json vscode/tsconfig.json vscode/eslint.config.mjs vscode/src vscode/test
git commit -m "Add the extension scaffold, the helper process and the SDK path

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Generate…, Cmd+., the pickers and the quick fixes

**Files:**
- Create: `vscode/src/actions.ts`, `vscode/src/extension.ts`
- Test: `vscode/test/suite/fakes.ts`, `vscode/test/suite/actions.test.ts`

**Interfaces:**
- Consumes: `Helper`, `documentParams`, `served`, `workspaceEdit` and `HelperProcess` from Task 7.
- Produces:
  - In `actions.ts`: `generateKind`, `fixKind`, `type Picker`, `interface Run`, `class Generator` with `generate()`, `provideCodeActions(...)` and `run(uri, run)`, and `quickPick`.
  - In `extension.ts`: `activate(context)` and `register(subscriptions, helper, pick)`, which returns `{generator}`. Task 9 adds `stale`.
- The commands: `dartGenerate.generate`, `dartGenerate.run` (internal, with no palette entry), `dartGenerate.restartHelper` and `dartGenerate.showOutput`.

- [ ] **Step 1: Write the fakes and the failing tests**

Create `vscode/test/suite/fakes.ts`:

```ts
import * as vscode from 'vscode';
import { Picker } from '../../src/actions';
import { Helper } from '../../src/protocol';

/** One call that the fake helper received. */
export interface Call {
  method: string;
  params: Record<string, unknown>;
  explicit: boolean;
}

/** A helper that answers from [answers] and records each call. */
export class FakeHelper implements Helper {
  readonly calls: Call[] = [];
  answers: Record<string, (params: Record<string, unknown>) => unknown> = {};

  async request<T>(method: string, params: object, explicit: boolean): Promise<T | undefined> {
    const p = params as Record<string, unknown>;
    this.calls.push({ method, params: p, explicit });
    return (await this.answers[method]?.(p)) as T | undefined;
  }

  notify(method: string, params: object): void {
    this.calls.push({ method, params: params as Record<string, unknown>, explicit: false });
  }

  called(method: string): Call[] {
    return this.calls.filter((c) => c.method === method);
  }
}

/** A picker that records its arguments and answers [answer]. */
export class FakePicker {
  readonly opened: { title: string; ticked: string[] }[] = [];
  answer: string[] | undefined = undefined;
  readonly pick: Picker = async (title, _fields, ticked) => {
    this.opened.push({ title, ticked });
    return this.answer;
  };
}

/** Opens test/workspace/lib/point.dart with [text] in a fresh editor. */
export async function openPoint(text: string): Promise<vscode.TextEditor> {
  const folder = vscode.workspace.workspaceFolders![0].uri;
  const uri = vscode.Uri.joinPath(folder, 'lib', 'point.dart');
  const document = await vscode.workspace.openTextDocument(uri);
  const editor = await vscode.window.showTextDocument(document);
  await editor.edit((b) =>
    b.replace(new vscode.Range(0, 0, document.lineCount, 0), text),
  );
  return editor;
}

export const pointText = `class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);
}
`;

export function dispose(disposables: vscode.Disposable[]): void {
  for (const d of disposables.splice(0)) d.dispose();
}
```

Create `vscode/test/suite/actions.test.ts`:

```ts
import * as assert from 'node:assert';
import * as vscode from 'vscode';
import { fixKind, generateKind, Generator } from '../../src/actions';
import { register } from '../../src/extension';
import { Action } from '../../src/protocol';
import { dispose, FakeHelper, FakePicker, openPoint, pointText } from './fakes';

const menu: Action[] = [
  { id: 'dataClass', title: 'Generate data class', disabledReason: null },
  {
    id: 'toString',
    title: 'Generate toString()…',
    disabledReason: null,
    pick: {
      fields: [
        { name: 'x', type: 'int' },
        { name: 'y', type: 'int' },
      ],
      ticked: ['x'],
    },
  },
  {
    id: 'equality',
    title: 'Generate ==() and hashCode…',
    disabledReason: 'a field is not final (mutableClass)',
  },
  {
    id: 'copyWith',
    title: 'Generate copyWith()',
    disabledReason: null,
    edits: [{ offset: 0, length: 0, text: '// copyWith\n' }],
    replaces: false,
  },
];

describe('code actions', () => {
  const disposables: vscode.Disposable[] = [];
  let helper: FakeHelper;
  let picker: FakePicker;
  let editor: vscode.TextEditor;
  let generator: Generator;

  beforeEach(async () => {
    helper = new FakeHelper();
    picker = new FakePicker();
    helper.answers.actions = () => menu;
    generator = register(disposables, helper, picker.pick).generator;
    editor = await openPoint(pointText);
    editor.selection = new vscode.Selection(0, 6, 0, 6);
  });

  afterEach(async () => {
    dispose(disposables);
    await vscode.commands.executeCommand('workbench.action.revertAndCloseActiveEditor');
  });

  async function codeActions(kind?: string): Promise<vscode.CodeAction[]> {
    return vscode.commands.executeCommand<vscode.CodeAction[]>(
      'vscode.executeCodeActionProvider',
      editor.document.uri,
      editor.selection,
      kind,
    );
  }

  /**
   * Calls [target] as VS Code does for a request of [only]. A direct call
   * sees disabled actions, and VS Code's own automatic requests cannot race
   * it.
   */
  function provide(
    only?: vscode.CodeActionKind,
    target = generator,
    diagnostics: vscode.Diagnostic[] = [],
  ) {
    return target.provideCodeActions(
      editor.document,
      editor.selection,
      { only, diagnostics, triggerKind: vscode.CodeActionTriggerKind.Invoke },
      new vscode.CancellationTokenSource().token,
    );
  }

  it('Generate… resolves once and lists the extension kinds with reasons', async () => {
    await vscode.commands.executeCommand('dartGenerate.generate');
    await vscode.commands.executeCommand('hideCodeActionWidget');
    // vscode.executeCodeActionProvider drops disabled actions, so this asks
    // the provider directly, with the kind that the menu asks for.
    const actions = await provide(generateKind);
    assert.deepStrictEqual(
      actions.map((a) => [a.kind?.value, a.disabled?.reason]),
      [
        ['refactor.generate.dartGenerate.dataClass', undefined],
        ['refactor.generate.dartGenerate.toString', undefined],
        ['refactor.generate.dartGenerate.equality', 'a field is not final (mutableClass)'],
        ['refactor.generate.dartGenerate.copyWith', undefined],
      ],
    );
    // VS Code may add automatic requests of its own. Generate… asked once.
    assert.strictEqual(helper.called('actions').filter((c) => c.explicit).length, 1);
  });

  it('a Generate… request does not list the plugin kinds', async () => {
    disposables.push(
      vscode.languages.registerCodeActionsProvider('dart', {
        provideCodeActions: () => [
          new vscode.CodeAction(
            'Generate toString()',
            vscode.CodeActionKind.Refactor.append('generate').append('toString'),
          ),
        ],
      }),
    );
    const kinds = (await codeActions(generateKind.value)).map((a) => a.kind?.value);
    assert.ok(!kinds.includes('refactor.generate.toString'), `${kinds}`);
  });

  it('Cmd+. asks without explicit, and a source request asks nothing', async () => {
    // A provider that VS Code does not know, so only these calls reach it.
    const own = new FakeHelper();
    const unregistered = new Generator(own, picker.pick);
    await provide(undefined, unregistered);
    await provide(vscode.CodeActionKind.Source.append('organizeImports'), unregistered);
    assert.deepStrictEqual(
      own.called('actions').map((c) => c.explicit),
      [false],
    );
  });

  it('a plain edit applies at once', async () => {
    const copyWith = (await provide(generateKind)).find(
      (a) => a.kind?.value === 'refactor.generate.dartGenerate.copyWith',
    )!;
    await vscode.workspace.applyEdit(copyWith.edit!);
    assert.ok(editor.document.getText().startsWith('// copyWith\n'));
  });

  it('a replacement waits in the refactor preview', async () => {
    helper.answers.generate = () => ({
      edits: [{ offset: 0, length: 5, text: 'final class' }],
      replaces: true,
      skipped: [],
    });
    const done = vscode.commands.executeCommand('dartGenerate.run', editor.document.uri, {
      id: 'json',
      title: 'Regenerate toJson() and fromJson()',
      offset: 6,
      length: 0,
    });
    // The preview opens after a moment, with the change unticked. Until the
    // run ends, the text stays as it was, and Discard ends the run.
    let ended = false;
    void done.then(() => (ended = true));
    while (!ended) {
      assert.strictEqual(editor.document.getText(), pointText, 'applied without a preview');
      await vscode.commands.executeCommand('refactorPreview.discard');
      await new Promise((r) => setTimeout(r, 50));
    }
    assert.strictEqual(editor.document.getText(), pointText);
  });

  it('the picker opens with the ticks of the pick', async () => {
    picker.answer = ['y'];
    helper.answers.generate = () => ({ edits: [], replaces: false, skipped: [] });
    const toString = (await provide(generateKind)).find(
      (a) => a.kind?.value === 'refactor.generate.dartGenerate.toString',
    )!;
    await vscode.commands.executeCommand(
      toString.command!.command,
      ...toString.command!.arguments!,
    );
    assert.deepStrictEqual(picker.opened, [{ title: 'Generate toString()', ticked: ['x'] }]);
    assert.deepStrictEqual(helper.called('generate')[0].params.fields, ['y']);
  });

  it('Escape in the picker changes nothing', async () => {
    picker.answer = undefined;
    await vscode.commands.executeCommand('dartGenerate.run', editor.document.uri, {
      id: 'toString',
      title: 'Generate toString()',
      offset: 6,
      length: 0,
      pick: menu[1].pick,
    });
    assert.strictEqual(helper.called('generate').length, 0);
  });

  it('a quick fix on a hint opens the picker with every field ticked', async () => {
    picker.answer = ['x', 'y'];
    helper.answers.generate = () => ({ edits: [], replaces: false, skipped: [] });
    const diagnostic = new vscode.Diagnostic(
      new vscode.Range(0, 6, 0, 11),
      'toString() does not show y.',
      vscode.DiagnosticSeverity.Hint,
    );
    diagnostic.source = 'dart_generate';
    diagnostic.code = 'toString';
    const fix = (await provide(undefined, generator, [diagnostic]))[0];
    assert.strictEqual(fix.kind?.value, fixKind.value);
    assert.ok(fix.isPreferred);
    assert.strictEqual(fix.title, 'Regenerate toString()…');
    await vscode.commands.executeCommand(fix.command!.command, ...fix.command!.arguments!);
    assert.deepStrictEqual(picker.opened, [
      { title: 'Regenerate toString()', ticked: ['x', 'y'] },
    ]);
  });

  it('asks again when the document changes during the request', async () => {
    let first = true;
    helper.answers.generate = async () => {
      if (first) {
        first = false;
        await editor.edit((b) => b.insert(new vscode.Position(0, 0), '// typed\n'));
      }
      return { edits: [{ offset: 0, length: 0, text: '// generated\n' }], replaces: false, skipped: [] };
    };
    await vscode.commands.executeCommand('dartGenerate.run', editor.document.uri, {
      id: 'dataClass',
      title: 'Generate data class',
      offset: 6,
      length: 0,
    });
    assert.strictEqual(helper.called('generate').length, 2);
    assert.ok(editor.document.getText().startsWith('// generated\n// typed\n'));
  });
});
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `cd vscode && npm test`
Expected: FAIL in `pretest` with `error TS2307: Cannot find module '../../src/actions'`.

- [ ] **Step 3: Write the actions and the activation**

Create `vscode/src/actions.ts`:

```ts
import * as vscode from 'vscode';
import {
  Action,
  documentParams,
  Generated,
  Helper,
  Pick,
  served,
  workspaceEdit,
} from './protocol';

/** The extension's kinds. The plugin's kinds are `refactor.generate.<id>`. */
export const generateKind = vscode.CodeActionKind.Refactor.append('generate').append(
  'dartGenerate',
);
export const fixKind = vscode.CodeActionKind.QuickFix.append('dartGenerate');

/** Opens a field picker. Resolves to the picked names, or `undefined`. */
export type Picker = (
  title: string,
  fields: Pick['fields'],
  ticked: string[],
) => Promise<string[] | undefined>;

/** What `dartGenerate.run` gets from a menu item or a quick fix. */
export interface Run {
  id: string;
  /** The title without "…", for the picker. */
  title: string;
  offset: number;
  length: number;
  pick?: Pick;
  /** A quick fix on a hint: the picker opens with every field ticked. */
  tickAll?: boolean;
}

const fixTitles: Record<string, string> = {
  toString: 'Regenerate toString()…',
  equality: 'Regenerate ==() and hashCode…',
  copyWith: 'Regenerate copyWith()',
  json: 'Regenerate toJson() and fromJson()',
};

/** The Generate… command, the code action provider and the quick fixes. */
export class Generator implements vscode.CodeActionProvider {
  /** The last Generate… result, so the menu does not resolve again. */
  private menu?: { key: string; actions: Action[] };

  constructor(
    private readonly helper: Helper,
    private readonly pick: Picker,
  ) {}

  /** Generate…: asks for every action, then opens the menu with them. */
  async generate(): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor || !served(editor.document)) return;
    const document = editor.document;
    const params = documentParams(document, editor.selection);
    const actions = await this.helper.request<Action[]>(
      'actions',
      { ...params, explicit: true },
      true,
    );
    if (!actions) return;
    if (actions.length === 0) {
      vscode.window.setStatusBarMessage('Put the cursor inside a class.', 5000);
      return;
    }
    this.menu = { key: menuKey(document, params), actions };
    await vscode.commands.executeCommand('editor.action.codeAction', {
      kind: generateKind.value,
      apply: 'never',
    });
  }

  async provideCodeActions(
    document: vscode.TextDocument,
    range: vscode.Range,
    context: vscode.CodeActionContext,
    token: vscode.CancellationToken,
  ): Promise<vscode.CodeAction[]> {
    if (!served(document)) return [];
    const result = context.diagnostics
      .filter((d) => d.source === 'dart_generate')
      .map((d) => this.fix(document, d));
    // Code actions on save ask for `source.*` kinds: no request then.
    if (context.only && !generateKind.intersects(context.only)) return result;
    const explicit = context.only !== undefined && generateKind.contains(context.only);
    const params = documentParams(document, range);
    const key = menuKey(document, params);
    const actions =
      explicit && this.menu?.key === key
        ? this.menu.actions
        : await this.helper.request<Action[]>(
            'actions',
            { ...params, explicit },
            explicit,
            token,
          );
    for (const action of actions ?? []) {
      result.push(this.codeAction(document, params, action));
    }
    return result;
  }

  private codeAction(
    document: vscode.TextDocument,
    params: { offset: number; length: number },
    action: Action,
  ): vscode.CodeAction {
    const item = new vscode.CodeAction(action.title, generateKind.append(action.id));
    if (action.disabledReason) {
      item.disabled = { reason: action.disabledReason };
    } else if (action.edits) {
      item.edit = workspaceEdit(document, action.edits, action.replaces ?? false);
    } else {
      const run: Run = {
        id: action.id,
        title: action.title.replace(/…$/, ''),
        offset: params.offset,
        length: params.length,
        pick: action.pick,
      };
      item.command = {
        title: action.title,
        command: 'dartGenerate.run',
        arguments: [document.uri, run],
      };
    }
    return item;
  }

  /** "Regenerate X" for a stale member, marked as preferred. */
  private fix(
    document: vscode.TextDocument,
    diagnostic: vscode.Diagnostic,
  ): vscode.CodeAction {
    const id = String(diagnostic.code);
    const item = new vscode.CodeAction(fixTitles[id], fixKind);
    item.diagnostics = [diagnostic];
    item.isPreferred = true;
    const run: Run = {
      id,
      title: fixTitles[id].replace(/…$/, ''),
      offset: document.offsetAt(diagnostic.range.start),
      length: 0,
      tickAll: true,
    };
    item.command = {
      title: item.title,
      command: 'dartGenerate.run',
      arguments: [document.uri, run],
    };
    return item;
  }

  /**
   * Runs an action that needs a picker, a composite action, or a quick fix.
   * If the document changes during the request, it asks again.
   */
  async run(uri: vscode.Uri, run: Run): Promise<void> {
    const document = vscode.workspace.textDocuments.find(
      (d) => d.uri.toString() === uri.toString(),
    );
    if (!document) return;
    const range = new vscode.Range(
      document.positionAt(run.offset),
      document.positionAt(run.offset + run.length),
    );
    let fields: string[] | undefined;
    let pick = run.pick;
    if (!pick && run.tickAll && (run.id === 'toString' || run.id === 'equality')) {
      const actions = await this.helper.request<Action[]>(
        'actions',
        { ...documentParams(document, range), explicit: true },
        true,
      );
      pick = actions?.find((a) => a.id === run.id)?.pick;
      if (!pick) return;
    }
    if (pick) {
      const ticked = run.tickAll ? pick.fields.map((f) => f.name) : pick.ticked;
      fields = await this.pick(run.title, pick.fields, ticked);
      if (!fields) return;
    }
    for (let attempt = 0; attempt < 3; attempt++) {
      const version = document.version;
      const result = await this.helper.request<Generated>(
        'generate',
        { ...documentParams(document, range), action: run.id, fields },
        true,
      );
      if (!result) return;
      if (document.version !== version) continue;
      if (result.edits.length > 0) {
        await vscode.workspace.applyEdit(
          workspaceEdit(document, result.edits, result.replaces),
        );
      }
      if (result.skipped.length > 0) {
        void vscode.window.showInformationMessage(
          `Skipped ${result.skipped.join('; ')}`,
        );
      }
      return;
    }
  }
}

function menuKey(
  document: vscode.TextDocument,
  params: { offset: number; length: number },
): string {
  return `${document.uri} ${document.version} ${params.offset} ${params.length}`;
}

/** The field picker: a QuickPick with a tick box for each field. */
export const quickPick: Picker = (title, fields, ticked) =>
  new Promise((resolve) => {
    const picker = vscode.window.createQuickPick<vscode.QuickPickItem & { name: string }>();
    picker.title = title;
    picker.canSelectMany = true;
    picker.items = fields.map((f) => ({ label: f.name, description: f.type, name: f.name }));
    picker.selectedItems = picker.items.filter((i) => ticked.includes(i.name));
    let picked: string[] | undefined;
    picker.onDidAccept(() => {
      if (picker.selectedItems.length === 0) {
        picker.prompt = 'Pick at least one field';
        return;
      }
      picked = picker.selectedItems.map((i) => i.name);
      picker.hide();
    });
    picker.onDidHide(() => {
      picker.dispose();
      resolve(picked);
    });
    picker.show();
  });
```

Create `vscode/src/extension.ts`:

```ts
import * as vscode from 'vscode';
import { Generator, generateKind, fixKind, Picker, quickPick, Run } from './actions';
import { HelperProcess } from './helper';
import { Helper, served } from './protocol';
import { dartApi, sdkFromPath } from './sdk';

export async function activate(context: vscode.ExtensionContext): Promise<void> {
  const channel = vscode.window.createOutputChannel('Dart Generate', { log: true });
  const dart = await dartApi();
  const helper = new HelperProcess(
    context.asAbsolutePath('bin/helper'),
    [],
    () => {
      const sdkPath = dart?.sdks.dart ?? sdkFromPath();
      if (!sdkPath) {
        channel.error('No Dart SDK: install the Dart extension or put dart on PATH.');
        return undefined;
      }
      const folders = (vscode.workspace.workspaceFolders ?? [])
        .filter((f) => f.uri.scheme === 'file')
        .map((f) => f.uri.fsPath);
      return { sdkPath, folders };
    },
    channel,
    (message) => {
      void vscode.window
        .showErrorMessage(`Dart Generate: ${message}`, 'Show Output')
        .then((choice) => choice && channel.show());
    },
  );
  context.subscriptions.push(
    channel,
    helper,
    vscode.commands.registerCommand('dartGenerate.restartHelper', () => helper.start()),
    vscode.commands.registerCommand('dartGenerate.showOutput', () => channel.show()),
    vscode.workspace.onDidChangeWorkspaceFolders(() => helper.start()),
  );
  if (dart) context.subscriptions.push(dart.onSdksChanged(() => void helper.start()));
  register(context.subscriptions, helper, quickPick);
  await helper.start();
}

/**
 * Registers the provider and the commands on [helper]. The tests call it
 * with a fake helper and a fake picker.
 */
export function register(
  subscriptions: vscode.Disposable[],
  helper: Helper,
  pick: Picker,
): { generator: Generator } {
  const generator = new Generator(helper, pick);
  const watcher = vscode.workspace.createFileSystemWatcher('**/*.dart');
  const changed = (uri: vscode.Uri) =>
    helper.notify('filesChanged', { paths: [uri.fsPath] });
  subscriptions.push(
    watcher,
    vscode.languages.registerCodeActionsProvider(
      { language: 'dart', scheme: 'file' },
      generator,
      { providedCodeActionKinds: [generateKind, fixKind] },
    ),
    vscode.commands.registerCommand('dartGenerate.generate', () => generator.generate()),
    vscode.commands.registerCommand('dartGenerate.run', (uri: vscode.Uri, run: Run) =>
      generator.run(uri, run),
    ),
    vscode.workspace.onDidCloseTextDocument((document) => {
      if (served(document)) helper.notify('closed', { path: document.uri.fsPath });
    }),
    watcher.onDidChange(changed),
    watcher.onDidCreate(changed),
    watcher.onDidDelete(changed),
  );
  return { generator };
}
```

- [ ] **Step 4: Run the checks and the suite**

Run: `cd vscode && npm run check && npm test`
Expected: `14 passing`.

- [ ] **Step 5: Commit**

```bash
git add vscode/src vscode/test/suite
git commit -m "Add Generate…, the code actions, the pickers and the quick fixes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Marks on stale members

**Files:**
- Create: `vscode/src/stale.ts`
- Modify: `vscode/src/extension.ts`
- Test: `vscode/test/suite/stale.test.ts`

**Interfaces:**
- Consumes: `Helper`, `served` and `StaleResult` from Task 7, and `register` from Task 8.
- Produces: `StaleScan(helper)` with `diagnostics`, `schedule(document)`, `scanVisible()`, `scan(document)`, `closed(document)` and `dispose()`. `register` returns `{generator, stale}`.

- [ ] **Step 1: Write the failing test**

Create `vscode/test/suite/stale.test.ts`:

```ts
import * as assert from 'node:assert';
import * as vscode from 'vscode';
import { StaleScan } from '../../src/stale';
import { FakeHelper, openPoint, pointText } from './fakes';

describe('stale members', () => {
  let helper: FakeHelper;
  let scan: StaleScan;
  let editor: vscode.TextEditor;

  beforeEach(async () => {
    helper = new FakeHelper();
    scan = new StaleScan(helper);
    editor = await openPoint(pointText);
  });

  afterEach(async () => {
    scan.dispose();
    await vscode.commands.executeCommand('workbench.action.revertAndCloseActiveEditor');
  });

  const items = {
    items: [
      {
        offset: 6,
        length: 5,
        id: 'copyWith',
        severity: 'warning',
        message: 'copyWith() does not cover y.',
        missing: ['y'],
      },
      {
        offset: 21,
        length: 1,
        id: 'toString',
        severity: 'hint',
        message: 'toString() does not show y.',
        missing: ['y'],
      },
    ],
  };

  function marks(): [string, vscode.DiagnosticSeverity, string | number | undefined][] {
    return scan.diagnostics
      .get(editor.document.uri)!
      .map((d) => [d.message, d.severity, d.code as string]);
  }

  it('turns items into warnings and hints with the member range', async () => {
    helper.answers.stale = () => items;
    await scan.scan(editor.document);
    assert.deepStrictEqual(marks(), [
      ['copyWith() does not cover y.', vscode.DiagnosticSeverity.Warning, 'copyWith'],
      ['toString() does not show y.', vscode.DiagnosticSeverity.Hint, 'toString'],
    ]);
    const range = scan.diagnostics.get(editor.document.uri)![0].range;
    assert.strictEqual(editor.document.getText(range), 'Point');
  });

  it('keeps the previous marks for a file with a syntax error', async () => {
    helper.answers.stale = () => items;
    await scan.scan(editor.document);
    helper.answers.stale = () => ({ skipped: true });
    await scan.scan(editor.document);
    assert.strictEqual(marks().length, 2);
  });

  it('drops a result for an older version of the document', async () => {
    helper.answers.stale = async () => {
      await editor.edit((b) => b.insert(new vscode.Position(0, 0), '// typed\n'));
      return items;
    };
    await scan.scan(editor.document);
    assert.strictEqual(scan.diagnostics.get(editor.document.uri)?.length ?? 0, 0);
  });

  it('clears the marks of a closed document', async () => {
    helper.answers.stale = () => items;
    await scan.scan(editor.document);
    scan.closed(editor.document);
    assert.strictEqual(scan.diagnostics.get(editor.document.uri)?.length ?? 0, 0);
  });
});
```

- [ ] **Step 2: Run the test to see it fail**

Run: `cd vscode && npm test`
Expected: FAIL in `pretest` with `error TS2307: Cannot find module '../../src/stale'`.

- [ ] **Step 3: Write the scan and wire it in**

Create `vscode/src/stale.ts`:

```ts
import * as vscode from 'vscode';
import { Helper, served, StaleResult } from './protocol';

/** The marks on stale generated members (ADR 0008). */
export class StaleScan implements vscode.Disposable {
  readonly diagnostics = vscode.languages.createDiagnosticCollection('dart_generate');
  private readonly timers = new Map<string, NodeJS.Timeout>();

  constructor(private readonly helper: Helper) {}

  /** Scans [document] 500 ms after the last call for it. */
  schedule(document: vscode.TextDocument): void {
    const key = document.uri.toString();
    clearTimeout(this.timers.get(key));
    this.timers.set(
      key,
      setTimeout(() => {
        this.timers.delete(key);
        void this.scan(document);
      }, 500),
    );
  }

  /** Scans each document that a visible editor shows. */
  scanVisible(): void {
    const documents = new Set(vscode.window.visibleTextEditors.map((e) => e.document));
    for (const document of documents) void this.scan(document);
  }

  async scan(document: vscode.TextDocument): Promise<void> {
    if (!served(document)) return;
    const version = document.version;
    const result = await this.helper.request<StaleResult>(
      'stale',
      { path: document.uri.fsPath, text: document.getText() },
      false,
    );
    // A syntax error keeps the previous marks, so they do not flicker.
    if (!result || 'skipped' in result) return;
    if (document.isClosed || document.version !== version) return;
    this.diagnostics.set(
      document.uri,
      result.items.map((item) => {
        const range = new vscode.Range(
          document.positionAt(item.offset),
          document.positionAt(item.offset + item.length),
        );
        const diagnostic = new vscode.Diagnostic(
          range,
          item.message,
          item.severity === 'warning'
            ? vscode.DiagnosticSeverity.Warning
            : vscode.DiagnosticSeverity.Hint,
        );
        diagnostic.source = 'dart_generate';
        diagnostic.code = item.id;
        return diagnostic;
      }),
    );
  }

  closed(document: vscode.TextDocument): void {
    clearTimeout(this.timers.get(document.uri.toString()));
    this.diagnostics.delete(document.uri);
  }

  dispose(): void {
    for (const timer of this.timers.values()) clearTimeout(timer);
    this.diagnostics.dispose();
  }
}
```

Apply this patch from the repo root:

```bash
git apply <<'PATCH'
--- a/vscode/src/extension.ts
+++ b/vscode/src/extension.ts
@@ -3,6 +3,7 @@
 import { HelperProcess } from './helper';
 import { Helper, served } from './protocol';
 import { dartApi, sdkFromPath } from './sdk';
+import { StaleScan } from './stale';
 
 export async function activate(context: vscode.ExtensionContext): Promise<void> {
   const channel = vscode.window.createOutputChannel('Dart Generate', { log: true });
@@ -27,6 +28,8 @@
         .showErrorMessage(`Dart Generate: ${message}`, 'Show Output')
         .then((choice) => choice && channel.show());
     },
+    // The stale scan of the visible files also resolves them.
+    () => stale.scanVisible(),
   );
   context.subscriptions.push(
     channel,
@@ -36,24 +39,29 @@
     vscode.workspace.onDidChangeWorkspaceFolders(() => helper.start()),
   );
   if (dart) context.subscriptions.push(dart.onSdksChanged(() => void helper.start()));
-  register(context.subscriptions, helper, quickPick);
+  const { stale } = register(context.subscriptions, helper, quickPick);
   await helper.start();
 }
 
 /**
- * Registers the provider and the commands on [helper]. The tests call it
- * with a fake helper and a fake picker.
+ * Registers the provider, the commands and the stale scan on [helper]. The
+ * tests call it with a fake helper and a fake picker.
  */
 export function register(
   subscriptions: vscode.Disposable[],
   helper: Helper,
   pick: Picker,
-): { generator: Generator } {
+): { generator: Generator; stale: StaleScan } {
   const generator = new Generator(helper, pick);
+  const stale = new StaleScan(helper);
   const watcher = vscode.workspace.createFileSystemWatcher('**/*.dart');
-  const changed = (uri: vscode.Uri) =>
+  // A checkout changes many files at once. schedule() waits for the last one.
+  const changed = (uri: vscode.Uri) => {
     helper.notify('filesChanged', { paths: [uri.fsPath] });
+    for (const editor of vscode.window.visibleTextEditors) stale.schedule(editor.document);
+  };
   subscriptions.push(
+    stale,
     watcher,
     vscode.languages.registerCodeActionsProvider(
       { language: 'dart', scheme: 'file' },
@@ -64,12 +72,19 @@
     vscode.commands.registerCommand('dartGenerate.run', (uri: vscode.Uri, run: Run) =>
       generator.run(uri, run),
     ),
+    vscode.window.onDidChangeVisibleTextEditors(() => stale.scanVisible()),
+    vscode.workspace.onDidChangeTextDocument((e) => {
+      if (vscode.window.visibleTextEditors.some((v) => v.document === e.document)) {
+        stale.schedule(e.document);
+      }
+    }),
     vscode.workspace.onDidCloseTextDocument((document) => {
+      stale.closed(document);
       if (served(document)) helper.notify('closed', { path: document.uri.fsPath });
     }),
     watcher.onDidChange(changed),
     watcher.onDidCreate(changed),
     watcher.onDidDelete(changed),
   );
-  return { generator };
+  return { generator, stale };
 }
PATCH
```

- [ ] **Step 4: Run the checks and the suite**

Run: `cd vscode && npm run check && npm test`
Expected: `18 passing`.

- [ ] **Step 5: Commit**

```bash
git add vscode/src vscode/test/suite
git commit -m "Mark stale generated members in visible Dart editors

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Packaging and the smoke test

**Files:**
- Create: `vscode/scripts/package.sh`, `vscode/.vscodeignore`
- Test: `vscode/test/suite/smoke.test.ts`

**Interfaces:**
- Consumes: `HelperProcess`, `register`, `sdkFromPath` and `generateKind`.
- Produces: `vscode/dart-generate-0.1.0.vsix` and `vscode/bin/helper`. Git ignores both.

- [ ] **Step 1: Write the smoke test**

Create `vscode/test/suite/smoke.test.ts`:

```ts
import * as assert from 'node:assert';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import * as vscode from 'vscode';
import { generateKind } from '../../src/actions';
import { register } from '../../src/extension';
import { HelperProcess } from '../../src/helper';
import { sdkFromPath } from '../../src/sdk';
import { dispose, FakePicker, openPoint } from './fakes';

/** Runs only after `npm run package` built bin/helper. */
describe('smoke: the compiled helper', function () {
  const binary = resolve(__dirname, '../../../bin/helper');
  const disposables: vscode.Disposable[] = [];

  before(function () {
    if (!existsSync(binary)) this.skip();
  });

  after(async () => {
    dispose(disposables);
    await vscode.commands.executeCommand('workbench.action.revertAndCloseActiveEditor');
  });

  it('lists the menu and marks a stale toString', async () => {
    const channel = vscode.window.createOutputChannel('Dart Generate smoke', { log: true });
    const folder = vscode.workspace.workspaceFolders![0].uri.fsPath;
    const helper = new HelperProcess(
      binary,
      [],
      () => ({ sdkPath: sdkFromPath()!, folders: [folder] }),
      channel,
      () => assert.fail('the helper crashed'),
    );
    disposables.push(channel, helper);
    await helper.start();
    const { generator, stale } = register(disposables, helper, new FakePicker().pick);
    const editor = await openPoint(`class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

  @override
  String toString() => 'Point(x: $x)';
}
`);
    const actions = await generator.provideCodeActions(
      editor.document,
      new vscode.Range(0, 6, 0, 6),
      { only: generateKind, diagnostics: [], triggerKind: vscode.CodeActionTriggerKind.Invoke },
      new vscode.CancellationTokenSource().token,
    );
    assert.deepStrictEqual(
      actions.map((a) => a.title),
      [
        'Regenerate data class',
        'Regenerate toString()…',
        'Generate ==() and hashCode…',
        'Generate copyWith()',
        'Generate toJson() and fromJson()',
        'Generate getter…',
        'Convert to primary constructor',
      ],
    );
    await stale.scan(editor.document);
    assert.deepStrictEqual(
      stale.diagnostics.get(editor.document.uri)!.map((d) => d.message),
      ['toString() does not show y.'],
    );
  });

  it('says that it did not start for a wrong SDK path', async () => {
    const channel = vscode.window.createOutputChannel('Dart Generate smoke', { log: true });
    let helper: HelperProcess | undefined;
    const failed = new Promise<string>((resolve) => {
      helper = new HelperProcess(
        binary,
        [],
        () => ({ sdkPath: '/no/such/sdk', folders: [] }),
        channel,
        resolve,
      );
      void helper.start();
    });
    disposables.push(channel, helper!);
    assert.strictEqual(await failed, 'the helper did not start.');
  });
});
```

- [ ] **Step 2: Run the suite without the binary**

Run: `cd vscode && npm test`
Expected: `18 passing` and `2 pending`. The smoke tests skip themselves until `bin/helper` exists.

- [ ] **Step 3: Write the packaging script and the ignore file**

Create `vscode/scripts/package.sh`:

```sh
#!/bin/sh
# Builds dart-generate-<version>.vsix for macOS arm64: the helper binary, the
# bundle, the package, and a check that the helper keeps its executable bit.
set -eu
cd "$(dirname "$0")/.."

mkdir -p bin
dart compile exe ../helper/bin/helper.dart -o bin/helper
npm run compile

version=$(node -p "require('./package.json').version")
vsix="dart-generate-$version.vsix"
# esbuild bundles every dependency, so vsce needs no npm dependency scan.
npx vsce package --target darwin-arm64 --no-dependencies --skip-license \
  --allow-missing-repository --out "$vsix"

# Without the executable bit, the installed helper cannot start.
mode=$(unzip -Z "$vsix" extension/bin/helper | cut -c1-10)
if [ "$mode" != "-rwxr-xr-x" ]; then
  echo "extension/bin/helper has mode $mode, not -rwxr-xr-x" >&2
  exit 1
fi

echo "Install with: code --install-extension $PWD/$vsix"
```

Create `vscode/.vscodeignore`:

```text
# The .vsix holds package.json, dist/extension.js and bin/helper.
.vscode-test/**
node_modules/**
out/**
scripts/**
src/**
test/**
*.vsix
eslint.config.mjs
tsconfig.json
```

- [ ] **Step 4: Build the package**

Run: `cd vscode && npm run package`
Expected: `DONE  Packaged: dart-generate-0.1.0.vsix (5 files, 7.02 MB)`, then `Install with: code --install-extension …/dart-generate-0.1.0.vsix`. If `extension/bin/helper` in the `.vsix` file has a mode other than `-rwxr-xr-x`, the script fails.

If `vsce` reports `Extension entrypoint(s) missing`, the dependency scan ran. Make sure that the script passes `--no-dependencies`.

- [ ] **Step 5: Run the suite with the binary**

Run: `cd vscode && npm run check && npm test`
Expected: `20 passing`. The smoke tests start `bin/helper` on `test/workspace`, and once with a wrong SDK path. They take about 1 s.

- [ ] **Step 6: Commit**

```bash
git add vscode/scripts/package.sh vscode/.vscodeignore vscode/test/suite/smoke.test.ts
git commit -m "Package the extension for macOS arm64 and add the smoke test

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: The README, a full test run and the manual steps

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Delete the plugin's VS Code key binding**

The block is lines 32 to 44: the sentence about the key, its JSON, the sentence after the JSON and one blank line. Delete it from the repo root:

```bash
sed -i '' '32,44d' README.md
sed -n 30,32p README.md
```

Expected output:

```text
compiles the new code.

Zed shows the actions in its code action menu (Cmd+.). It has no filter by kind.
```

- [ ] **Step 2: Add the extension section**

Apply this patch from the repo root:

```bash
git apply <<'PATCH'
--- a/README.md
+++ b/README.md
@@ -3,12 +3,49 @@
 Generate actions for Dart classes in VS Code and Zed: toString, `==` and hashCode,
 copyWith, toJson and fromJson, a getter for a private field, and "Convert to primary
-constructor". It is an analyzer plugin, so it reads classes with the real analyzer.
-Primary constructors and class modifiers work.
+constructor". They read classes with the real analyzer, so primary constructors and
+class modifiers work.
 
-The design is in `docs/superpowers/specs/2026-09-28-dart-generate-design.md`. The
-decisions are in `docs/adr/`.
+VS Code uses the extension in `vscode/`. Zed uses the analyzer plugin in `plugin/`.
+Both run the same assists, so they write the same code.
 
-## Setup
+The designs are in `docs/superpowers/specs/`. The decisions are in `docs/adr/`.
 
+## VS Code extension
+
+To install or update the extension:
+
+1. In `vscode/`, run `npm install` once. Then run `npm run package`.
+2. Run the `code --install-extension` command that the script prints. If you use
+   a VS Code profile for Dart, add `--profile` and its name, for example
+   `--profile "Dart & Flutter"`. Without it, the extension goes into the default
+   profile only.
+3. Run "Developer: Reload Window" in each open VS Code window.
+
+VS Code keeps one profile for each folder. To open a folder in the profile that has
+the extension, run `code --profile "Dart & Flutter" <folder>` once.
+
+After a Dart SDK upgrade, run `dart test` in `helper/`. Then build and install the
+extension again. If the SDK and the helper differ in the minor version, the extension
+shows a warning once.
+
+In a Dart editor, Cmd+N opens Generate…, a menu with every action. An action that
+does not apply is greyed out with its reason. toString and `==` open a field picker.
+The actions also appear in Cmd+. and the lightbulb.
+
+A regenerated member replaces the old one, so the refactor preview opens first. The
+change starts unticked. Tick it, then choose Apply.
+
+A generated member that no longer covers every field gets a mark. copyWith, toJson
+and fromJson get a warning, and toString and `==` get a hint. Its quick fix
+regenerates the member.
+
+If a project's `analysis_options.yaml` enables the plugin, Cmd+. shows only the
+plugin's actions. Generate… still works there.
+
+If an action fails, run "Dart Generate: Show Output". "Dart Generate: Restart
+Helper" starts the helper again.
+
+## Plugin setup
+
 1. Add these lines to `analysis_options.yaml` in the project. Do not commit them.
 
@@ -32,5 +69,5 @@
 Zed shows the actions in its code action menu (Cmd+.). It has no filter by kind.
 
-## Troubleshooting
+## Plugin troubleshooting
 
 1. If no action appears, run `dart analyze` in the project.
PATCH
```

The replay's README passed the `simple-english` hook.

- [ ] **Step 3: Run every package**

Run each line from the repo root:

```bash
(cd core && dart analyze && dart test)
(cd plugin && dart analyze && dart test)
(cd fixtures && dart analyze && dart test)
(cd helper && dart analyze && dart format --output=none --set-exit-if-changed . && dart test)
(cd vscode && npm run check && npm test)
```

Expected: `No issues found!` for each Dart package. Then core `+51`, plugin `+21`, fixtures `+20`, helper `+32` and the extension `20 passing`. The core test `every reason has a row in the README` passes, so each `Reason` still has its README row.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "Describe the VS Code extension in the README

The plugin's cmd+n binding goes: a user keybinding wins over the
extension's, so it would hide Generate….

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Ask the user to install the extension and to do the manual steps**

Installing changes the user's VS Code, so ask the user first. weather_cli opens in the VS Code profile "Dart & Flutter", so the user adds `--profile "Dart & Flutter"` to the install command from Task 10. Then the user runs "Developer: Reload Window". The user does these five steps in `~/Projects/weather_cli`. VS Code is a click-only app for an agent, so the user types there.

1. Press Cmd+N in `lib/src/data/models/current_weather_model.dart`. Read the menu and its reasons.
2. Pick two fields for toString and apply. A hint then marks toString, because it leaves out three fields.
3. Choose "Regenerate toJson() and fromJson()". The preview shows `'temperature_2m'` replaced, with the change unticked. Choose Discard.
4. Add `final double pressure;` and `required this.pressure`. A warning appears on fromJson: "fromJson() does not cover pressure."
5. Open "Generate getter…" in `lib/src/data/datasources/forecast_remote_data_source.dart` and tick `_timeout`.

After the steps, the user undoes the edits in `weather_cli`. weather_cli no longer enables the plugin, so Cmd+. there shows the extension's actions too.

## Decisions after review

The user made these choices on 2026-09-29, after the plan was written:

1. A replacement keeps `needsConfirmation`. The preview opens with the change unticked, and the user ticks it before Apply. So every replace path shows a preview, the picker and the quick fixes too.
2. weather_cli no longer enables the plugin. Its local `plugins:` block is gone, so VS Code's Cmd+. there shows the extension's actions.
3. An uncommitted field move in weather_cli's `current_weather_model.dart` was reverted. The manual steps start from the committed file.
4. The plan runs with superpowers:subagent-driven-development. The user gives the word to start.

After a later audit, the user chose four more:

1. The preview test discards until the run ends, in place of a fixed 1 s wait. The preview opens after about 115 ms.
2. If the helper cannot start, the extension shows one error with "Show Output". This covers no SDK and an error answer to `initialize`, such as a wrong SDK path.
3. The extension goes into the profile "Dart & Flutter" only. When a folder such as darty opens with `code --profile "Dart & Flutter"`, it gets that profile.
4. The plugin plan's leftovers went to the Trash: `~/.dartServer/.plugin_manager` and `.superpowers/sdd/2026-09-28-dart-generate/`.

During execution, the user chose these fixes over the plan's code:

1. The helper's overlay reaches every analysis context (`workspace.dart`).
2. The stale scan counts a constructor's field initializer as a use (ADR 0008 rule 3).
3. A failed `initialize` stops the helper.
4. The `served` test has one row per check.
5. Generate… keys its menu by the version it asked for.
6. A failed Dart extension falls back to `dart` on PATH.
7. A composite puts the request's text back on the overlay.
8. If the text before the cursor changed during a request, the run stops and does not retry.
9. `package.sh` builds on arm64 only.
10. Small hardening: no virtual workspaces, a closed connection answers `undefined`, and the test client has a timeout.
11. `main` (the super-parameter fix) is merged into this branch after this wave.
