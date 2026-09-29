# dart_generate for VS Code: design

A VS Code extension that shows the dart_generate actions with VS Code's own UI: a
Generate… menu, field pickers, a preview before a replacement, and warnings on stale
generated members. You install it once. It needs no `plugins:` block. A Dart helper
process runs the plugin's own assists, so the extension and the plugin write the same
code.

The generators, the builder rule, placement and formatting are unchanged. They are in
[the plugin design](2026-09-28-dart-generate-design.md).

## Scope

- **User.** One person, on one Mac with Apple silicon. There is no Marketplace
  publishing.
- **Editor.** VS Code 1.139 or later. Zed keeps the analyzer plugin. The plugin stays,
  and its behavior does not change.
- **Features.** The Generate… menu, the field picker, the Cmd+. actions, the preview,
  "Generate data class" and stale-member diagnostics. CodeLens and settings are not
  built.
- **In darty.** The extension runs in darty, because it changes no file until you
  pick an action. The plugin stays off in darty, as the plugin design says. When darty
  opens in the profile "Dart & Flutter", it gets the extension.

## Decisions

| ADR | Decision |
|---|---|
| [0001](../../adr/0001-analyzer-plugin-not-a-language-server.md) | An analyzer plugin for VS Code and Zed. Amended by 0007. |
| [0006](../../adr/0006-each-assist-catches-and-logs-its-own-failure.md) | Each assist catches its own failure. Amended for the helper. |
| [0007](../../adr/0007-vscode-extension-beside-the-plugin.md) | A VS Code extension beside the plugin, with a Dart helper that runs the plugin's assists |
| [0008](../../adr/0008-stale-generated-members-get-a-warning-or-a-hint.md) | A stale copyWith or JSON member gets a warning. A stale toString or `==` gets a hint. |

## Architecture

```
dart_generate/
  core/       generate_core: gains a message for each Reason.
  plugin/     dart_generate: gains lib/assists.dart and four GenerateAssist fields.
  helper/     dart_generate_helper (new): bin/helper.dart, the JSON-RPC server.
  vscode/     the TypeScript extension (new), packaged as a .vsix file.
  fixtures/   shared by the plugin e2e test and the helper e2e test.
```

The extension owns all UI. The helper owns all Dart analysis. They talk JSON-RPC 2.0
over the helper's stdin and stdout. The helper writes its log to stderr, and the
extension shows it in the "Dart Generate" output channel. That channel is a
`LogOutputChannel`, from `createOutputChannel` with `{log: true}`.

### Changes to core

`Reason` gains a `message`, which the Generate… menu shows beside a greyed-out action.

| Reason | Message |
|---|---|
| `noFields` | the class has no field that this action can use |
| `noBuilder` | no public constructor covers every field |
| `mutableClass` | a field is not final |
| `typeParameterField` | a field has a type parameter type |
| `nestedCollection` | a collection holds a collection |
| `nonStringMapKey` | a map key is not String |
| `customToString` | toString is hand-written |
| `notConvertible` | the constructor cannot move into the class header |
| `publicNameTaken` | the class already has a member with the public name |
| `notAClass` | the cursor is in an enum, a mixin or an extension type |

### Changes to the plugin

The plugin's behavior does not change. Its e2e tests pass with no edits.

- **`lib/assists.dart`** exports `GenerateAssist`, `fieldNames`, the six assist
  classes, `generatorNames`, `findMember` and `readClass`. The helper imports it, so
  it needs no `src/` import. The picker needs `fieldNames` for the fields that a
  selection covers. The stale scan needs `findMember` and `readClass`.
- **`GenerateToString.isGenerated`** becomes public. The stale scan uses it to skip
  a hand-written toString (`customToString`).
- **`GenerateAssist` gains four public fields**, in the style of the existing `verb`
  field. The server never sets them, so their defaults keep today's behavior.

