import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

void main() {
  test('keeps groups, defaults, var and super', () {
    final header = primaryHeader(
      'Conv',
      [
        HeaderParam('_secret', type: 'int'),
        HeaderParam('id'),
        HeaderParam('name', type: 'String', isNamed: true, isRequired: true),
        HeaderParam(
          'size',
          type: 'int',
          isFinal: false,
          isNamed: true,
          defaultValue: '0',
        ),
      ],
      typeParameters: '<T>',
      isConst: true,
    );
    expect(
      header,
      'const Conv<T>(final int _secret, super.id, '
      '{required final String name, var int size = 0})',
    );
  });

  test('optional positional parameters go in brackets', () {
    final header = primaryHeader('Span', [
      HeaderParam('start', type: 'int'),
      HeaderParam(
        'end',
        type: 'int',
        isOptionalPositional: true,
        defaultValue: '0',
      ),
    ]);
    expect(header, 'Span(final int start, [final int end = 0])');
  });

  test('a doc comment ends its own line', () {
    final header = primaryHeader('Pair', [
      HeaderParam('left', type: 'int', metadata: '/// The left side.'),
    ]);
    expect(header, 'Pair(/// The left side.\n final int left)');
  });

  test('a trailing comment follows its parameter and ends the line', () {
    // The formatter puts the comma before the comment.
    final header = primaryHeader('User', [
      HeaderParam('name', type: 'String', comment: '// the display name'),
      HeaderParam('age', type: 'int'),
    ]);
    expect(
      header,
      'User(final String name // the display name\n, final int age)',
    );
  });

  test('a named and optional positional parameter is inconsistent', () {
    expect(
      () => HeaderParam('x', isNamed: true, isOptionalPositional: true),
      throwsA(isA<AssertionError>()),
    );
  });

  test('a required parameter must be named', () {
    expect(
      () => HeaderParam('x', isRequired: true),
      throwsA(isA<AssertionError>()),
    );
  });

  test('a required parameter has no default value', () {
    expect(
      () =>
          HeaderParam('x', isNamed: true, isRequired: true, defaultValue: '0'),
      throwsA(isA<AssertionError>()),
    );
  });
}
