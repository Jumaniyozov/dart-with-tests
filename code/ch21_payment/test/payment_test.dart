import 'dart:async';

import 'package:ch21_payment/payment.dart';
import 'package:ch21_payment/v1.dart' as v1;
import 'package:test/test.dart';

void main() {
  // #region now
  group('the future is here now; the value is not', () {
    test('the call hands one back before the answer exists', () {
      expect(authorise(100), isA<Future<int>>());
    });

    test('and the body has already run, as far as its first await', () async {
      final log = <String>[];
      final pending = step('a', log);
      expect(log, ['a start']);
      await pending;
      expect(log, ['a start', 'a end']);
    });
  });
  // #endregion now

  // #region failing
  group('an async function does not throw; its future fails', () {
    test('the call itself returns, even when the argument is refused', () {
      var reached = false;
      final pending = authorise(0);
      reached = true;
      expect(reached, isTrue);
      expect(pending, throwsArgumentError);
    });

    test('and study 20 catches it, one await later', () async {
      await expectLater(authorise(-1), throwsArgumentError);
      await expectLater(authorise(90000), throwsA(isA<CardDeclined>()));
    });
  });
  // #endregion failing

  // #region order
  group('await does not block', () {
    test('one after the other, each waiting for the last', () async {
      expect(await oneAtATime(), ['a start', 'a end', 'b start', 'b end']);
    });

    test('or both out at once, and finishing in the order they left', () async {
      expect(await together(), ['a start', 'b start', 'a end', 'b end']);
    });
  });
  // #endregion order

  // #region missing
  group('the await that was left out', () {
    test('reports a success that has not happened, then fails alone', () async {
      Object? orphan;
      await runZonedGuarded(() async {
        expect(await v1.takePayment(90000), 'authorised');
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, stack) => orphan = error);

      expect(orphan, isA<CardDeclined>());
      expect(await takePayment(90000), 'declined: over the floor limit');
    });
  });
  // #endregion missing
}
