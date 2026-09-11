// Captures — and re-runs — the transcripts of a program that does not exit.
//
// Book II's transcript convention assumes a command that finishes: run it, keep
// what it printed, and `check_transcripts` re-runs it later to find out whether
// a subsequent commit made it a lie. A server finishes nothing. The command the
// reader types is `curl`, in a second terminal, against a process that is still
// listening — and there is no single command a checker can repeat.
//
// So the scenario is the unit here rather than the command. Each one below
// names a package, an entrypoint, how many expenses its store starts with, and
// the commands to run while it is up. This file starts the server, waits for a
// readiness line, runs the commands, kills the server, and writes the
// transcript. `--check` does all of that and compares instead of writing.
//
// Two things make it possible, and both are rules rather than habits:
//
//   * **The server logs nothing time-varying** — ADR 0005. A fixed port, no
//     timestamps, no elapsed times. A readiness line carrying a clock reading
//     would make every transcript fail on its second run.
//   * **The one clock that is not ours is elided by the command itself.** HTTP
//     responses carry a `date:` header, so every header transcript here pipes
//     through a `sed` that replaces its value. That `sed` is on line 1 of the
//     transcript, where the reader can see it and run it.
//
//   dart run tool/capture_server.dart            # from code/, writes them
//   dart run tool/capture_server.dart --check    # re-runs them, changes nothing

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// What one transcript is: a server, a store to put behind it, and the commands
/// to type while it is answering.
class _Scenario {
  const _Scenario(
    this.name, {
    required this.package,
    required this.entrypoint,
    required this.seeded,
    required this.commands,
    this.limit = 0,
    this.environment = const {},
    this.store,
    this.serves,
  });

  final String name;
  final String package;
  final String entrypoint;
  final int seeded;
  final List<String> commands;

  /// A limit on `food`, in pence, or `0` for a store with no limits in it.
  final int limit;

  /// What the server needs in its environment to start at all. Study 37's
  /// reads its shared key from there, and refuses to run without one.
  final Map<String, String> environment;

  /// Where to put the store, **relative to the package**, for a scenario whose
  /// commands have to name it.
  ///
  /// Null puts it in a temporary directory, which is what every scenario whose
  /// only commands are `curl` wants. Study 38 needs the other thing: its second
  /// process is the command line, writing the same file the server is holding,
  /// and `--file /var/folders/…` is an absolute path that no reader can type.
  /// So that scenario names a relative path, the file is written inside the
  /// package while the scenario runs, and it is deleted afterwards — a stray
  /// one would be caught by `check_slices` on the next run.
  final String? store;

  /// What the entrypoint is handed as `--file`, when that is not the file the
  /// store was seeded into.
  ///
  /// Every scenario before study 39 serves what it seeds. Study 39's server
  /// reads a **database** and the seed is the `.jsonl` study 28 wrote, because
  /// the transcript's own second command is the migration between the two.
  /// Relative to the package for [store]'s reason, and deleted for it too.
  final String? serves;

  String get transcript => 'code/$package/transcripts/$name.txt';
}

/// The `date:` header is the one value on the wire that no run can repeat, so
/// the command that captures it is the command that elides it.
const _elideDate = r"sed 's/^date: .*/date: <elided, so this can be re-run>/'";

/// The other clock reading, and it took three transcripts going red to find
/// it.
///
/// The seed below is filed under **today**, so anything printing a day is
/// printing one. Same convention as [_elideDate] and the same reason: it is on
/// line 1, where the reader can see it and run it. [_undated] fails on any
/// transcript that keeps a raw one, so no scenario can forget it.
const _elideDay = r"""sed 's/"day":"[0-9][0-9-]*"/"day":"<today, elided>"/g'""";

