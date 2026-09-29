# Each assist catches and logs its own failure

Each assist wraps its work in a `try`. If it fails, it appends the time, the
generator, the file and the stack trace to the log, then returns no edit. It rethrows
only `InconsistentAnalysisException`.

## Why

- **One failure hides every generator.** The plugin's `AssistProcessor` catches only
  `ConflictingEditException` (`assist_processor.dart:61`). Any other exception fails
  the whole `edit.getAssists` request (`plugin_server.dart:1091`). Every plugin
  action at that cursor then disappears.
- **The editor shows no error either way.** The failed request reaches no user
  interface, and the plugin gets a null instrumentation service
  (`plugin_server.dart:218`). A log file is the only place an error can be read. The
  analyzer plugin docs recommend a log file for the same reason.

## Considered options

- **Let exceptions propagate.** This follows darty study 26: never catch an `Error`.
  Rejected here: the error still reaches nobody, and the other generators disappear
  with it.

## Consequences

**This departs from darty study 26 on purpose.** The rule exists so that a bug is
seen. In a plugin, catching and logging is the only way to see it.

**One exception passes through.** A file change during a request throws
`InconsistentAnalysisException`, and the server returns an empty list for it. Logging
it fills the log while the user types.

**A conflicting edit goes to the log.** The processor catches
`ConflictingEditException` and drops the action, but it writes no log. Each assist
builds its edit in a private draft (see below), so a conflict can only come from
dart_generate's own placement code. It is always our bug. The first version rethrew
it, and that hid a bug in Task 11 of the plan: the JSON action was missing on every
class whose last member was a constructor, and the log stayed empty.

**The log location comes from the environment.** The path is the value of
`DART_GENERATE_LOG`. If the variable is not set, the path is
`~/.dartServer/dart_generate.log`. The end-to-end test sets it to a temporary file. A
log with any line in it fails the test. A spike showed that the plugin inherits the
server's environment and can write files. If the log passes 1 MB, the plugin empties
it.

**The edit is built in a draft.** `AssistProcessor` reads the builder after
`compute` returns. A catch after half an edit therefore still shows a broken action.
Each assist builds into a draft `ChangeBuilder` and copies the edits only on success.
In the prototype, a planted throw in the JSON assist removed only that action.

## Amended for the VS Code helper (2026-09-28)

The VS Code helper runs the same assists (ADR 0007). The rule stays: one failing
assist hides only its own action. Four details change in the helper.

1. **The error goes to stderr, not to the log file.** `GenerateAssist` gains an
   `onError` field. Its default is `writeLog`, so the plugin still writes the log. The
   helper sets it to write `ERROR <generator> <path>` and the stack trace to stderr.
   The extension shows stderr in the "Dart Generate" output channel.
2. **A failed action stays visible.** In the Generate… menu it is greyed out with the
   reason "internal error: see Output › Dart Generate". The plugin cannot do this,
   because the server sends no disabled actions.
3. **Requests run one at a time.** A new overlay during a running request throws
   `InconsistentAnalysisException`. The queue prevents that, and a request that still
   throws it runs once more.
4. **An error line fails the test.** Any `ERROR` line on the helper's stderr fails the
   helper e2e test, as a log line fails the plugin e2e test.
