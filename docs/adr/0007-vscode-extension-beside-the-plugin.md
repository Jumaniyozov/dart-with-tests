# A VS Code extension beside the plugin

VS Code gets its own extension. A TypeScript front end owns the UI, and a Dart helper
process runs the plugin's six assists through the public
`CorrectionProducerContext.createResolved`. The analyzer plugin stays for Zed, and
its behavior does not change.

## Why

- **The plugin channel cannot carry the UI.** The user chose a Generate… menu with
  greyed-out actions and reasons, field pickers, a preview before a replacement, and
  stale-member diagnostics. The analysis server sends a plugin's assists as plain code
  actions. It sends no disabled actions, and a plugin cannot open a picker.
- **Install once.** The extension needs no `plugins:` block, so a project needs no
  setup and nothing can be committed by accident.
- **The same code.** The helper runs the plugin's own assist classes, so both front
  ends write the same members. The helper e2e test compares its output with
  `fixtures/lib/`, as the plugin e2e test does.

## Considered options

- **Replace the plugin with the extension.** Rejected by the user: Zed then loses the
  actions.
- **A second language server through `vscode-languageclient`.** Rejected: the menu and
  the pickers are not LSP features, so they need custom requests anyway. The Dart side
  also needs an LSP implementation, and no maintained Dart library has one.
- **Reuse the Dart extension's analysis server.** Rejected: its public API has SDK
  paths and an outline, and the outline has no resolved types. The plugin itself runs
  its own analysis, so moving work into it saves nothing.
- **A new `engine/` package for the generator code.** Rejected: `createResolved` is
  public, so the helper runs the assists as they are. Nothing moves, and the plugin
  e2e tests stay the proof.
- **A parser in TypeScript, as in hzgood.** Rejected for the reason in ADR 0001: a
  line parser read `class const Expense(...)` as a class named `Point(final`.
- **A helper that reads syntax only.** Rejected: `final items = <int>[];` has no
  written type, so `==` compares the list by identity. JSON also needs to know
  whether a type is an enum or a class with `fromJson`.
- **Analysis only on demand.** The stale scan reads syntax only, at 17 to 25 MB. Only
  explicit actions resolve, so the lightbulb no longer appears by itself. The helper
  restarts 2 minutes after the last explicit action. Rejected by the user: this Mac
  has 18 GB of RAM, and macOS compresses idle memory. The first action after a break
  also waits, about 0.2 s in weather_cli and 2.4 s in a Flutter app.
- **Stop the helper after 10 idle minutes.** Rejected with on-demand analysis, for the
  same reasons.
- **`json_rpc_2` for the transport.** Rejected: a handler gets no request ID, so
  `$/cancelRequest` cannot find a waiting request. The helper's own `Connection`
  class frames, queues and answers the messages.
- **A disk cache (`FileByteStore`).** Rejected: it gives no gain. A new Flutter app took
  2,408 ms and 475 MB with no cache. With an empty cache, it took 2,625 ms and 560 MB.
  With a warm cache, it took 2,376 ms and 552 MB.

## Consequences

**Two front ends.** VS Code uses the extension, and Zed uses the plugin. In a folder
whose root analysis options enable the plugin, Cmd+. and the lightbulb show only the
plugin's actions. The helper answers a Cmd+. request there with no actions. It reads
the analysis options at the package or workspace root, and it reads them again after
they change. Generate… and the quick fixes still work, because the plugin offers
neither.

**Separate kinds.** The plugin's kind is `refactor.generate.<name>`. The extension's
kind is `refactor.generate.dartGenerate.<name>`. A Generate… request asks only for the
extension's kind, so it never lists the plugin's actions.

**The helper stays loaded.** Each VS Code window starts one helper. Measured RSS was
105 MB for weather_cli, 107 MB for darty `code/`, and 475 MB for a new Flutter app. The
first resolve took 166 ms, 167 ms and 2,408 ms. The Dart analysis server itself used
172 MB for weather_cli.

**One platform.** `npm run package` builds a macOS arm64 binary into the `.vsix` file.
Another platform needs a new build. If the helper loses its executable bit in the zip
file, the packaging script fails.

**The helper contains analyzer 14.4.0.** After a Dart SDK upgrade, run the helper e2e
test, then rebuild and install the `.vsix` file. At start, the helper compares the
SDK's `version` file with the Dart version that built it. If the major or minor
version differs, the extension shows a warning once.

**The Dart extension is optional.** With the Dart extension installed, its public API
gives the SDK path. Without it, the path comes from `dart` on PATH. So the extension
tests run in a VS Code without the Dart extension, and no second analysis server mixes
its actions into the results.

**The extension runs in darty.** It changes no file until you pick an action, so the
user chose to leave it on there. The plugin stays off in darty, as ADR 0001 says. The
extension is installed in the VS Code profile "Dart & Flutter" only. When darty opens
in that profile, it gets the extension.

**The plugin gains four fields.** `GenerateAssist` gains `fields`, `anywhereInClass`,
`reason` and `onError`, and the method `enclosingClass`. The server never sets the
fields, so their defaults keep today's behavior. `lib/assists.dart` exports
`GenerateAssist`, `fieldNames`, the assists, `findMember` and `readClass` for the
helper, and `GenerateToString.isGenerated` becomes public. A spike ran all five class
assists this way on weather_cli, in 7 to 39 ms each.

**A replacement needs a tick.** VS Code starts a change with `needsConfirmation`
unticked in its refactor preview, and Apply stays disabled until you tick it.