const _scenarios = [
  _Scenario(
    'answers',
    package: 'ch35_expenses',
    entrypoint: 'bin/serve.dart',
    seeded: 3,
    commands: [
      'curl -s http://localhost:8080/',
      'curl -s http://localhost:8080/expenses/2026-09/summary',
    ],
  ),
  _Scenario(
    'byhand',
    package: 'ch35_expenses',
    entrypoint: 'bin/by_hand.dart',
    seeded: 3,
    commands: ['curl -sD - -o /dev/null http://localhost:8080/ | $_elideDate'],
  ),
  _Scenario(
    'wire',
    package: 'ch35_expenses',
    entrypoint: 'bin/serve.dart',
    seeded: 3,
    commands: ['curl -sD - -o /dev/null http://localhost:8080/ | $_elideDate'],
  ),
  _Scenario(
    'answers',
    package: 'ch36_expenses',
    entrypoint: 'bin/serve.dart',
    seeded: 2,
    commands: [
      // Study 36 has no router, so **both** of these answer the expenses and
      // both print a day. Only the first was piped at first, and the check at
      // the bottom of this file is what said so.
      'curl -s http://localhost:8080/ | $_elideDay',
      'curl -s http://localhost:8080/budgets | $_elideDay',
    ],
  ),
  _Scenario(
    'wire',
    package: 'ch36_expenses',
    entrypoint: 'bin/serve.dart',
    seeded: 2,
    commands: ['curl -sD - -o /dev/null http://localhost:8080/ | $_elideDate'],
  ),
  _Scenario(
    'answers',
    package: 'ch37_expenses',
    entrypoint: 'bin/serve.dart',
    seeded: 2,
    limit: 2000,
    environment: {'EXPENSES_KEY': _key},
    commands: [
      'curl -s $_sends http://localhost:8080/expenses | $_elideDay',
      'curl -s $_sends http://localhost:8080/budgets',
      'curl -s $_sends $_json '
          '-d \'{"pence":320,"category":"food","note":"bun"}\' '
          'http://localhost:8080/expenses | $_elideDay',
      'curl -s $_sends http://localhost:8080/budgets/food',
    ],
  ),
  _Scenario(
    'statuses',
    package: 'ch37_expenses',
    entrypoint: 'bin/serve.dart',
    seeded: 2,
    limit: 2000,
    environment: {'EXPENSES_KEY': _key},
    commands: [
      'curl -s $_status http://localhost:8080/expenses',
      'curl -s $_status $_sends http://localhost:8080/nowhere',
      'curl -s $_status $_sends '
          "'http://localhost:8080/expenses?month=2026-13'",
      'curl -s $_status $_sends $_json '
          '-d \'{"pence":2000,"category":"food","note":"feast"}\' '
          'http://localhost:8080/expenses',
      'curl -s $_status $_sends http://localhost:8080/expenses | $_elideDay',
    ],
  ),
  _Scenario(
    'stale',
    package: 'ch38_expenses',
    entrypoint: 'bin/holding.dart',
    seeded: 2,
    store: 'expenses.txt',
    environment: {'EXPENSES_KEY': _key},
    commands: [
      'curl -s $_sends http://localhost:8080/budgets',
      'dart run bin/expenses.dart --file expenses.txt budget food 20.00',
      'curl -s $_sends http://localhost:8080/budgets',
    ],
  ),
  _Scenario(
    'fresh',
    package: 'ch38_expenses',
    entrypoint: 'bin/serve.dart',
    seeded: 2,
    store: 'expenses.txt',
    environment: {'EXPENSES_KEY': _key},
    commands: [
      'curl -s $_sends http://localhost:8080/budgets',
      'dart run bin/expenses.dart --file expenses.txt budget food 20.00',
      'curl -s $_sends http://localhost:8080/budgets',
    ],
  ),
  // Study 39's server is already listening at an empty database when the
  // migration runs, which is why this is one scenario rather than a setup step
  // and a transcript. Nothing here asks about a **budget** and nothing POSTs,
  // on purpose: both of those go through `Tracker.today`, and a transcript
  // whose answer depends on which month it was captured in is one that stops
  // reproducing on the first of a month. See `OUTLINE.md`.
  _Scenario(
    'moved',
    package: 'ch39_expenses',
    entrypoint: 'bin/serve.dart',
    seeded: 2,
    limit: 2000,
    store: 'expenses.txt',
    serves: 'expenses.db',
    environment: {'EXPENSES_KEY': _key},
    commands: [
      'curl -s $_sends http://localhost:8080/expenses | $_elideDay',
      'dart run bin/migrate.dart --from expenses.txt --to expenses.db',
      "curl -s $_sends 'http://localhost:8080/expenses?limit=1' | $_elideDay",
      'dart run bin/migrate.dart --from expenses.txt --to expenses.db',
    ],
  ),
];

/// What both entrypoints print once they are listening. Fixed, because a port
/// chosen at run time is a clock reading by another name.
const _ready = 'listening on http://localhost:8080';

/// Study 37's shared key. A demonstration value on a loopback port, written out
/// in the commands because the reader has to send it to get an answer at all.
const _key = 'a-shared-key';

/// `authorization` and, where there is a body, what the body is.
const _sends = "-H 'authorization: Bearer $_key'";
const _json = "-H 'content-type: application/json'";

/// The status code, after the document, so a transcript shows both.
const _status = r"-w '%{http_code}\n'";