| Field | Default | Effect |
|---|---|---|
| `Set<String>? fields` | `null` | Replaces the fields that the selection gives. |
| `bool anywhereInClass` | `false` | `classTarget` and the header check of `ConvertToPrimaryConstructor` accept any position inside the class. |
| `Reason? reason` | `null` | Set on every path that returns no edit for a known reason, from `NotOffered` and from the adapter checks. |
| `void Function(String generator, String file, Object error, StackTrace stack) onError` | `writeLog` | Called by the catch in `compute`. The helper replaces it. |

A new method, `enclosingClass()`, returns the class around the cursor. Inside an
`EnumDeclaration`, a `MixinDeclaration` or an `ExtensionTypeDeclaration`, it returns
`null` and sets `reason` to `notAClass`. The assists call it in place of
`thisOrAncestorOfType<ClassDeclaration>()`.

## The helper

`helper/` is the package `dart_generate_helper`. It depends on `dart_generate` and
`generate_core` by path. It names `Reason`, `Outcome`, `ParamModel`, `usedFields`
and `publicName`, so it needs `generate_core` directly. It uses no JSON-RPC package. `json_rpc_2` gives a handler
no request ID, so `$/cancelRequest` cannot find a waiting request. The helper's own
`Connection` class frames, queues and answers the messages. It imports from three
analyzer packages, so it depends on each of them directly, pinned as in the plugin:
`analysis_server_plugin: 0.3.23`, `analyzer: 14.4.0` and `analyzer_plugin: 0.14.17`.
Without them, `depend_on_referenced_packages` reports the imports.

### Transport

- **Framing.** Each message has a `Content-Length` header, the format of
  `vscode-jsonrpc`. The framer comes from `plugin/test/lsp.dart`.
- **Offsets.** Dart strings and VS Code's `document.offsetAt` both count UTF-16 code
  units. A request carries plain offsets into the text that it sends. An edit comes
  back as `{offset, length, text}` in the same coordinates.
- **One message at a time.** The connection runs requests and notifications in
  arrival order. Without the queue, a new overlay can land while an older request
  resolves, and the analyzer throws `InconsistentAnalysisException`.
- **Cancellation.** `$/cancelRequest` marks a queued request. The helper skips it and
  answers with the error code `-32800`.
- **One retry.** A request that throws `InconsistentAnalysisException` runs once more.

### Analysis

- **One `AnalysisContextCollection`** covers the workspace folders from `initialize`.
  It uses an `OverlayResourceProvider` over the physical file system.
- **Buffer text.** Each request puts its text on the overlay for its file. The overlay
  stays until the `closed` notification. A file with no overlay comes from disk.
- **The SDK path** comes from `initialize`.
- **The SDK version.** At `initialize`, the helper reads `<sdk>/version`. If the major
  or minor version differs from `Platform.version`, it returns a warning, for example
  "Dart Generate was built for Dart 3.13 and your SDK is 3.14. Rebuild the extension."
- **Package files.** Before each request, the helper reads the modification
  time of `.dart_tool/package_config.json` and `analysis_options.yaml` at each context
  root. A change rebuilds the collection. A file watcher is not used for these files,
  because a watcher can miss a change under `.dart_tool/`.
- **Memory.** The collection stays loaded while the window is open (ADR 0007).

### How an action runs

1. Resolve the library with `getResolvedLibraryContaining`.
2. Build the context with `CorrectionProducerContext.createResolved`, with the
   request's offset and length.
3. Create the assist, and set `fields`, `anywhereInClass` and `onError`.
4. Call `compute` with a new `ChangeBuilder` for the session and the request's EOL.
5. Read the edits, the verb from `assistArguments`, and `reason`.

When the verb is "Regenerate", when the action is Convert, or when a step of a
composite action regenerated a member, `replaces` is true. The edit size does not
decide it, because `writeMembers` formats the whole body. A plain insert therefore
comes back as a replacement too.

`generate` always sets `anywhereInClass`, because only an explicit choice sends it: a
picker result, a quick fix on a member name, or "Generate data class".

