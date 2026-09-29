import 'package:generate_core/generate_core.dart';

/// One marker comment in a fixture.
///
/// `// @generate toString, equality` asks for actions on the next class.
/// `// @regenerate copyWith` asks for the same, and expects the title to
/// start with "Regenerate" because the member already exists. `at _count`
/// puts the cursor on a field instead, and `select a..b` selects from field
/// `a` to field `b`. `// @not copyWith noBuilder` asserts that an action is
/// absent, and names the reason.
final class Marker(
  /// The index of the marker line among all marker lines of the file.
  final int index,
  final bool expected,
  final List<String> names, {

  /// "Generate" or "Regenerate" for an expected action, `null` for `@not`.
  final String? verb,
  final String? reason,
  final String? at,
  final (String, String)? select,
});

final _line = RegExp(
  r'^\s*// @(generate|regenerate|not) (.+)$',
  multiLine: true,
);

List<Marker> parseMarkers(String text) => [
  for (final (i, m) in _line.allMatches(text).indexed) _parse(i, m),
];

Marker _parse(int index, RegExpMatch match) {
  var rest = match.group(2)!;
  String? at;
  (String, String)? select;
  if (RegExp(r' at (\w+)$').firstMatch(rest) case final m?) {
    at = m.group(1);
    rest = rest.substring(0, m.start);
  }
  if (RegExp(r' select (\w+)\.\.(\w+)$').firstMatch(rest) case final m?) {
    select = (m.group(1)!, m.group(2)!);
    rest = rest.substring(0, m.start);
  }
  final keyword = match.group(1)!;
  if (keyword == 'generate' || keyword == 'regenerate') {
    final names = rest.split(',').map((n) => n.trim()).toList();
    return Marker(
      index,
      true,
      names,
      verb: keyword == 'generate' ? 'Generate' : 'Regenerate',
      at: at,
      select: select,
    );
  }
  final [name, reason] = rest.split(' ');
  // A misspelled reason would cover nothing and pass.
  if (!Reason.values.any((r) => r.name == reason)) {
    throw FormatException('marker $index: "$reason" is not a Reason name');
  }
  return Marker(index, false, [name], reason: reason, at: at, select: select);
}

/// The selection that [marker] asks for in [text]: `(start, end)`.
(int, int) target(String text, Marker marker) {
  final after = _line.allMatches(text).elementAt(marker.index).end;
  int find(String pattern, int from) {
    final m = RegExp(pattern).allMatches(text, from).firstOrNull;
    if (m == null) throw StateError('marker ${marker.index}: no $pattern');
    return m.start;
  }

  if (marker.select case (final from, final to)) {
    final start = find('\\b$from\\b', after);
    return (start, find('\\b$to\\b', start) + to.length);
  }
  if (marker.at case final name?) {
    final start = find('\\b$name\\b', after);
    return (start, start);
  }
  final declaration = RegExp(
    r'\b(class|enum|mixin|extension\s+type)\s+(const\s+)?(\w+)',
  ).allMatches(text, after).first;
  final start =
      declaration.start +
      declaration.group(0)!.lastIndexOf(declaration.group(3)!);
  return (start, start);
}
