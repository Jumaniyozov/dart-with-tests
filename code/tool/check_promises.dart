// Checks that every book's promise table records only promises the prose made.
//
// `OUTLINE.md` carries a table of forward references per book so the cost of
// reordering studies can be read off rather than rediscovered — ADR 0001
// explains why. A table is only worth that if it is true, and Book II's drifted
// in both directions within four studies.
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
// **This was Book II-only until Book III was outlined, and nobody noticed.** It
// hardcoded the heading `### Promises Book II makes to itself` and read pages
// only from `web/content/docs/writing-good-dart/`, so Book I's table and Book
// III's were both invisible to it — as would every page either book ever ships.
// It reported green for a reason that would not have lasted: Book II's pages say
// "Book III" and the reference pattern below matches `study 35`, so no forward
// reference to a later book had ever been counted.
//
// It now finds tables by their header row rather than by a heading somebody has
// to remember to spell exactly, and it reads every page under
// `web/content/docs/`. Study numbers are unique across books, which is what
// makes one page map enough.
//
//   dart run tool/check_promises.dart        # from code/

import 'dart:io';

final _rowPattern = RegExp(r'^\|\s*(\d+)\s*\|\s*(\d+)\s*\|', multiLine: true);
final _studyPattern = RegExp(r'^study:\s*(\d+)', multiLine: true);
final _referencePattern = RegExp(
  r'[Ss]tud(?:y|ies)\s+(\d+)(?:\s+and\s+(\d+))?',
);

/// The header row of a promise table. Book I's says *was* promised and Book II's
/// says *is*, so the tense is not part of the match.
final _headerPattern = RegExp(
  r'^\|\s*Owed by\s*\|\s*Made in\s*\|\s*The reader (?:is|was) promised\s*\|',
  multiLine: true,
);

/// A promise recorded as already settled. Book II writes `26←24` and Book I
/// writes `15→16`; both mean *made in one study, owed to another*, and the arrow
/// points from the study that made it. Normalised here to `(owedBy, madeIn)`.
///
/// Collected over the whole file rather than per table, and that is deliberate:
/// a first version scoped it to each table's section and reported Book III as
/// having three paid promises, because the paragraph explaining the two
/// notations sits under Book III's heading and *contains* `15→16` and `26←24`.
/// A tool that reads prose about its own format as data is worse than no tool.
final _paidPattern = RegExp(r'(\d+)\s*([←→])\s*(\d+)');

/// The `###` heading a table sits under, used only to name it in output.
final _headingPattern = RegExp(r'^### (.+)$', multiLine: true);

class _Table {
  _Table(this.label, this.rows);
  final String label;
  final Set<(String, String)> rows;
}

void main(List<String> args) {
  final root = args.isEmpty ? '..' : args.first;
  final outline = File('$root/OUTLINE.md').readAsStringSync();
  final pages = _pagesByStudy(Directory('$root/web/content/docs'));

  final tables = _tables(outline);

  // An empty table and a deleted one used to look the same here, and both
  // passed. They are not the same: Book II ended with every promise paid and
  // the table structurally present, which is a result worth keeping, while a
  // table somebody removed is the check quietly switching itself off.
  if (tables.isEmpty) {
    stderr.writeln(
      'check_promises: no promise table found in OUTLINE.md. It is the header '
      'row `| Owed by | Made in | The reader is promised |` this looks for, so '
      'either it moved or it was deleted; either way nothing is being checked.',
    );
    exit(1);
  }

  final everyRow = {for (final t in tables) ...t.rows};
  final everyPaid = _paid(outline);

  final problems = <String>[];
  for (final table in tables) {
    for (final (owedBy, madeIn) in table.rows) {
      final page = pages[madeIn];
      if (page == null) continue; // study not written yet
      if (!_mentions(page, owedBy)) {
        problems.add(
          '${table.label}: row "$owedBy owed by $madeIn": study $madeIn\'s '
          'page never mentions study $owedBy',
        );
      }
    }
  }

  final unrecorded = <String>[];
  pages.forEach((study, text) {
    for (final target in _forwardReferences(text, study)) {
      if (!everyRow.contains((target, study)) &&
          !everyPaid.contains((target, study))) {
        unrecorded.add('study $study mentions study $target, in no table');
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

  if (problems.isNotEmpty) {
    stderr.writeln(
      'check_promises: ${problems.length} row(s) record a promise '
      'the prose never made.\n',
    );
    problems.forEach(stderr.writeln);
    exit(1);
  }

  // Say what was found per table, so a book whose table has silently stopped
  // being read is visible rather than absorbed into a total.
  final rows = everyRow.length;
  stdout.writeln(
    'check_promises: ${tables.length} table(s), $rows row(s) '
    '${rows == 0 ? '— every promise the prose makes has been paid' : 'backed by their pages'}, '
    '${pages.length} page(s) read.',
  );
  for (final table in tables) {
    stdout.writeln('  ${table.label}: ${table.rows.length} open');
  }
  stdout.writeln('  ${everyPaid.length} recorded as paid, across all books.');
}

/// Every promise table in `OUTLINE.md`, found by its header row and labelled
/// with the nearest `###` heading above it.
List<_Table> _tables(String outline) {
  final headings = [
    for (final m in _headingPattern.allMatches(outline)) (m.start, m.group(1)!),
  ];
  final found = <_Table>[];
  for (final header in _headerPattern.allMatches(outline)) {
    var end = outline.indexOf('\n## ', header.start);
    if (end < 0) end = outline.length;
    final body = outline.substring(header.start, end);

    var label = 'unlabelled table';
    for (final (start, text) in headings) {
      if (start < header.start) label = text;
    }

    found.add(
      _Table(label, {
        for (final m in _rowPattern.allMatches(body))
          (m.group(1)!, m.group(2)!),
      }),
    );
  }
  return found;
}

/// Every written study's page, keyed by its study number, across every book.
/// Study numbers are unique book to book, so one map is enough.
Map<String, String> _pagesByStudy(Directory docs) {
  final found = <String, String>{};
  if (!docs.existsSync()) return found;
  for (final entry in docs.listSync(recursive: true)) {
    if (entry is! File || !entry.path.endsWith('.mdx')) continue;
    final text = entry.readAsStringSync();
    final study = _studyPattern.firstMatch(text)?.group(1);
    if (study != null) found[study] = text;
  }
  return found;
}

/// Whether a page names a study by number.
bool _mentions(String page, String study) => _referencePattern
    .allMatches(page)
    .any((m) => m.group(1) == study || m.group(2) == study);

/// Studies this page points forward to.
Set<String> _forwardReferences(String page, String own) {
  final mine = int.parse(own);
  final found = <String>{};
  for (final match in _referencePattern.allMatches(page)) {
    for (final group in [match.group(1), match.group(2)]) {
      if (group == null) continue;
      if (int.parse(group) > mine) found.add(group);
    }
  }
  return found;
}

/// Every promise the file records as settled, from anywhere in it.
Set<(String, String)> _paid(String outline) => {
  for (final m in _paidPattern.allMatches(outline))
    m.group(2) == '←' ? (m.group(1)!, m.group(3)!) : (m.group(3)!, m.group(1)!),
};
