import 'package:analyzer/dart/analysis/session.dart';

import 'actions.dart';
import 'stale.dart';
import 'workspace.dart';

/// The requests and notifications of the helper.
final class Helper(
  /// Writes one log line to stderr.
  final void Function(String line) log,
) {
  Workspace? _workspace;

  Workspace get _ready =>
      _workspace ?? (throw StateError('initialize has not run'));

  /// Answers [method]. A request that meets a changed file while it resolves
  /// runs once more.
  Future<Object?> handle(String method, Map<String, Object?> params) async {
    try {
      return await _handle(method, params);
    } on InconsistentAnalysisException {
      return _handle(method, params);
    }
  }

  Future<Object?> _handle(String method, Map<String, Object?> p) async {
    if (method != 'initialize') await _ready.refresh();
    switch (method) {
      case 'initialize':
        await _workspace?.dispose();
        final workspace = _workspace = Workspace(p['sdkPath']! as String, [
          for (final f in p['folders']! as List<Object?>) f! as String,
        ]);
        log('initialize: ${workspace.folders.join(', ')}');
        return {'warning': workspace.sdkWarning()};
      case 'actions':
        final path = p['path']! as String;
        final explicit = p['explicit']! as bool;
        // Under a root that enables the plugin, Cmd+. shows the plugin's
        // actions. Generate… still works there.
        if (!explicit && _ready.pluginEnabled(path)) return const <Object?>[];
        final doc = await _document(p);
        if (doc == null) return const <Object?>[];
        return actions(
          doc,
          p['offset']! as int,
          p['length']! as int,
          explicit: explicit,
        );
      case 'generate':
        final doc = await _document(p);
        if (doc == null) {
          return {
            'edits': const <Object?>[],
            'replaces': false,
            'skipped': const <Object?>[],
          };
        }
        final path = p['path']! as String;
        return generate(
          doc,
          (text) => _ready.resolve(path, text),
          p['action']! as String,
          p['offset']! as int,
          p['length']! as int,
          switch (p['fields']) {
            final List<Object?> list => [for (final f in list) f! as String],
            _ => null,
          },
        );
      case 'stale':
        final resolved = await _ready.resolve(
          p['path']! as String,
          p['text']! as String,
        );
        return resolved == null
            ? {'items': const <Object?>[]}
            : stale(resolved.$2);
      case 'filesChanged':
        await _ready.changed([
          for (final f in p['paths']! as List<Object?>) f! as String,
        ]);
        return null;
      case 'closed':
        await _ready.closed(p['path']! as String);
        return null;
      default:
        throw UnsupportedError('unknown method $method');
    }
  }

  Future<Document?> _document(Map<String, Object?> p) async {
    final resolved = await _ready.resolve(
      p['path']! as String,
      p['text']! as String,
    );
    if (resolved == null) return null;
    return Document(
      resolved.$1,
      resolved.$2,
      p['eol']! as String,
      (generator, file, error, stack) =>
          log('ERROR $generator $file\n$error\n$stack'),
    );
  }
}