**Composite actions.** "Generate data class" runs toString, `==` and hashCode,
copyWith, and JSON, in that order. The getter picker runs `GenerateGetter` once for
each picked field, with the offset at the field name, in declaration order. After each
step, the helper applies the edits to the text, puts the result on the overlay and
resolves again. After the last step, the helper puts the request's own text back on
the overlay. Thus other files do not see members that the editor does not have. The
result is one edit over the changed span, from the first changed offset to the last.
That span includes an import that a step adds at the top of the file.

### Requests

| Request | Params | Result |
|---|---|---|
| `initialize` | `sdkPath`, `folders` | `warning` or null |
| `actions` | `path`, `text`, `eol`, `offset`, `length`, `explicit` | the actions for the class at the offset (see below) |
| `generate` | the `actions` params, plus `action` and `fields` | `edits`, `replaces` and `skipped` |
| `stale` | `path`, `text` | `{items}`, the stale members (ADR 0008), or `{skipped: true}` |

`explicit` is true for a Generate… request. It sets `anywhereInClass` and asks for
greyed-out actions too.

**Plugin roots.** For a request with `explicit: false`, the helper first reads the
analysis options at the context root of `path`. It reads them through
`AnalysisContext.getAnalysisOptionsForFile` and casts them to `AnalysisOptionsImpl` to
read `pluginConfigurations`. If they enable `dart_generate`, the result is empty. The
root counts, because the server takes plugins from the analysis options at the root of
the package or workspace.

Each action in the `actions` result has these members:

- **`id`:** `dataClass`, `toString`, `equality`, `copyWith`, `json`, `getter` or
  `primaryConstructor`.
- **`title`:** for example "Regenerate toString()".
- **`disabledReason`:** the reason message and name, or null.
- **`edits` and `replaces`:** for an action without a picker, except data class.
- **`pick`:** for an action with a picker. It holds the fields, each with its name and
  its resolved type, and `ticked`, the fields ticked at the start. For toString and
  `==`, these are the fields that a selection covers. Without such a selection, they
  are the fields that an existing member uses. Without a member, they are all the
  fields. For the getter, none is ticked.

"Generate data class" carries no edits. Its title and its greyed-out state come from
the four other results, and choosing it sends `generate`. So opening the menu does not
run four composite steps. When no step applies, its reason is the reason that the four
steps share, or "no step applies".

An empty list means that the offset is not in a class, an enum, a mixin or an
extension type. In an enum, a mixin or an extension type, every action is greyed out
with `notAClass`.

`skipped` lists the steps that gave no edit, each with its reason, for example
"JSON: a map key is not String (nonStringMapKey)".

Each item in the `stale` result names one member. It has the offset and length of the
member name, the action `id` and the severity, `warning` or `hint`. It also has the
message and the missing fields.
If the file has a syntax error, the result is `skipped: true`. A half-typed member
otherwise loses its references for a moment, and its mark flickers.

### Notifications

| Notification | Params | Effect |
|---|---|---|
| `filesChanged` | `paths` | `changeFile` for each path |
| `closed` | `path` | removes the overlay, so the file is read from disk again |

### Errors

- **A failing assist.** `onError` writes `ERROR <generator> <path>` and the stack
  trace to stderr. The action comes back with the disabled reason "internal error:
  see Output › Dart Generate". The other actions still show (ADR 0006).
- **A failing request.** The helper answers with a JSON-RPC error and the stack trace
  goes to stderr. The extension shows no action for it.

## The extension

`vscode/` is a TypeScript extension. esbuild bundles it with `vscode-jsonrpc` 9.0.3
into `dist/extension.js`. `package.json` sets `engines.vscode` to `^1.139.0` and a
local `publisher`.

### Activation and scope

