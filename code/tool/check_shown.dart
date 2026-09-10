// Checks that a region on a page does not lean on a name the page never shows.
//
// `check_regions` catches the orphan: a region with no `<include>`. This is its
// inverse and the standing requirements say it cannot see it — a helper declared
// *outside* every region, in a file whose regions are on the page, is invisible
// to the orphan check and leaves exactly the same gap. Study 20 shipped a
// `#trace` region calling `traceOf(…)` with `traceOf` declared above `main()`
// and never shown.
//
// It kept happening. Study 27 shipped `day` and `late Store store` outside the
// regions that used them, and study 28 did the same with `directory`, `file` and
// `expenseOf` — twice in two studies, both found by hand.
//
// The check: for every region some MDX includes, take the names declared outside
// every region in that same file, and report any of them the region's body uses.
// A name declared both inside and outside is not reported — the reader has seen
// one of them.
//
// This is a heuristic and not a parser. It reads declarations of the shapes this
// book actually writes and nothing more, which is why it errs towards silence:
// it will miss an unusual declaration before it invents a problem.
//
// Comments, strings and member accesses are all discounted before a name counts
// as used. Every one of the three had to be added: the first version said a
// region "uses `out`" because its doc comment read *reach out for*; the second
// said one "uses `record`" because it asserted `expect(spy.calls, ['record'])`;
// the third said the same because of `outcome.out`, which is a record's member
// and not a local at all.
//
//   dart run tool/check_shown.dart        # from code/

import 'dart:io';

final _regionStart = RegExp(r'^\s*//\s*#region\s+(\S+)\s*$');
final _regionEnd = RegExp(r'^\s*//\s*#endregion');

/// The declaration shapes this book writes: a binding, or a callable.
final _declarations = [
  RegExp(
    r'^\s*(?:final|const|var|late\s+final|late)\s+[\w<>,\s?]*?(\w+)\s*[=;]',
  ),
  // The type must start with a character a type can start with. `[\w<>,\s?]+`
  // let the *indentation* be the type, so every `test('…', () async {` outside
  // a region registered a declaration of `test` — measured on study 33's
  // `command_test.dart`, where it made a shown region look like it leaned on
  // the test package.
  RegExp(
    r'^\s*(?:static\s+)?[\w<>?][\w<>,\s?]*\s+(\w+)\s*\([^)]*\)\s*(?:async\s*)?[={]',
  ),
  RegExp(
    r'^\s*(?:abstract\s+|final\s+|base\s+|interface\s+|sealed\s+|mixin\s+)*'
    r'(?:class|mixin|enum|extension|typedef)\s+(?:const\s+)?(\w+)',
  ),
];

/// Names that mean something to the language or the test package rather than to
/// this file, so finding one outside a region proves nothing.
const _ignored = {'main', 'if', 'for', 'while', 'switch', 'return', 'await'};

void main(List<String> args) {
  final root = args.isEmpty ? '.' : args.first;
  final included = _includedRegions(Directory('$root/../web/content'));
  final problems = <String>[];
  var checked = 0;

  for (final package in _packages(Directory(root))) {
    final name = package.path.split(Platform.pathSeparator).last;
    for (final file in _dartFiles(package)) {
      final relative = file.path
          .substring(package.path.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
      final regions = _split(file.readAsLinesSync());
      final outside = _declared(regions.remove('') ?? const []);

      for (final region in regions.entries) {
        if (!included.contains('$name/$relative#${region.key}')) continue;
        checked++;
        final inside = _declared(region.value);
        final body = _code(region.value);
        for (final leaked in outside.difference(inside)) {
          // Not preceded by a dot or a word character: `outcome.out` is a
          // member of a record, not a use of a local named `out`.
          final use = RegExp(r'(?<![.\w$])' + RegExp.escape(leaked) + r'\b');
          if (use.hasMatch(body)) {
            problems.add(
              '$name/$relative#${region.key} uses `$leaked`, '
              'declared outside every region',
            );
          }
        }
      }
    }
  }

  if (problems.isEmpty) {
    stdout.writeln(
      'check_shown: $checked shown region(s), every name in them shown too.',
    );
    return;
  }
  stderr.writeln('check_shown: ${problems.length} problem(s).\n');
  problems.forEach(stderr.writeln);
  exit(1);
}

/// A file's lines grouped by region name, with everything outside under ''.
Map<String, List<String>> _split(List<String> lines) {
  final grouped = <String, List<String>>{'': []};
  var current = '';
  for (final line in lines) {
    final start = _regionStart.firstMatch(line);
    if (start != null) {
      current = start.group(1)!;
      grouped.putIfAbsent(current, () => []);
      continue;
    }
    if (_regionEnd.hasMatch(line)) {
      current = '';
      continue;
    }
    grouped[current]!.add(line);
  }
  return grouped;
}

/// The lines with their strings and comments taken off, so neither prose nor a
/// test name can look like a use of a name.
///
/// Both mattered. The first version reported a region "uses `out`" because its
/// doc comment said *reach out for*, and the second reported one "uses `record`"
/// because it asserted `expect(spy.calls, ['record'])`.
String _code(List<String> lines) =>
    _withoutBlockStrings(lines.join('\n'))
        .split('\n')
        .map(_stripped)
        .join('\n');

/// Triple-quoted strings, taken out before anything else looks at the text.
///
/// `_string` reads one line at a time and cannot see them, so a `'''` block's
/// prose was read as code: study 33's `usage` says *show what has been
/// recorded* and the checker reported the region as using `recorded`.
final _blockString = RegExp("'''.*?'''|\"\"\".*?\"\"\"", dotAll: true);

String _withoutBlockStrings(String source) => source.replaceAllMapped(
  _blockString,
  // Keep the line count, so nothing else shifts underneath.
  (match) => '\n' * '\n'.allMatches(match[0]!).length,
);

final _string = RegExp(r"""('(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")""");

String _stripped(String line) {
  final withoutStrings = line.replaceAll(_string, "''");
  final comment = withoutStrings.indexOf('//');
  return comment == -1 ? withoutStrings : withoutStrings.substring(0, comment);
}

Set<String> _declared(List<String> lines) {
  final names = <String>{};
  for (final line in lines) {
    if (line.trimLeft().startsWith('//')) continue;
    for (final pattern in _declarations) {
      final match = pattern.firstMatch(line);
      if (match != null && !_ignored.contains(match.group(1))) {
        names.add(match.group(1)!);
      }
    }
  }
  return names;
}

Set<String> _includedRegions(Directory content) {
  final found = <String>{};
  if (!content.existsSync()) return found;
  final pattern = RegExp(r'\.\./code/(ch\d\d_\w+)/(\S+?)#(\w+)</include>');
  for (final file in content.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.mdx')) continue;
    for (final match in pattern.allMatches(file.readAsStringSync())) {
      found.add('${match.group(1)}/${match.group(2)}#${match.group(3)}');
    }
  }
  return found;
}

Iterable<Directory> _packages(Directory root) => root
    .listSync()
    .whereType<Directory>()
    .where((d) => RegExp(r'ch\d\d_').hasMatch(d.path.split('/').last));

Iterable<File> _dartFiles(Directory package) sync* {
  for (final folder in ['lib', 'bin', 'test', 'exercises']) {
    final directory = Directory('${package.path}/$folder');
    if (!directory.existsSync()) continue;
    for (final entry in directory.listSync(recursive: true).whereType<File>()) {
      if (entry.path.endsWith('.dart')) yield entry;
    }
  }
}
