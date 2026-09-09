import 'package:test/test.dart';

import 'challenges.dart';

/// The trace a failure arrives with, as text.
String traceOf(void Function() body) {
  try {
    body();
  } on FormatException catch (_, trace) {
    return trace.toString();
  }
  return 'nothing was thrown';
}

void main() {
  group('challenge 1 — add up, or say which entry stopped you', () {
    test('adds up a list that is all numbers', () {
      expect(sumOf(['1', '2', '3']), 6);
      expect(sumOf(<String>[]), 0);
    });

    test('and names the first entry that is not', () {
      expect(
        () => sumOf(['1', 'x', 'y']),
        throwsA(isA<BadEntry>().having((e) => e.at, 'at', 1)),
      );
      expect(
        () => sumOf(['no']),
        throwsA(isA<BadEntry>().having((e) => e.at, 'at', 0)),
      );
    });
  });

  group('challenge 2 — strict about the text', () {
    test('reads the digits it is given', () {
      expect(strictWholeFrom('12'), 12);
      expect(strictWholeFrom('0'), 0);
    });

    test('and refuses what int.tryParse would have let through', () {
      expect(() => strictWholeFrom(' 12 '), throwsFormatException);
      expect(() => strictWholeFrom('+12'), throwsFormatException);
      expect(() => strictWholeFrom('-12'), throwsFormatException);
      expect(() => strictWholeFrom(''), throwsFormatException);
    });
  });

  group('challenge 3 — a record either way', () {
    test('logs and answers when the text is a number', () {
      final log = <String>[];
      expect(readInto('12', log), 12);
      expect(log, ['trying', 'read', 'done']);
    });

    test('logs and refuses when it is not', () {
      final log = <String>[];
      expect(() => readInto('x', log), throwsFormatException);
      expect(log, ['trying', 'refused', 'done']);
    });

    test('and the failure still points at where it started', () {
      expect(traceOf(() => readInto('x', [])), contains('wholeFrom'));
    });
  });
}
