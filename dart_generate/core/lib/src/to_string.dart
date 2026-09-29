import 'model.dart';
import 'outcome.dart';

/// `toString()` over every field that is not `late`.
///
/// If [only] is given, it keeps just those field names: the fields that the
/// editor selection covers.
Outcome generateToString(ClassModel model, {Set<String>? only}) {
  final fields = usedFields(model, only);
  if (fields.isEmpty) return NotOffered(Reason.noFields);
  final parts = [for (final f in fields) '${f.name}: ${interpolate(f.name)}'];
  final text = '${model.name}(${parts.join(', ')})';
  return Generated([
    Member('toString', '@override\nString toString() => ${_literal(text)};'),
  ]);
}

/// The longest string literal content on one line. With the formatter's
/// indent of 6 and the quotes, a line stays within 80 columns.
const _width = 70;

/// [text] as one string literal, or as adjacent literals split after a
/// `, ` when it is longer than [_width]. The formatter never splits a string.
String _literal(String text) {
  if (text.length <= _width) return "'$text'";
  final pieces = text.split(', ');
  final lines = <String>[];
  var line = '';
  for (final (i, piece) in pieces.indexed) {
    final next = i == pieces.length - 1 ? piece : '$piece, ';
    if (line.isNotEmpty && line.length + next.length > _width) {
      lines.add(line);
      line = '';
    }
    line += next;
  }
  lines.add(line);
  return lines.map((l) => "'$l'").join('\n');
}

/// The fields that toString and `==` use.
List<FieldModel> usedFields(ClassModel model, Set<String>? only) => [
  for (final f in model.fields)
    if (!f.isLate && (only == null || only.contains(f.name))) f,
];

/// `$name`, or `${name}` when the name has a `$` that would end the
/// interpolation early.
String interpolate(String name) =>
    name.contains(r'$') ? '\${$name}' : '\$$name';
