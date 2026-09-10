// Checks that every study's `Also met:` line lists things the study met.
//
// `Also met:` closes each Wrapping up and is a summary of what the reader now
// has. Like Book II's promise table before it, it turned out to have been
// written from **intention** rather than from the finished study, and the
// defect recurred in both places before either was checked — which is when
// this book builds a tool.
//
// Measured when this was first run: study 8 claimed the reader met `values`
// and `entries`, and neither appears in `ch08_tally` or anywhere on the page;
// study 22 claimed `Stream.fromIterable`, which nothing in `ch22_feed` uses.
// Three false claims, all on published pages.
//
// The corpus a claim is checked against is deliberately narrow: the study's
// package (all of it, transcripts included), plus `analysis_options.yaml` for
// lint names, plus the **code** on the study's own page — text inside backticks
// or fences — with the `Also met:` line itself removed, since a claim cannot be
// its own evidence. Prose does not count. "The map's values" in a sentence is
// not the reader meeting `values`.
//
// It is a heuristic and errs towards silence. An item is split into
// identifiers and only those of three characters or more are required, so
// `Comparable<T>` asks for `Comparable` and lets `T` go, and `${}` asks for
// nothing at all. Anything it does report has appeared literally nowhere.
//
//   dart run tool/check_also_met.dart        # from code/

import 'dart:io';

final _studyPattern = RegExp(r'^study:\s*(\d+)', multiLine: true);
final _alsoMetPattern = RegExp(r'Also met:(.+?)\n\n', dotAll: true);
final _tickedPattern = RegExp(r'`([^`]+)`');
final _fencePattern = RegExp(r'```.*?```', dotAll: true);
final _identifierPattern = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');
final _commentPattern = RegExp(r'//.*');
final _attributionPattern = RegExp(r'(?:source|href)="([^"]*)"');

void main(List<String> args) {
  final root = args.isEmpty ? '..' : args.first;
  final options = File('$root/code/analysis_options.yaml').readAsStringSync();

  final packages = <int, Directory>{};
  for (final entry in Directory('$root/code').listSync()) {
    final name = entry.path.split(Platform.pathSeparator).last;
    if (entry is Directory && RegExp(r'^ch(\d\d)_').hasMatch(name)) {
      packages[int.parse(name.substring(2, 4))] = entry;
    }
  }

  final problems = <String>[];
  var claims = 0;
  var lines = 0;

  for (final page in _pages(Directory('$root/web/content/docs'))) {
    final text = page.readAsStringSync();
    final study = _studyPattern.firstMatch(text);
    if (study == null) continue;
    final number = int.parse(study.group(1)!);
    final package = packages[number];
    if (package == null) continue;

    final alsoMet = _alsoMetPattern.firstMatch(text);
    if (alsoMet == null) continue; // study 1 has none, by design
    lines++;

    final withoutClaim = text.replaceFirst(alsoMet.group(0)!, '');
    final corpus = StringBuffer(options)
      ..write(_codeOn(withoutClaim))
      // `<Practice source="…">` renders as the Practice's own heading, so a
      // lint or guideline named only there is still something the reader met.
      ..write(
        _attributionPattern
            .allMatches(withoutClaim)
            .map((m) => m.group(1))
            .join('\n'),
      )
      ..write(_sourceIn(package));
    final haystack = corpus.toString();

    for (final match in _tickedPattern.allMatches(alsoMet.group(1)!)) {
      claims++;
      final item = match.group(1)!.trim();
      final missing = _identifierPattern
          .allMatches(item)
          .map((m) => m.group(0)!)
          .where((word) => word.length >= 3 && !haystack.contains(word))
          .toList();
      if (missing.isNotEmpty) {
        problems.add(
          'study $number ${_name(page)}: claims `$item`, and '
          '${missing.map((w) => '`$w`').join(', ')} '
          '${missing.length == 1 ? 'appears' : 'appear'} nowhere in the study',
        );
      }
    }
  }

  if (problems.isEmpty) {
    stdout.writeln(
      'check_also_met: $claims claim(s) across $lines `Also met:` line(s), '
      'every one of them met.',
    );
    return;
  }
  stdout.writeln('check_also_met: ${problems.length} problem(s).\n');
  for (final problem in problems) {
    stdout.writeln('  $problem');
  }
  exitCode = 1;
}

/// Every `.mdx` page, in a stable order.
List<File> _pages(Directory docs) =>
    docs
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.mdx'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

String _name(File page) => page.path.split(Platform.pathSeparator).last;

/// Only the code on a page: fenced blocks and inline backticks. Prose is not
/// evidence that a reader met an identifier.
String _codeOn(String page) {
  final code = StringBuffer();
  for (final fence in _fencePattern.allMatches(page)) {
    // Comments are stripped for check_shown's reason: a name written in
    // English inside a `//` line is not the reader meeting it. Study 8's page
    // says `// 2 — pairs, not values`, and that is not `Map.values`.
    code.write(fence.group(0)!.replaceAll(_commentPattern, ''));
  }
  // Fences are removed before inline backticks are scanned. Leaving them in
  // lets a fence's own ``` pair with the next inline tick, which shifts every
  // match after it and silently hides real claims — it hid two when this tool
  // was first run.
  for (final ticked in _tickedPattern.allMatches(
    page.replaceAll(_fencePattern, '\n'),
  )) {
    code
      ..write(ticked.group(1))
      ..write('\n');
  }
  return code.toString();
}

/// Everything readable in a package, transcripts and manifests included.
String _sourceIn(Directory package) {
  final source = StringBuffer();
  for (final entry in package.listSync(recursive: true)) {
    if (entry is! File) continue;
    if (entry.path.contains('.dart_tool')) continue;
    try {
      source
        ..write(entry.readAsStringSync())
        ..write('\n');
    } on FileSystemException {
      continue; // not text; nothing a claim could be met in
    }
  }
  return source.toString();
}
