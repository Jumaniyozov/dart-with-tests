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

  String get transcript => 'code/$package/transcripts/$name.txt';
}

/// The `date:` header is the one value on the wire that no run can repeat, so
/// the command that captures it is the command that elides it.
const _elideDate = r"sed 's/^date: .*/date: <elided, so this can be re-run>/'";

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
      'curl -s http://localhost:8080/',
      'curl -s http://localhost:8080/budgets',
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
      'curl -s $_sends http://localhost:8080/expenses',
      'curl -s $_sends http://localhost:8080/budgets',
      'curl -s $_sends $_json '
          '-d \'{"pence":320,"category":"food","note":"bun"}\' '
          'http://localhost:8080/expenses',
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
      'curl -s $_status $_sends http://localhost:8080/expenses',
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

/// A store with a known number of expenses in it, on a fixed day.
///
/// Seeded as lines rather than by running the CLI, because `expenses add` files
/// an expense under *today*, and today is exactly the kind of thing a transcript
/// cannot contain.
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
    '{"day":"2026-09-11","pence":${450 + i * 10},"category":"food","note":"tea"}',
].map((line) => '$line\n').join();

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

  if (problems.isEmpty) {
    stdout.writeln(
      'capture_server: $done server command(s) '
      '${checking ? 'still true' : 'captured'}.',
    );
    return;
  }
  stdout.writeln('capture_server: ${problems.length} problem(s).\n');
  for (final problem in problems) {
    stdout.writeln('  $problem');
  }
  exitCode = 1;
}

/// One scenario, start to finish: seed a store, start the server, wait for it
/// to say so, run the commands, stop it.
Future<String> _capture(String root, _Scenario scenario) async {
  final directory = '$root/code/${scenario.package}';
  final temporary = Directory.systemTemp.createTempSync('capture_server');
  final store = File('${temporary.path}/expenses.txt')
    ..writeAsStringSync(_store(scenario));

  final server = await Process.start(
    'dart',
    ['run', scenario.entrypoint, '--file', store.path],
    workingDirectory: directory,
    environment: scenario.environment,
  );

  final buffer = StringBuffer();
  try {
    await _listening(server);
    for (var i = 0; i < scenario.commands.length; i++) {
      final command = scenario.commands[i];
      final result = await Process.run('bash', [
        '-c',
        command,
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
