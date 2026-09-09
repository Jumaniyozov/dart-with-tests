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
//   dart run tool/check_regions.dart        # from code/
//
// Exit 0 when every changed region is on a page, 1 otherwise.

import 'dart:io';

final _packagePattern = RegExp(r'^ch(\d\d)_expenses$');
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

  for (var i = 0; i < packages.length; i++) {
    final name = _name(packages[i]);
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
      if (!included.contains('$name/${entry.key}')) {
        final why = before.containsKey(entry.key) ? 'changed' : 'new';
        problems.add('$name: $why but on no page — ${entry.key}');
      }
    }
  }

  if (problems.isEmpty) {
    stdout.writeln(
      'check_regions: $checked new or changed region(s), all shown.',
    );
    return;
  }
  stderr.writeln('check_regions: ${problems.length} problem(s).\n');
  problems.forEach(stderr.writeln);
  exit(1);
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
