// Checks that Book II's snapshot packages really are snapshots.
//
// Studies 23-34 each ship the whole expense tracker as it stands at the end of
// that study (ADR 0004). A file the study does not claim to touch must be
// byte-identical to the previous study's copy; a file it does claim to touch
// must actually differ. Both directions matter: a stale SLICE manifest is the
// same class of defect as a challenge intro claiming three tests when there are
// seven.
//
//   dart run tool/check_slices.dart        # from code/
//
// Exit 0 when every pair agrees, 1 otherwise.

import 'dart:io';

/// Directories whose contents are per-study by design and are never carried
/// forward, so comparing them would be noise rather than signal.
///
/// `transcripts/` holds captured output, which differs whenever the suite grows.
/// `exercises/` holds three fresh challenges per study.
const _skippedDirs = {'transcripts', 'exercises', '.dart_tool'};

const _skippedFiles = {'SLICE', 'pubspec.lock'};

final _packagePattern = RegExp(r'^ch(\d\d)_expenses$');

void main(List<String> args) {
  final root = Directory(args.isEmpty ? '.' : args.first);
  final packages = _snapshotPackages(root);

  if (packages.length < 2) {
    stdout.writeln(
      'check_slices: ${packages.length} snapshot package(s) — '
      'nothing to compare yet.',
    );
    return;
  }

  final problems = <String>[];
  for (var i = 1; i < packages.length; i++) {
    problems.addAll(_comparePair(packages[i - 1], packages[i]));
  }

  if (problems.isEmpty) {
    stdout.writeln(
      'check_slices: ${packages.length - 1} pair(s) agree with '
      'their SLICE manifests.',
    );
    return;
  }

  stderr.writeln('check_slices: ${problems.length} problem(s).\n');
  problems.forEach(stderr.writeln);
  exit(1);
}

/// The `chNN_expenses` directories, in study order.
List<Directory> _snapshotPackages(Directory root) {
  final found = <Directory>[
    for (final entry in root.listSync())
      if (entry is Directory && _packagePattern.hasMatch(_name(entry))) entry,
  ];
  found.sort((a, b) => _name(a).compareTo(_name(b)));
  return found;
}

/// Everything wrong between one study and the next.
List<String> _comparePair(Directory previous, Directory current) {
  final declared = _readSlice(current);
  final before = _sourceFiles(previous);
  final after = _sourceFiles(current);
  final label = '${_name(previous)} -> ${_name(current)}';

  if (declared == null) {
    return ['$label: ${_name(current)}/SLICE is missing.'];
  }

  final problems = <String>[];
  final seen = <String>{};

  for (final path in ({...before.keys, ...after.keys}.toList()..sort())) {
    final wasDeclared = declared.contains(path);
    seen.add(path);

    if (!before.containsKey(path)) {
      if (!wasDeclared) {
        problems.add('$label: added but not in SLICE — $path');
      }
      continue;
    }
    if (!after.containsKey(path)) {
      if (!wasDeclared) {
        problems.add('$label: removed but not in SLICE — $path');
      }
      continue;
    }

    // Normalise the package name so `bin/` and `test/` imports, which must use
    // `package:` and therefore carry the study number, do not read as changes.
    final same =
        _normalise(before[path]!, _name(previous)) ==
        _normalise(after[path]!, _name(current));

    if (same && wasDeclared) {
      problems.add('$label: in SLICE but unchanged — $path');
    } else if (!same && !wasDeclared) {
      problems.add('$label: changed but not in SLICE — $path');
    }
  }

  for (final path in declared.difference(seen)) {
    problems.add('$label: in SLICE but exists in neither study — $path');
  }
  return problems;
}

/// Paths declared by this study, relative to its package root.
Set<String>? _readSlice(Directory package) {
  final file = File('${package.path}/SLICE');
  if (!file.existsSync()) return null;
  return {
    for (final line in file.readAsLinesSync())
      if (line.trim().isNotEmpty && !line.trimLeft().startsWith('#'))
        line.trim(),
  };
}

/// Every comparable file in the package, keyed by its path within the package.
Map<String, String> _sourceFiles(Directory package) {
  final files = <String, String>{};
  for (final entry in package.listSync(recursive: true)) {
    if (entry is! File) continue;
    final relative = entry.path.substring(package.path.length + 1);
    final segments = relative.split(Platform.pathSeparator);
    if (segments.any(_skippedDirs.contains)) continue;
    if (_skippedFiles.contains(segments.last)) continue;
    files[segments.join('/')] = entry.readAsStringSync();
  }
  return files;
}

String _normalise(String contents, String packageName) =>
    contents.replaceAll(packageName, 'PACKAGE');

String _name(FileSystemEntity entity) =>
    entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