- **Activation.** The extension starts on `onLanguage:dart`.
- **The SDK path.** With the Dart extension installed, the SDK path comes from its
  public API (`sdks.dart`). A change in `onSdksChanged` restarts the helper. Without
  the Dart extension, the path comes from `dart` on PATH. For Flutter's
  wrapper script, `<flutter>/bin/dart`, the SDK is `<flutter>/bin/cache/dart-sdk`.
  The Dart extension is not a hard dependency, so the tests run without it.
- **Documents.** The extension serves `file:` documents inside a workspace folder. It
  skips `*.g.dart`, `*.freezed.dart` and files with a `GENERATED CODE - DO NOT MODIFY`
  header.
- **Settings.** There are none.
- **Workspace trust.** `capabilities.untrustedWorkspaces` is `{supported: true}`. The
  helper reads files and runs no project code, so restricted mode needs no limit.

### Code action kinds

The plugin's kind is `refactor.generate.<name>`. The extension's kind is
`refactor.generate.dartGenerate.<name>`, so a request for one never matches the other.
Quick fixes use `quickfix.dartGenerate`. `providedCodeActionKinds` lists both bases.

| Request | Kind asked for | Position | Result |
|---|---|---|---|
| Generate… | `refactor.generate.dartGenerate` | any line in the class | every action, and greyed-out actions with their reasons |
| Cmd+. or the lightbulb | none, or any other kind | the class header, a field, or a selection that covers fields | the actions that apply |
| A quick fix | `quickfix` | a stale member name | "Regenerate X", marked as preferred |

**Plugin folders.** Under a context root whose analysis options enable the plugin,
the helper answers a Cmd+. or lightbulb request with no actions (see "Plugin roots").
A context root is a package or a pub workspace, and one workspace folder can hold
several. The helper reads `analysis_options.yaml` again after it changes, so the
extension keeps no cache. Generate… and quick fixes still work there, because the
plugin offers neither.

### Generate…

- **Command.** `dartGenerate.generate`, titled "Generate…", in the category
  "Dart Generate".
- **Key.** Cmd+N. Its `when` clause is `editorTextFocus && editorLangId == dart &&
  resourceScheme == file && !editorReadonly`. In a Dart editor this key replaces
  "New Untitled Text File".
- **Menus.** The editor context menu and the command palette.
- **Behavior.** The command first sends `actions` with `explicit: true`. If the
  result is empty, it shows "Put the cursor inside a class." in the status bar.
  Otherwise it runs `editor.action.codeAction` with the extension's kind and
  `apply: "never"`, so the menu always opens.
- **One resolve.** The command keeps its `actions` result, keyed by the document
  version and the offset. The provider call that `editor.action.codeAction` starts
  uses that result, so the helper builds the edits once.

The menu lists the actions in this order:

1. Generate data class
2. Generate toString()…
3. Generate ==() and hashCode…
4. Generate copyWith()
5. Generate toJson() and fromJson()
6. Generate getter or Generate getter…
7. Convert to primary constructor

When a picker opens next, the title ends with "…". When a member exists,
"Regenerate" replaces "Generate". When any of its members exists, "Generate data
class" becomes "Regenerate data class". A greyed-out action shows its reason. For
example, `==` in a mutable class shows "a field is not final (mutableClass)". When
none of its four steps apply, "Generate data class" is greyed out. After it applies, a message lists the
skipped steps, for example "Skipped JSON: a map key is not String (nonStringMapKey)".

### Pickers

A picker is a `QuickPick` with `canPickMany`.

| Action | Fields listed | Ticked at the start |
|---|---|---|
| toString, `==` and hashCode | the fields in declaration order, without `late` fields | Generate: all. A quick fix on a hint: all, because the quick fix exists to add the missing fields. Regenerate from Generate…: the fields that the member uses, so a deliberate subset stays. A selection that covers fields: those fields. |
| getter, from the class | the private fields that have no public getter | none, because each getter widens the public API |

- **Enter with no field ticked** shows "Pick at least one field" and keeps the picker
  open.
