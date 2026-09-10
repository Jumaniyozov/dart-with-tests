// Checks that every number this book prints from a run still matches the run.
//
// A transcript is captured once and then lives in the repository, where a later
// commit can quietly falsify it. That happened twice and neither was caught:
// the audit at `efa9fb6` added tests to `ch07_basket` and `ch08_tally` so that
// two previously unasserted claims would be executed, and left both packages'
// `all.txt` saying `+12` when the suite had become 13. The commit even records
// "90 tests pass" — it counted the workspace and not the transcripts. Both
// numbers were on published pages for every commit since.
//
// `check_slices` cannot see this: it skips `transcripts/` on purpose, because a
// transcript legitimately differs whenever the suite grows. `check_regions` and
// `check_promises` do not look at transcripts at all.
//
// Only one direction is mechanically decidable, and it is the useful one: a
// transcript of a `dart test` run that says **All tests passed** must still say
// it, with the same number. The whole repository is green, so re-running such a
// command is safe and its count is a fact.
//
// A transcript showing a *failure* is skipped, and that is not laziness. The
// standing requirements ask for exactly that transcript to be captured from a
// temporary broken state and the state then reverted — `undefined.txt` in half
// these packages is a deliberate compile error that no longer exists. Re-running
// one proves nothing about whether it was true when captured.
//
// A transcript with no status line at all is skipped too. `challenges.txt` is
// cut to its first few lines on purpose; a red suite in full would be pages.
// The count it would have ended on is not lost, because the prose states it —
// "Three challenges, N failing tests" — and that sentence is checked here
// against a real `dart test exercises/` run. Studies 15-18 deliberately state no
// count; a study that states none cannot have a stale one.
//
// Everything skipped is counted, so the coverage is visible rather than assumed.
//
//   dart run tool/check_transcripts.dart     # from code/

import 'dart:io';

final _commandPattern = RegExp(r'^\$ (.+)$');
final _passedPattern = RegExp(r'\+(\d+): All tests passed!');
final _failedPattern = RegExp(r'-(\d+): Some tests failed');
final _countPattern = RegExp(r'Three challenges, ([a-z]+) failing tests');
final _studyPattern = RegExp(r'^study:\s*(\d+)', multiLine: true);
final _packagePattern = RegExp(r'\.\./code/(ch\d+_[a-z]+)/');

const _numberWords = {
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
  'twenty': 20,
};

void main(List<String> args) {
  final root = args.isEmpty ? '..' : args.first;
  final problems = <String>[];
  var checked = 0;
  var skipped = 0;

  for (final package in _packages(Directory('$root/code'))) {
    final transcripts = Directory('${package.path}/transcripts');
    if (!transcripts.existsSync()) continue;
    final name = package.path.split(Platform.pathSeparator).last;

    for (final file in transcripts.listSync().whereType<File>()) {
      if (!file.path.endsWith('.txt')) continue;
      final leaf = file.path.split(Platform.pathSeparator).last;
      final lines = file.readAsLinesSync();

      for (var i = 0; i < lines.length; i++) {
        final command = _commandPattern.firstMatch(lines[i])?.group(1)?.trim();
        if (command == null) continue;
        final rerun = _rerunnable(command);
        if (rerun == null) {
          skipped++;
          continue;
        }
        final claimed = _statusIn(lines.skip(i + 1));
        // Truncated on purpose, or captured red from a state that is gone.
        if (claimed == null || claimed.startsWith('-')) {
          skipped++;
          continue;
        }
        checked++;
        final actual = _run(package.path, rerun);
        if (actual != claimed) {
          problems.add(
            '$name/$leaf: `$command` says $claimed, now ${actual ?? 'nothing'}',
          );
        }
      }
    }
  }

  problems.addAll(_challengeCounts(root));

  if (problems.isEmpty) {
    stdout.writeln(
      'check_transcripts: $checked re-runnable command(s) still true, '
      '$skipped not re-runnable by design.',
    );
    return;
  }
  stdout.writeln('check_transcripts: ${problems.length} problem(s).\n');
  for (final problem in problems) {
    stdout.writeln('  $problem');
  }
  exitCode = 1;
}

/// The arguments to re-run, or null when this command is not one we can repeat.
///
/// Only `dart test` is safe here. `dart analyze` transcripts routinely name a
/// file captured from a temporary state and then deleted, and `dart run` on a
/// program that writes or exits is not something a checker should be doing.
List<String>? _rerunnable(String command) {
  const prefix = 'dart test';
  if (command != prefix && !command.startsWith('$prefix ')) return null;
  final rest = command.substring(prefix.length).trim();
  if (rest.isEmpty) return ['test'];
  // A flag changes what the numbers mean, so leave those alone.
  if (rest.startsWith('-')) return null;
  return ['test', rest];
}

/// `+N` for a green run, `-N` for a red one — the number, not the timing.
String? _statusIn(Iterable<String> lines) {
  String? last;
  for (final line in lines) {
    if (line.startsWith(r'$ ')) break;
    final passed = _passedPattern.firstMatch(line);
    if (passed != null) last = '+${passed.group(1)}';
    final failed = _failedPattern.firstMatch(line);
    if (failed != null) last = '-${failed.group(1)}';
  }
  return last;
}

String? _run(String directory, List<String> arguments) {
  final result = Process.runSync(
    'dart',
    arguments,
    workingDirectory: directory,
  );
  return _statusIn('${result.stdout}\n${result.stderr}'.split('\n'));
}

/// "Three challenges, N failing tests" against `dart test exercises/`.
List<String> _challengeCounts(String root) {
  final problems = <String>[];
  for (final page in _pages(Directory('$root/web/content/docs'))) {
    final text = page.readAsStringSync();
    final claim = _countPattern.firstMatch(text);
    if (claim == null) continue;
    final leaf = page.path.split(Platform.pathSeparator).last;
    final claimed = _numberWords[claim.group(1)];
    if (claimed == null) {
      problems.add(
        '$leaf: "${claim.group(0)}" is not a number this tool reads',
      );
      continue;
    }
    final package = _packageOf(text, root);
    if (package == null) {
      problems.add('$leaf: states a challenge count and includes no package');
      continue;
    }
    final actual = _run('$root/code/$package', ['test', 'exercises/']);
    if (actual != '-$claimed') {
      problems.add('$leaf: claims $claimed failing, $package gives $actual');
    }
  }
  return problems;
}

/// The package a page's challenges live in — the one its own study number names
/// rather than the first path it happens to mention, because a study may
/// transclude an earlier study's code before reaching its own.
String? _packageOf(String text, String root) {
  final study = _studyPattern.firstMatch(text)?.group(1);
  if (study == null) return null;
  final number = study.padLeft(2, '0');
  for (final match in _packagePattern.allMatches(text)) {
    final package = match.group(1)!;
    if (package.startsWith('ch$number')) return package;
  }
  return null;
}

Iterable<Directory> _packages(Directory code) => code
    .listSync()
    .whereType<Directory>()
    .where((entry) => RegExp(r'ch\d+_').hasMatch(entry.path.split('/').last));

Iterable<File> _pages(Directory docs) sync* {
  for (final book in docs.listSync().whereType<Directory>()) {
    for (final file in book.listSync().whereType<File>()) {
      if (file.path.endsWith('.mdx')) yield file;
    }
  }
}
