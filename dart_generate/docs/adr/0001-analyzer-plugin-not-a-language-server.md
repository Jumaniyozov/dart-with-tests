# An analyzer plugin, not our own language server

dart_generate is one Dart package built on `analysis_server_plugin`. The Dart analysis
server loads it and sends its assists to VS Code and Zed as LSP code actions. Both
editors show them in the Cmd+. menu.

## Why

- **One codebase for every editor.** The requirement is VS Code and Zed. Zed extensions
  can provide languages, debuggers, themes, icon themes, snippets and MCP servers.
  They cannot add editor menus, editor commands or code actions. Their slash commands
  serve the Agent panel only. The analysis server is the one channel that both
  editors already listen to.
- **The real analyzer.** The plugin gets resolved elements. It knows field types,
  nullability, primary constructors and class modifiers. Line-by-line parsers fail on
  `class const Expense(...)`. A test of Datly's parser (2026-05-15) returned a class
  named `Point(final` with no fields.
- **Tested before this decision.** A probe on Dart 3.13.2 found the plugin assist in
  the code action list inside a pub workspace member. Its LSP kind is `refactor.<id>`.
  Zed requests the `refactor` kind (`crates/lsp/src/lsp.rs:956`).

## Considered options

- **Our own language server and two small editor extensions.** A Dart LSP server, a
  VS Code extension in TypeScript and a Zed extension in Rust compiled to WASM.
  Rejected: three codebases in three languages. Its one gain is no per-project setup,
  and the user works in their own repos, where one line of setup is acceptable.
- **Fork the hzgood extension and replace its parser.** Rejected: it stays VS Code
  only.

## Consequences

**Each checkout needs a local `plugins:` entry.** Nobody commits it. On a machine
without that path, a committed absolute `path:` makes `dart analyze` exit with code 4.
An accidental commit therefore turns CI red. A `git:` source can be committed, but
every CI run then compiles the plugin for actions that CI never uses.

**The first start compiles the plugin.** The first `dart analyze` took 16 s. In the
first editor probe, the action was missing after 4 s and present after 45 s. Later
`dart analyze` runs on a 600-file workspace took 4 s instead of 2 s.

**The plugin runs a second analysis in the server process.** It has its own
`AnalysisContextCollection` (`plugin_server.dart:661`). On the same workspace the
server used 317 MB instead of 224 MB. The rejected language-server option has the
same cost in a separate process.

**A broken plugin fails silently.** A plugin with a compile error makes `dart analyze`
exit with code 0, and the menu shows nothing. The end-to-end test must fail in that
case, and the README tells the user to read the `dart analyze` output first.

**The plugin API is young.** It arrived in Dart 3.10. `analysis_server_plugin` is at
0.3.23 and pins `analyzer` 14.4.0 exactly. Both are pinned exactly here, and an SDK
upgrade starts with the end-to-end tests.

**Not in darty.** The book repo does not enable the plugin. Its classes are
hand-written teaching material, and `check_also_met.dart` reads
`code/analysis_options.yaml` as evidence.

## Amended by ADR 0007 (2026-09-28)

VS Code now also has its own extension. This ADR rejected a separate extension
because "its one gain is no per-project setup". The user later chose UI that the
plugin channel cannot carry: a Generate… menu with reasons, field pickers, a preview
and stale-member diagnostics. ADR 0007 weighs those gains.

The plugin stays for Zed, and its behavior does not change. The rule "an SDK upgrade
starts with the end-to-end tests" now also covers the helper e2e test and a rebuild of
the `.vsix` file.

"Not in darty" still holds for the plugin. The extension runs in darty, because it
changes no darty file until you pick an action.