- **Escape** cancels, and nothing changes.
- **No picker opens** for Cmd+. on toString or `==`. It uses all fields, or the fields
  that the selection covers, as the plugin does.
- **The getter with the cursor on a private field** adds that getter at once.
- **The getter from the class header or from Generate…** opens the picker. If no field
  is left, the action is greyed out with `noFields` or `publicNameTaken`.

### Preview

An edit with `replaces: true` sets `needsConfirmation` on its `WorkspaceEdit` entries,
so VS Code opens its refactor preview. VS Code starts each such change unticked, and
Apply stays disabled until you tick it. So a replacement takes two clicks: tick the
change, then choose Apply. Discard leaves the file as it was. Any other edit applies
at once, and one undo removes it.

The extension applies the result of a `generate` request itself. Before it applies
the edit, it makes sure that `document.version` did not change during the request.
If it changed, the extension asks again, up to 3 times. If the text before the
requested offset changed too, the extension stops, applies nothing, and shows "The
file changed. Run the action again." in the status bar. A Cmd+. action carries its
edit. After a document change, VS Code closes the menu.

### Diagnostics

ADR 0008 has the rule. The collection is named `dart_generate` and is also the source.

| Member | Severity | Message | Quick fix |
|---|---|---|---|
| copyWith, toJson, fromJson | Warning | "copyWith() does not cover pressure." | "Regenerate copyWith()", with a preview |
| toString | Hint | "toString() does not show pressure." | "Regenerate toString()…", with the picker, all fields ticked, and then a preview |
| `==` and hashCode | Hint, on `==` | "==() and hashCode do not use pressure." | "Regenerate ==() and hashCode…", with the picker, all fields ticked, and then a preview |

- **Scan scope.** The scan covers visible Dart editors only. Other extensions can
  open documents that nobody sees, and those get no scan.
- **Scan times.** Three events start a scan: an editor becomes visible, 500 ms pass
  after the last edit, or `filesChanged` arrives. A superclass in another file can
  change the fields that `super.` parameters bring in.
- **Syntax errors.** For a `skipped: true` result, the extension keeps the previous
  marks.
- **Stale results.** The extension drops a result that belongs to an older
  `document.version`.
- **Closing a file** clears its diagnostics.

### The helper process

- **Start.** At activation. The stale scan of the first open file resolves it, so the
  helper needs no separate warm-up.
- **Workspace folders.** A change in `onDidChangeWorkspaceFolders` restarts the
  helper with the new folders.
- **Crash.** The extension restarts the helper up to 3 times in 3 minutes. After that,
  it shows an error with a "Show Output" button.
- **No start.** The extension shows "Dart Generate: the helper did not start." with
  a "Show Output" button in two cases: no SDK is found, or the helper answers
  `initialize` with an error. A wrong SDK path, such as a Flutter folder without its
  `bin/cache`, gives that error. After an error answer to `initialize`, the extension
  stops the helper. "Dart Generate: Restart Helper" or an SDK change starts it again.
- **Timeouts.** An automatic lightbulb request gives up after 5 s and returns nothing.
  An explicit request waits and shows the progress message "Dart Generate:
  analyzing…".
- **Commands.** "Dart Generate: Restart Helper" and "Dart Generate: Show Output".

## Packaging and setup

`npm run package` in `vscode/` does five steps:

1. `dart compile exe ../helper/bin/helper.dart -o bin/helper`
2. esbuild writes `dist/extension.js`.
3. `vsce package --target darwin-arm64 --no-dependencies --skip-license
   --allow-missing-repository --out dart-generate-<version>.vsix`, with
   `@vscode/vsce` 4.0.0. esbuild bundles every dependency, so `vsce` needs no npm
   dependency scan. With the scan, `vsce` 4.0.0 found no files at all.
4. `unzip -Z` lists `extension/bin/helper`. If its mode is not `-rwxr-xr-x`, the
   script fails, because the installed helper cannot start without it.
