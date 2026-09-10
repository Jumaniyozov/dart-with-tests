// Checks that Book II shows the reader every region it changed.
//
// The orphan-`#region` rule from Book I says a region with no `<include>` is
// dead weight. Snapshots break that rule's assumption: every package carries
// every earlier study's regions, so by study 34 dozens would look orphaned
// while being perfectly well shown in the study that wrote them.
//
// Scoping the rule to the files a study's SLICE names is not enough either —
// study 25 changed `run` inside command.dart and left `codes`, `outcome` and
// `parse` alone, and only the first needs showing again.
//
// So the rule is by region: a region must be included by some MDX page if it
// is new in this study, or if its text differs from the previous study's.
//
// One study broke that rule honestly and it needed an escape hatch. Study 28
// turned `Store` into an asynchronous interface, and five regions changed by
// nothing but `async` and `await` — the same mocks, the same assertions, one
// keyword heavier. Re-showing them would tell a reader there was something new
// about mocks, which is exactly the wolf-crying this check exists to avoid.
//
// The hatch is not a silent skip. A study's SLICE may carry lines of the form
//
//   # unshown: test/store_test.dart#spy — async only, shown in study 27
//
// and the reason after the dash is required. That makes every exemption a
// sentence a person wrote and a reviewer can disagree with, and it keeps them
// in the same file that already records what the study changed.
//
//   dart run tool/check_regions.dart        # from code/
//
// Exit 0 when every changed region is on a page or exempted, 1 otherwise.

import 'dart:io';

final _packagePattern = RegExp(r'^ch(\d\d)_expenses$');
final _exemptionPattern = RegExp(r'^#\s*unshown:\s*(\S+)\s*(?:—|--)?(.*)$');
final _regionPattern = RegExp(
  r'//\s*#region\s+(\w+)\n(.*?)//\s*#endregion',
  dotAll: true,
);

void main(List<String> args) {
  final root = Directory(args.isEmpty ? '.' : args.first);
  final packages = _snapshotPackages(root);
  if (packages.isEmpty) {
    stdout.writeln('check_regions: no snapshot packages yet.');
    return;
  }

  final included = _includedRegions(Directory('${root.path}/../web/content'));
  final problems = <String>[];
  var checked = 0;
  var exempted = 0;

  for (var i = 0; i < packages.length; i++) {
    final name = _name(packages[i]);
    final exempt = _exemptions(packages[i], problems);
    final now = _regions(packages[i]);
    final before = i == 0
        ? <String, String>{}
        : _regions(packages[i - 1]).map(
            (key, value) => MapEntry(
              key,
              value.replaceAll(_name(packages[i - 1]), 'PACKAGE'),
            ),
          );

    for (final entry in now.entries) {
      final body = entry.value.replaceAll(name, 'PACKAGE');
      final unchanged = before[entry.key] == body;
      if (unchanged) continue;
      checked++;
      if (included.contains('$name/${entry.key}')) continue;
      if (exempt.contains(entry.key)) {
        exempted++;
        continue;
      }
      final why = before.containsKey(entry.key) ? 'changed' : 'new';
      problems.add('$name: $why but on no page — ${entry.key}');
    }
  }

  if (problems.isEmpty) {
    final note = exempted == 0
        ? 'all shown.'
        : '${checked - exempted} shown, $exempted exempted in a SLICE.';
    stdout.writeln('check_regions: $checked new or changed region(s), $note');
    return;
  }
  stderr.writeln('check_regions: ${problems.length} problem(s).\n');
  problems.forEach(stderr.writeln);
  exit(1);
}

/// Regions this study's SLICE says it deliberately does not show.
///
/// The format is `# unshown: <path>#<region> — <reason>`, and a line without a
/// reason is a problem rather than an exemption: the point is that somebody had
/// to write down why.
Set<String> _exemptions(Directory package, List<String> problems) {
  final slice = File('${package.path}/SLICE');
  if (!slice.existsSync()) return const {};
  final name = _name(package);
  final exempt = <String>{};
  for (final line in slice.readAsLinesSync()) {
    final match = _exemptionPattern.firstMatch(line);
    if (match == null) continue;
    final reason = match.group(2)!.trim();
    if (reason.isEmpty) {
      problems.add('$name: unshown line with no reason — ${match.group(1)}');
      continue;
    }
    exempt.add(match.group(1)!);
  }
  return exempt;
}

List<Directory> _snapshotPackages(Directory root) {
  final found = <Directory>[
    for (final entry in root.listSync())
      if (entry is Directory && _packagePattern.hasMatch(_name(entry))) entry,
  ];
  found.sort((a, b) => _name(a).compareTo(_name(b)));
  return found;
}

/// Every region in a package, keyed by `path/within/package#regionName`.
Map<String, String> _regions(Directory package) {
  final found = <String, String>{};
  for (final entry in package.listSync(recursive: true)) {
    if (entry is! File || !entry.path.endsWith('.dart')) continue;
    final relative = entry.path
        .substring(package.path.length + 1)
        .split(Platform.pathSeparator)
        .join('/');
    if (relative.startsWith('exercises/')) continue;
    for (final match in _regionPattern.allMatches(entry.readAsStringSync())) {
      found['$relative#${match.group(1)}'] = match.group(2)!;
    }
  }
  return found;
}

/// Every `package/path#region` any MDX page transcludes.
Set<String> _includedRegions(Directory content) {
  final pattern = RegExp(r'\.\./code/(ch\d\d_expenses/[^<#]+)#(\w+)</include>');
  final found = <String>{};
  for (final entry in content.listSync(recursive: true)) {
    if (entry is! File || !entry.path.endsWith('.mdx')) continue;
    for (final match in pattern.allMatches(entry.readAsStringSync())) {
      found.add('${match.group(1)!.trim()}#${match.group(2)}');
    }
  }
  return found;
}

String _name(FileSystemEntity entity) =>
    entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
