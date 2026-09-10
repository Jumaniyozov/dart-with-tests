// Checks `OUTLINE.md`'s `Shipped:` lines against the packages they describe.
//
// Each written study's entry opens with a line like
//
//     Shipped: 168 green, 3 challenges at 10 failing, 9 transcripts.
//
// Every number in it is a claim, and until Book III was outlined **no checker
// had ever read this file**. The existing count requirements sweep `code/` with
// a grep and the pages with another; `OUTLINE.md` is the corpus neither looks
// at, and it is the one every session reads first.
//
// Swept by hand once: nine `Shipped:` lines, six carrying a wrong number. Five
// were wrong the day they were written — every transcript in those packages
// arrived in the single commit that wrote the study, so nothing was added
// afterwards. Four drifted later, and all four drifted because the book audited
// itself: 4528c90, 25ecdfa, f6df067 and ab840c9 each added assertions for claims
// that had none, making the book more true and a line stale as a side effect.
//
// The ruling that makes this checkable: **a `Shipped:` line describes the
// package as it stands, not the commit that wrote it.** So both numbers can be
// counted, which is what this does.
//
// Studies 27, 28 and 29 state no `Shipped:` line at all. That is allowed and is
// not the same as a missing entry — a study that states no number cannot have a
// stale one — so those are reported rather than failed on. What is failed on is
// finding no lines whatsoever, which would mean this check had switched itself
// off.
//
// Slow, like `check_transcripts`: it runs a suite per claim.
//
//   dart run tool/check_shipped.dart        # from code/

import 'dart:io';

/// `### 34 — Being a dependency · `being-a-dependency` · `ch34_expenses` — …`
/// The package is the third backticked field, which is where every entry in
/// this file puts it.
final _headingPattern = RegExp(
  r'^### (\d+) — [^`]*`[^`]*`[^`]*`([A-Za-z0-9_]+)`',
  multiLine: true,
);

final _shippedPattern = RegExp(
  r'^Shipped: (\d+) green,.*?(\d+) transcripts',
  multiLine: true,
);

final _passedPattern = RegExp(r'\+(\d+): All tests passed!');

void main(List<String> args) {
  final root = args.isEmpty ? '..' : args.first;
  final outline = File('$root/OUTLINE.md').readAsStringSync();

  // Walk the entries in order so each `Shipped:` line belongs to the heading
  // above it. Reading the file as one string and matching separately is how a
  // sweep of this same file earlier attributed three lines to the wrong studies.
  final headings = _headingPattern.allMatches(outline).toList();
  final problems = <String>[];
  final silent = <String>[];
  var checked = 0;

  for (var i = 0; i < headings.length; i++) {
    final study = headings[i].group(1)!;
    final package = headings[i].group(2)!;
    final end = i + 1 < headings.length
        ? headings[i + 1].start
        : outline.length;
    final entry = outline.substring(headings[i].start, end);

    final claim = _shippedPattern.firstMatch(entry);
    if (claim == null) {
      silent.add('study $study ($package)');
      continue;
    }

    final directory = Directory('$root/code/$package');
    if (!directory.existsSync()) {
      problems.add(
        'study $study: `Shipped:` names $package, which is not in code/',
      );
      continue;
    }
    checked++;

    final claimedGreen = claim.group(1)!;
    final claimedTranscripts = int.parse(claim.group(2)!);

    final transcripts = Directory('$root/code/$package/transcripts');
    final actualTranscripts = transcripts.existsSync()
        ? transcripts.listSync().length
        : 0;
    if (actualTranscripts != claimedTranscripts) {
      problems.add(
        'study $study: claims $claimedTranscripts transcripts, '
        '$package holds $actualTranscripts',
      );
    }

    final actualGreen = _green(directory.path);
    if (actualGreen == null) {
      problems.add('study $study: `dart test test/` in $package did not pass');
    } else if (actualGreen != claimedGreen) {
      problems.add(
        'study $study: claims $claimedGreen green, $package gives $actualGreen',
      );
    }
  }

  // An empty corpus and a missing one are different answers, and every checker
  // in this book is asked to tell them apart.
  if (checked == 0) {
    stderr.writeln(
      'check_shipped: no `Shipped:` line found in OUTLINE.md at all. Either the '
      'wording changed or the entries went; either way nothing is being checked.',
    );
    exit(1);
  }

  if (problems.isEmpty) {
    stdout.writeln(
      'check_shipped: $checked `Shipped:` line(s) agree with their packages; '
      '${silent.length} entr(y/ies) state no count and cannot have a stale one.',
    );
    return;
  }
  stderr.writeln('check_shipped: ${problems.length} problem(s).\n');
  problems.forEach(stderr.writeln);
  exit(1);
}

/// The `+N` from a package's own suite, or null if it did not pass.
String? _green(String package) {
  final run = Process.runSync('dart', [
    'test',
    'test/',
  ], workingDirectory: package);
  final text = '${run.stdout}';
  return _passedPattern.firstMatch(text)?.group(1);
}
