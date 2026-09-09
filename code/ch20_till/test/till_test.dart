import 'package:ch20_till/till.dart';
import 'package:ch20_till/v1.dart' as v1;
import 'package:test/test.dart';

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
  // #region kinds
  group('an Error and an Exception are two different claims', () {
    test('the ones dart:core throws are sorted the same way', () {
      expect(FormatException('bad'), isA<Exception>());
      expect(ArgumentError('bad'), isA<Error>());
      expect(StateError('bad'), isA<Error>());
    });

    test('and the two families do not overlap', () {
      expect(ArgumentError('bad'), isNot(isA<Exception>()));
      expect(FormatException('bad'), isNot(isA<Error>()));
      expect(BadLine(1, 'x'), isA<Exception>());
    });
  });
  // #endregion kinds

  // #region refusing
  group('refusing text', () {
    test('the exception carries the text that caused it', () {
      expect(
        () => penceFrom('twelve'),
        throwsA(
          isA<FormatException>().having((e) => e.source, 'source', 'twelve'),
        ),
      );
    });

    test('a negative is not an amount a till can take', () {
      expect(() => penceFrom('-3'), throwsFormatException);
      expect(() => penceFrom('12.-3'), throwsFormatException);
    });

    test('and a function that never returns still fits where an int goes', () {
      expect(() => noAmount('x'), throwsFormatException);
      expect(wholeIn('7', '7'), 7);
    });
  });
  // #endregion refusing

  // #region answers
  group('one failure, two answers', () {
    const roll = ['12.34', 'twelve', '0.50'];

    test('stop, and say which line', () {
      expect(() => totalOf(roll), throwsA(isA<BadLine>()));
      expect(totalOf(['12.34', '0.50']), 1284);
    });

    test('or carry on, and say how many were skipped', () {
      expect(totalIgnoringBad(roll), (1284, 1));
      expect(totalIgnoringBad(['no', 'no']), (0, 2));
    });

    test('and the one that stops says more than the one that does not', () {
      expect(
        () => totalOf(roll),
        throwsA(
          isA<BadLine>()
              .having((e) => e.number, 'number', 2)
              .having((e) => e.typed, 'typed', 'twelve'),
        ),
      );
    });
  });
  // #endregion answers

  // #region order
  group('finally runs on both ways out', () {
    test('after a reading that worked', () {
      final log = <String>[];
      expect(logged('12.34', log), 1234);
      expect(log, ['read 12.34', 'done 12.34']);
    });

    test('and after one that did not, before the caller hears about it', () {
      final log = <String>[];
      expect(() => logged('twelve', log), throwsFormatException);
      expect(log, ['refused twelve', 'done twelve']);
    });

    test('but a return inside it throws the exception away entirely', () {
      expect(v1.lost('twelve'), 0);
      expect(v1.lost('12.34'), 0);
    });
  });
  // #endregion order

  // #region trace
  group('rethrow keeps the evidence and throw does not', () {
    test('rethrow arrives with the trace it started with', () {
      expect(traceOf(() => logged('twelve', [])), contains('penceFrom'));
      expect(traceOf(() => logged('twelve', [])), contains('noAmount'));
    });

    test('throwing the caught object starts the trace over', () {
      expect(
        traceOf(() => v1.logged('twelve', [])),
        isNot(contains('penceFrom')),
      );
      expect(
        traceOf(() => v1.logged('twelve', [])),
        isNot(contains('noAmount')),
      );
    });
  });
  // #endregion trace

  // #region lenient
  group('int.tryParse is more forgiving than it looks', () {
    test('it trims space and accepts a leading sign', () {
      expect(int.tryParse(' 12 '), 12);
      expect(int.tryParse('+12'), 12);
      expect(int.tryParse('-12'), -12);
    });

    test('so this parser accepts a little more than it says', () {
      expect(penceFrom(' 12 '), 1200);
      expect(penceFrom('+12'), 1200);
    });
  });
  // #endregion lenient
}