5. The script prints the install command.

To install or update the extension:

1. Run `code --install-extension dart-generate-<version>.vsix`. If you use a VS
   Code profile for Dart, add `--profile` and its name. Without it, the extension
   goes into the default profile only. weather_cli opens in the profile
   "Dart & Flutter", which is the only profile with the Dart extension.
2. Run "Developer: Reload Window" in each open VS Code window.

After a Dart SDK upgrade, run the helper e2e test. Then rebuild and install the
`.vsix` file. This extends the rule in ADR 0001.

`.vscodeignore` keeps `package.json`, `dist/extension.js` and `bin/helper` in the
`.vsix` file. `.gitignore` gains `.vscode-test/`, `node_modules/`, `dist/`, `out/`,
`vscode/bin/` and `*.vsix`.

## Testing

| Layer | What it proves | How |
|---|---|---|
| core, fixtures, plugin (existing) | The plugin changes keep its behavior. | The existing suites, unchanged. |
| Plugin API (new) | The four new fields and `enclosingClass` work outside the server. | `plugin/test/assist_api_test.dart` resolves small files in the test process with `createResolved`. |
| Helper e2e (new) | The helper writes what the plugin writes, for every marker in `fixtures/input/`. It also reports the reason of each `@not X reason` marker, which the plugin e2e test cannot see. | Start the helper with `Platform.resolvedExecutable` and `bin/helper.dart`, apply the markers over JSON-RPC, and compare with `fixtures/lib/`. |
| Helper cases (new) | Picked fields with gaps between them, `anywhereInClass`, data class with an import, and the getter picker with two fields. Each diagnostic row, a covering hand-written `fromJson`, the plugin folder rule, files from disk, and overlapping requests. | Inputs in `helper/test/cases/input/`, expected files in `helper/test/cases/expected/`. |
| Extension (new) | The kinds, the greyed-out actions, the quick fixes, the refactor preview, the diagnostics, the version rule and the restart policy. | Mocha in VS Code 1.139.1 from `@vscode/test-electron` 3.1.0, with a fake helper and an injected picker. The Dart extension is not installed. |
| Smoke (new) | The compiled helper and the extension work together, and a wrong SDK path gives the start error. | One fixture file, with `vscode/bin/helper`. |

- **An error fails the helper e2e test.** Any `ERROR` line on the helper's stderr
  fails it, as a log line fails the plugin e2e test (ADR 0006).
- **No `plugins:` block is committed.** The plugin folder test writes its
  `analysis_options.yaml` into a temporary folder.
- **A stub extension.** The test window loads `vscode/test/stub`, an empty
  extension, and the tests import the modules. So the real extension starts no
  helper there.
- **Direct provider calls.** `vscode.executeCodeActionProvider` drops disabled
  actions, and VS Code sends automatic requests of its own. So the tests call
  `provideCodeActions` directly.
- **Static analysis.** `tsc --noEmit` in strict mode and ESLint for `vscode/`, with
  TypeScript 6.0.3, because `typescript-eslint` 8.71.0 supports TypeScript below 6.1.
  `dart analyze` and `dart format` for `helper/`.

These are the manual steps in weather_cli, on `CurrentWeatherModel` and the data
source:

1. Press Cmd+N in `current_weather_model.dart` and read the menu and its reasons.
2. Pick two fields for toString and apply. A hint then marks toString, because it
   leaves out three fields.
3. Choose "Regenerate toJson() and fromJson()". The preview shows `'temperature_2m'`
   replaced, with the change unticked. Choose Discard.
4. Add `final double pressure;` and `required this.pressure`. A warning appears on
   fromJson: "fromJson() does not cover pressure."
5. Open "Generate getter…" in `forecast_remote_data_source.dart` and tick `_timeout`.

## Documentation

