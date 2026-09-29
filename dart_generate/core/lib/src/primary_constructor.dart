/// One parameter of a primary constructor header.
final class HeaderParam(
  final String name, {

  /// The field type as written. `null` for a `super.` parameter.
  final String? type,
  final bool isFinal = true,
  final bool isNamed = false,
  final bool isOptionalPositional = false,

  /// Whether a named parameter has `required`.
  final bool isRequired = false,
  final String? defaultValue,

  /// Doc comments and annotations, as written, that move onto the parameter.
  final String metadata = '',

  /// The comment that ended the field's line, as written. It follows the
  /// parameter.
  final String comment = '',
}) {
  this
    : assert(!(isNamed && isOptionalPositional)),
      assert(!isRequired || isNamed),
      assert(!isRequired || defaultValue == null);
}

/// The primary constructor header that replaces the class name, for example
/// `const Pair(final int left, final int right)`.
String primaryHeader(
  String name,
  List<HeaderParam> params, {
  String typeParameters = '',
  bool isConst = false,
}) {
  String write(HeaderParam p) => [
    // A doc comment runs to the end of its line.
    if (p.metadata.isNotEmpty)
      p.metadata.contains('//') ? '${p.metadata}\n' : p.metadata,
    if (p.isRequired) 'required',
    if (p.type case final type?)
      '${p.isFinal ? 'final' : 'var'} $type ${p.name}'
    else
      'super.${p.name}',
    if (p.defaultValue case final value?) '= $value',
    // A line comment runs to the end of its line. The formatter then puts the
    // comma before it.
    if (p.comment.isNotEmpty)
      p.comment.contains('//') ? '${p.comment}\n' : p.comment,
  ].join(' ');

  final positional = [
    for (final p in params)
      if (!p.isNamed && !p.isOptionalPositional) write(p),
  ];
  final optional = [
    for (final p in params)
      if (p.isOptionalPositional) write(p),
  ];
  final named = [
    for (final p in params)
      if (p.isNamed) write(p),
  ];
  final groups = [
    ...positional,
    if (optional.isNotEmpty) '[${optional.join(', ')}]',
    if (named.isNotEmpty) '{${named.join(', ')}}',
  ];
  return '${isConst ? 'const ' : ''}$name$typeParameters(${groups.join(', ')})';
}
