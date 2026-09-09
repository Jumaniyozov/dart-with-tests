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

  group('challenge 2 — who is wrong', () {
    test('multiplies the amount by the quantity', () {
      expect(priceOf('12', 3), 36);
      expect(priceOf('0', 9), 0);
    });

    test('text that is not a number is the world being wrong', () {
      expect(() => priceOf('twelve', 3), throwsFormatException);
    });

    test('and a quantity below one is the caller being wrong', () {
      expect(() => priceOf('12', 0), throwsArgumentError);
      expect(() => priceOf('12', -1), throwsArgumentError);
      expect(
        () => priceOf('12', 0),
        throwsA(
          isA<Error>().having((e) => e is Exception, 'is Exception', isFalse),
        ),
      );
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
