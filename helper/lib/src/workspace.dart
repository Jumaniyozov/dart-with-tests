import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
// pluginConfigurations has no public getter.
// ignore: implementation_imports
import 'package:analyzer/src/analysis_options/analysis_options.dart';

/// The analysis of the workspace folders, with the editor's text on top.
final class Workspace {
  Workspace(this.sdkPath, this.folders) {
    _collection = _open();
    _stamps = _readStamps();
  }

  final String sdkPath;
  final List<String> folders;

  final _provider = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

  late AnalysisContextCollection _collection;

  /// The modification time of each package file when [_collection] was built.
  Map<String, DateTime?> _stamps = const {};

  /// The text of each overlay.
  final _texts = <String, String>{};
  var _stamp = 0;

  AnalysisContextCollection _open() => AnalysisContextCollection(
    includedPaths: folders,
    resourceProvider: _provider,
    sdkPath: sdkPath,
  );

  /// The warning for an SDK that the helper was not built for, or `null`.
  String? sdkWarning() => versionWarning(
    File('$sdkPath/version').readAsStringSync(),
    Platform.version,
  );

  /// Rebuilds the collection when a package file changed. The helper calls
  /// it before each request. A file watcher can miss a change under
  /// `.dart_tool/`.
  Future<void> refresh() async {
    final stamps = _readStamps();
    final changed =
        stamps.length != _stamps.length ||
        stamps.entries.any((e) => _stamps[e.key] != e.value);
    if (!changed) return;
    await _collection.dispose();
    _collection = _open();
    _stamps = _readStamps();
    _texts.clear();
  }

  Map<String, DateTime?> _readStamps() => {
    for (final context in _collection.contexts)
      for (final name in [
        '.dart_tool/package_config.json',
        'analysis_options.yaml',
      ])
        '${context.contextRoot.root.path}/$name': _modified(
          '${context.contextRoot.root.path}/$name',
        ),
  };

  static DateTime? _modified(String path) {
    final stat = FileStat.statSync(path);
    return stat.type == FileSystemEntityType.notFound ? null : stat.modified;
  }

  AnalysisContext? _contextFor(String path) {
    try {
      return _collection.contextFor(path);
    } on StateError {
      // Outside every folder, or excluded by analysis_options.yaml.
      return null;
    }
  }

  /// Whether the analysis options at the root of [path]'s package or
  /// workspace enable the dart_generate plugin.
  bool pluginEnabled(String path) {
    final context = _contextFor(path);
    if (context == null) return false;
    final root = context.contextRoot.root.path;
    final options = context.getAnalysisOptionsForFile(
      _provider.getFile('$root/pubspec.yaml'),
    );
    return (options as AnalysisOptionsImpl).pluginConfigurations.any(
      (c) => c.name == 'dart_generate',
    );
  }

  /// Resolves the library of [path] with [text] as its content, or `null`
  /// when no folder analyzes [path].
  Future<(ResolvedLibraryResult, ResolvedUnitResult)?> resolve(
    String path,
    String text,
  ) async {
    final context = _contextFor(path);
    if (context == null) return null;
    if (_texts[path] != text) {
      _texts[path] = text;
      _provider.setOverlay(path, content: text, modificationStamp: ++_stamp);
      // Each context that imports the file must see the new text.
      await changed([path]);
    }
    await context.applyPendingFileChanges();
    final library = await context.currentSession.getResolvedLibraryContaining(
      path,
    );
    if (library is! ResolvedLibraryResult) return null;
    return (library, library.units.firstWhere((u) => u.path == path));
  }

  /// Tells every context that the content of [paths] changed: on disk or on
  /// the overlay.
  Future<void> changed(List<String> paths) async {
    for (final context in _collection.contexts) {
      for (final path in paths) {
        context.changeFile(path);
      }
      await context.applyPendingFileChanges();
    }
  }

  /// Drops the overlay of [path], so its text comes from disk again.
  Future<void> closed(String path) async {
    _texts.remove(path);
    _provider.removeOverlay(path);
    await changed([path]);
  }

  Future<void> dispose() => _collection.dispose();
}

/// The warning when [sdk] and [built] differ in the major or minor version,
/// or `null`. [built] is `Platform.version` of the helper, such as
/// `3.13.2 (stable) (...) on "macos_arm64"`.
String? versionWarning(String sdk, String built) {
  String minor(String v) => v.trim().split(RegExp(r'[ .]')).take(2).join('.');
  if (minor(sdk) == minor(built)) return null;
  return 'Dart Generate was built for Dart ${minor(built)} and your SDK is '
      '${minor(sdk)}. Rebuild the extension.';
}
