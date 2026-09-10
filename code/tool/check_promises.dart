// Checks that Book II's promise table records only promises the prose made.
//
// `OUTLINE.md` carries a table of forward references so the cost of reordering
// studies can be read off rather than rediscovered — ADR 0001 explains why.
// A table is only worth that if it is true, and this one drifted in both
// directions within four studies.
//
// One of the two directions is mechanically decidable and is what this checks:
// every row says study X promises something to study Y, so study X's page must
// at least mention study Y by number. Three rows failed that when it was first
// run, including two naming a study neither page mentions at all.
//
// The other direction — a promise the prose makes that the table omits — needs
// judgment, because "Study 25 gives the program something to record" at the end
// of a Wrapping up is navigation and not a promise. This tool prints those as
// notes for a person to triage rather than failing on them.
//
//   dart run tool/check_promises.dart        # from code/

import 'dart:io';

final _rowPattern = RegExp(r'^\|\s*(\d+)\s*\|\s*(\d+)\s*\|', multiLine: true);
final _studyPattern = RegExp(r'^study:\s*(\d+)', multiLine: true);
final _referencePattern = RegExp(
  r'[Ss]tud(?:y|ies)\s+(\d+)(?:\s+and\s+(\d+))?',
);

void main(List<String> args) {
  final root = args.isEmpty ? '..' : args.first;
  final outline = File('$root/OUTLINE.md').readAsStringSync();
  final pages = _pagesByStudy(
    Directory('$root/web/content/docs/writing-good-dart'),
  );

  // An empty table and a deleted one used to look the same here, and both
  // passed. They are not the same: Book II ended with every promise paid and
  // the table structurally present, which is a result worth keeping, while a
  // table somebody removed is the check quietly switching itself off.
  final header = outline.contains('| Owed by | Made in | The reader is');
  final table = _promiseTable(outline);
  if (table.isEmpty) {
    if (header) {
      stdout.writeln(
        'check_promises: the table is present and empty — '
        'every promise the prose makes has been paid.',
      );
      return;
    }
    stderr.writeln(
      'check_promises: no promise table found in OUTLINE.md. '
      'It is the header row this looks for, so either it moved or it was '
      'deleted; either way nothing is being checked.',
    );
    exit(1);
  }

  final problems = <String>[];
  for (final (owedBy, madeIn) in table) {
    final page = pages[madeIn];
    if (page == null) continue; // study not written yet
    if (!_mentions(page, owedBy)) {
      problems.add(
        'row "$owedBy owed by $madeIn": study $madeIn\'s page never mentions '
        'study $owedBy',
      );
    }
  }

  final paid = _paid(outline);
  final unrecorded = <String>[];
  pages.forEach((study, text) {
    for (final target in _forwardReferences(text, study)) {
      if (!table.contains((target, study)) && !paid.contains((target, study))) {
        unrecorded.add('study $study mentions study $target, not in the table');
      }
    }
  });

  if (unrecorded.isNotEmpty) {
    stdout.writeln(
      'check_promises: ${unrecorded.length} to triage by hand '
      '(navigation lines are fine, promises are not):',
    );
    for (final note in unrecorded) {
      stdout.writeln('  $note');
    }
    stdout.writeln('');
  }

  if (problems.isEmpty) {
    stdout.writeln(
      'check_promises: ${table.length} row(s), every one backed by '
      'its page.',
    );
    return;
  }
  stderr.writeln(
    'check_promises: ${problems.length} row(s) record a promise '
    'the prose never made.\n',
  );
  problems.forEach(stderr.writeln);
  exit(1);
}

/// The `(owedBy, madeIn)` pairs in the Book II promise table.
Set<(String, String)> _promiseTable(String outline) {
  final heading = outline.indexOf('### Promises Book II makes to itself');
  if (heading < 0) return {};
  var end = outline.indexOf('\n## ', heading);
  if (end < 0) end = outline.length;
  return {
    for (final match in _rowPattern.allMatches(outline.substring(heading, end)))
      (match.group(1)!, match.group(2)!),
  };
}

/// Promises the table records as already settled, written `26←24`.
Set<(String, String)> _paid(String outline) {
  final heading = outline.indexOf('### Promises Book II makes to itself');
  if (heading < 0) return {};
  var end = outline.indexOf('\n## ', heading);
  if (end < 0) end = outline.length;
  return {
    for (final match in RegExp(
      r'(\d+)←(\d+)',
    ).allMatches(outline.substring(heading, end)))
      (match.group(1)!, match.group(2)!),
  };
}

/// Each written Book II study's page, keyed by its study number.
Map<String, String> _pagesByStudy(Directory pages) {
  final found = <String, String>{};
  if (!pages.existsSync()) return found;
  for (final entry in pages.listSync()) {
    if (entry is! File || !entry.path.endsWith('.mdx')) continue;
    final text = entry.readAsStringSync();
    final study = _studyPattern.firstMatch(text)?.group(1);
    if (study != null) found[study] = text;
  }
  return found;
}

bool _mentions(String page, String study) => _referencePattern
    .allMatches(page)
    .any((match) => match.group(1) == study || match.group(2) == study);

/// Studies this page points forward to.
Set<String> _forwardReferences(String page, String study) => {
  for (final match in _referencePattern.allMatches(page))
    for (final group in [match.group(1), match.group(2)])
      if (group != null && int.parse(group) > int.parse(study)) group,
};