The README gains a section for the extension: the install and update steps, Cmd+N,
Generate…, and the stale-member marks. It loses the plugin's `cmd+n` binding for
`keybindings.json`. A user keybinding wins over an extension default. So that binding
shows the plugin's list on Cmd+N in place of Generate….

## Known limits

- **macOS arm64 only.** Another platform needs a new build.
- **Syntax errors.** In a file with a syntax error, the formatter gives up, so
  generated members are not indented. The plugin has the same limit.
- **One helper for each window.** Each VS Code window starts its own helper.
- **Unsaved changes in other files.** A file keeps the text of its last request until
  it closes. The helper reads any other file from disk, so it misses unsaved text in
  a file that no request sent.
- **Hand-written copyWith and JSON.** A hand-written copyWith or JSON member that
  leaves out a field on purpose keeps its warning (ADR 0008).
- **Plugin folders.** There, Cmd+. and the lightbulb show the plugin's actions. The
  pickers, the preview and the reasons need Generate….

## Evidence

Each measurement below comes from analyzer 14.4.0 compiled with `dart compile exe` on
Dart 3.13.2, on the target Mac.

| Project | First resolve | After an edit | RSS |
|---|---|---|---|
| weather_cli | 166 ms | 0 to 4 ms | 105 MB |
| darty `code/` | 167 ms | 4 ms | 107 MB |
| New Flutter app | 2,408 ms | 1 ms | 475 MB |
| New Flutter app, with an empty `FileByteStore` | 2,625 ms | not measured | 560 MB |
| New Flutter app, with a warm `FileByteStore` | 2,376 ms | not measured | 552 MB |
| 40 Flutter files, parsed only | 20 ms | not measured | 25 MB |

- **The Dart analysis server** used 172 MB for weather_cli, with the plugin loaded.
  This is the physical footprint, peak 192 MB.
- **`CorrectionProducerContext.createResolved`** is public in
  `analysis_server_plugin-0.3.23/lib/edit/dart/correction_producer.dart:293`.
- **`ChangeBuilder.format`** formats with `dart_style` through
  `createFormatter(resolvedUnit)`, in
  `analyzer_plugin-0.14.17/lib/src/utilities/change_builder/change_builder_dart.dart:2037`.
  It needs no server.
- **`pluginConfigurations`** is on `AnalysisOptionsImpl`, in
  `analyzer-14.4.0/lib/src/analysis_options/analysis_options.dart:325`.
- **Greyed-out code actions.** For a request of a specific kind, the code action
  menu shows a disabled action as faded. The VS Code API docs for
  `CodeAction.disabled` say so.
- **The Dart extension's public API.** `PublicDartExtensionApiImpl` in Dart-Code
  3.142.0 has `sdks`, `onSdksChanged` and `workspace.getOutline`. The outline has no
  resolved types.
- **A spike ran the plugin's assists outside the server.** It resolved
  weather_cli's `current_weather_model.dart` with an overlay and built each context
  with `createResolved`. toString, `==`, copyWith and Convert returned "Generate",
  and JSON returned "Regenerate" for the hand-written `fromJson`. Each took 7 to
  39 ms, and the log stayed empty. `getAnalysisOptionsForFile` for the root's
  `pubspec.yaml` listed `dart_generate` in `pluginConfigurations`.
- **A prototype of this spec ran on 2026-09-29.** On weather_cli, the compiled helper
  took 148 ms for the first resolve, 8 ms for Generate…, and 9 ms for "Generate data
  class". Its RSS was 109 MB.
- **The tests ran again on 2026-09-29, after the review fixes.** Core passed 51
  tests, the plugin 21 with its e2e test, and the fixtures 20. The helper passed 34
  in 9 to 11 s, two runs in a row. The extension passed 24 tests in VS Code 1.139.1,
  three runs in a row.
- **The refactor preview.** VS Code 1.139.1 starts a change with `needsConfirmation`
  unticked (`updateChecked(n, !n.metadata?.needsConfirmation)`), and Apply has the
  precondition `ctxHasCheckedChanges`.