/// A store with a known number of expenses in it, filed under **today**.
///
/// Seeded as lines rather than by running the CLI, because `expenses add` needs
/// a running program and this has to exist before one starts.
///
/// **Today, and that is the repair three transcripts needed.** It was a fixed
/// day, written down once, which made every answer that goes through
/// `Tracker.today` a function of the month it was captured in: `GET /budgets`
/// reports over `Period.of(today())` and `POST /expenses` files under today. On
/// the first of the next month `ch37`'s `statuses.txt` would have stopped
/// answering `409 over budget` and answered `200` with the expense recorded —
/// the status-code demonstration inverting, with no commit having touched
/// anything.
///
/// A seed in the same month as the clock removes that whole class, because
/// nothing the server **decides** can then depend on the month. What it costs
/// is that a printed `day` is a clock reading, which [_elideDay] handles and
/// [_undated] enforces.
///
/// **It ends in a newline, and the first scenario with a write route is what
/// found that out.** `FileStore.record` appends `'$line\n'` and never checks
/// what the file already ends with, so a seed without one has the new expense
/// welded onto the back of the last seeded line — which then decodes as
/// nothing, and two expenses vanish from an answer that was supposed to gain
/// one. Every file the program itself writes ends in a newline, so this is the
/// seed being an honest imitation of one rather than a bug being worked around.
String _store(_Scenario scenario) => [
  if (scenario.limit > 0)
    '{"kind":"limit","category":"food","pence":${scenario.limit}}',
  for (var i = 0; i < scenario.seeded; i++)
    '{"day":"$_today","pence":${450 + i * 10},"category":"food","note":"tea"}',
].map((line) => '$line\n').join();

/// Today, as the domain writes it.
String get _today {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

Future<void> main(List<String> args) async {
  final checking = args.contains('--check');
  final root = args.firstWhere((a) => !a.startsWith('--'), orElse: () => '..');
  final problems = <String>[];
  var done = 0;

  // An empty registry and a full one must not print the same thing. This tool
  // is the only thing that re-runs a server transcript, so a scenario list
  // somebody emptied is this check switching itself off.
  if (_scenarios.isEmpty) {
    stdout.writeln(
      'capture_server: no scenarios, so nothing is being checked.',
    );
    exitCode = 1;
    return;
  }

  for (final scenario in _scenarios) {
    final captured = await _capture(root, scenario);
    final file = File('$root/${scenario.transcript}');
    final dated = _undated(captured);
    if (dated != null) {
      problems.add('${scenario.transcript}: $dated');
      continue;
    }
    if (!checking) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(captured);
      done += scenario.commands.length;
      continue;
    }
    if (!file.existsSync()) {
      problems.add('${scenario.transcript}: named here and not on disk');
      continue;
    }
    final committed = file.readAsStringSync();
    if (committed != captured) {
      problems.add(
        '${scenario.transcript}: re-running it gives something else\n'
        '${_firstDifference(committed, captured)}',
      );
      continue;
    }
    done += scenario.commands.length;
  }

  // Every scenario has been re-run. Now the other direction: a transcript on
  // disk with a `curl` in it that no scenario above names.
  //
  // `check_transcripts` skips such a file **entirely** and counts it as covered
  // here, because there is no single command it could repeat. So a transcript
  // nobody owns is re-run by nothing while both tools report green — which is
  // the shape those tools' own comments call a check switching itself off, and
  // it arrived by the one route they did not anticipate. Proved both ways: a
  // file with `$ curl` in it and no scenario fails here, and removing it passes.
  problems.addAll(_unowned(root));

  if (problems.isEmpty) {
    stdout.writeln(
      'capture_server: $done server command(s) '
      '${checking ? 'still true' : 'captured'}, '
      'and no server transcript without a scenario.',
    );
    return;
  }
  stdout.writeln('capture_server: ${problems.length} problem(s).\n');
  for (final problem in problems) {
    stdout.writeln('  $problem');
  }
  exitCode = 1;
}

/// Every transcript holding a `curl` command that no scenario above accounts for.
///
/// The registry is what this tool checks; the filesystem is what the book
/// ships. Where they disagree, the file is the one with a reader looking at it.
List<String> _unowned(String root) {
  final owned = {for (final scenario in _scenarios) scenario.transcript};
  final problems = <String>[];

  final code = Directory('$root/code');
  if (!code.existsSync()) return ['code/ is not where this expected it'];

  for (final package in code.listSync().whereType<Directory>()) {
    final name = package.path.split(Platform.pathSeparator).last;
    final transcripts = Directory('${package.path}/transcripts');
    if (!transcripts.existsSync()) continue;

    for (final file in transcripts.listSync().whereType<File>()) {
      if (!file.path.endsWith('.txt')) continue;
      final leaf = file.path.split(Platform.pathSeparator).last;
      final path = 'code/$name/transcripts/$leaf';
      if (owned.contains(path)) continue;
      if (!file.readAsLinesSync().any((line) => line.startsWith(r'$ curl'))) {
        continue;
      }
      problems.add(
        '$path: has a curl command and no scenario here owns it, so '
        'check_transcripts skips it and nothing re-runs it',
      );
    }
  }
  return problems;
}

/// One scenario, start to finish: seed a store, start the server, wait for it
/// to say so, run the commands, stop it.
Future<String> _capture(String root, _Scenario scenario) async {
  final directory = '$root/code/${scenario.package}';
  final temporary = Directory.systemTemp.createTempSync('capture_server');
  final store = File(
    scenario.store == null
        ? '${temporary.path}/expenses.txt'
        : '$directory/${scenario.store}',
  )..writeAsStringSync(_store(scenario));

  final served = scenario.serves ?? scenario.store ?? store.path;
  final server = await Process.start(
    'dart',
    ['run', scenario.entrypoint, '--file', served],
    workingDirectory: directory,
    environment: scenario.environment,
  );

  final buffer = StringBuffer();
  try {
    await _listening(server);
    for (var i = 0; i < scenario.commands.length; i++) {
      final command = scenario.commands[i];
      // Merged, and merged by the **shell** rather than by this buffer.
      //
      // Appending all of stdout and then all of stderr is not what a terminal
      // does: a terminal shows both as they are written. Study 39's commands
      // are the first here to put anything on stderr — `dart run` announces
      // `Running build hooks...` there, on every run, for a package with a
      // native dependency — and the separated version printed the program's
      // answer before the line that really came first. Line 1 is still the
      // command the reader types, and in their terminal it shows exactly this.
      final result = await Process.run('bash', [
        '-c',
        '{ $command ; } 2>&1',
      ], workingDirectory: directory);
      buffer
        ..writeln('\$ $command')
        ..write(result.stdout)
        ..write(result.stderr);
      // By index, not by value. A scenario is allowed to run the same command
      // twice — which is exactly what proves a server answers the same thing
      // at two paths — and `command != commands.last` would then silently drop
      // the blank line after the first of them.
      if (i < scenario.commands.length - 1) buffer.writeln();
    }
    // `curl -s` prints a body with no trailing newline when the body has none,
    // which leaves a file that does not end in one. Every other transcript in
    // this book does, and a text file that does not is a thing people's tools
    // quietly fix for them — which would then read as a failing re-run.
    if (!buffer.toString().endsWith('\n')) buffer.writeln();
  } finally {
    server.kill(ProcessSignal.sigkill);
    await server.exitCode;
    temporary.deleteSync(recursive: true);
    if (scenario.store != null && store.existsSync()) store.deleteSync();
    if (scenario.serves != null) {
      final written = File('$directory/${scenario.serves}');
      if (written.existsSync()) written.deleteSync();
    }
  }
  return buffer.toString();
}

/// Waits for the readiness line, and gives up rather than hanging.
///
/// A tool that blocks for ever when the server fails to start is a tool that
/// looks like a slow check, which is the shape a person waits through twice
/// before investigating.
Future<void> _listening(Process server) async {
  final ready = Completer<void>();
  final said = StringBuffer();
  server.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
    line,
  ) {
    said.writeln(line);
    if (line == _ready && !ready.isCompleted) ready.complete();
  });
  server.stderr.transform(utf8.decoder).listen(said.write);
  await ready.future.timeout(
    const Duration(seconds: 30),
    onTimeout: () =>
        throw StateError('the server never said "$_ready". It said:\n$said'),
  );
}

/// The first raw day left in a captured transcript, or `null` when there is
/// none.
///
/// **The half of this that a person cannot be trusted with.** The seed is
/// filed under today, so every answer that goes through `Tracker.today` is
/// stable — that is the half a rule fixes. The other half is that a day can
/// still be *printed*, and whether a given command prints one is a judgement
/// somebody makes once and nobody re-makes when a route changes. So it is
/// asked of the bytes instead, every run, for every scenario.
///
/// It looks for the field the program actually writes rather than for a date
/// anywhere: `?month=2026-13` and *write it as 2026-09* are literal text in a
/// command and an error message, and neither is a clock reading.
String? _undated(String captured) {
  final raw = RegExp(r'"day":"[0-9]{4}-[0-9]{2}-[0-9]{2}"')
      .firstMatch(captured);
  return raw == null
      ? null
      : 'it keeps ${raw.group(0)}, which is today and will not be next month'
            ' — pipe that command through _elideDay';
}

/// The first line that differs, which is what a person needs to see.
String _firstDifference(String committed, String captured) {
  final was = const LineSplitter().convert(committed);
  final now = const LineSplitter().convert(captured);
  for (var i = 0; i < was.length || i < now.length; i++) {
    final before = i < was.length ? was[i] : '<nothing>';
    final after = i < now.length ? now[i] : '<nothing>';
    if (before != after) {
      return '    line ${i + 1} was: $before\n    line ${i + 1} now: $after';
    }
  }
  return '    the text is the same; the trailing newline is not';
}
