import 'package:ch22_feed/feed.dart';
import 'package:test/test.dart';

void main() {
  // #region lazy
  group('nothing runs until something listens', () {
    test('calling the function does not start the body', () {
      final log = <String>[];
      feedOf([100, 200], log);
      expect(log, isEmpty);
    });

    test('and listening runs all of it', () async {
      final log = <String>[];
      expect(await totalOf(feedOf([100, 200], log)), 300);
      expect(log, ['feed started', 'sending 100', 'sending 200', 'feed done']);
    });

    test('the same is true of a sync* Iterable, without any waiting', () {
      expect(runningTotals([100, 200, 50]), [100, 300, 350]);
      expect(runningTotals(<int>[]), isEmpty);
    });
  });
  // #endregion lazy

  // #region verbs
  group('study 12 verbs, over values that have not arrived', () {
    test('where and take, on a stream', () async {
      final feed = feedOf([700, 1000, 250, 5000, 2000, 9000], []);
      expect(await largeIn(feed).toList(), [1000, 5000, 2000]);
    });

    test('and the stream stops being asked once take has enough', () async {
      final log = <String>[];
      await largeIn(feedOf([1000, 2000, 3000, 4000], log)).toList();
      expect(log, isNot(contains('sending 4000')));
    });

    test('map, fold and firstWhere answer the same way too', () async {
      expect(await feedOf([700, 250], []).map((a) => a * 2).toList(), [
        1400,
        500,
      ]);
      expect(await feedOf([700, 250], []).fold<int>(0, (s, a) => s + a), 950);
      expect(await feedOf([700, 1000], []).firstWhere((a) => a >= 1000), 1000);
    });

    test('and yield* sends on every value of another stream', () async {
      expect(await largeFrom([700, 1000, 250, 5000]).toList(), [1000, 5000]);
      expect(await largeFrom([1, 2]).toList(), isEmpty);
    });
  });
  // #endregion verbs

  // #region leaving
  group('leaving an await for cancels the subscription', () {
    test('the feed is never asked for the rest', () async {
      final log = <String>[];
      expect(await firstLargeIn(feedOf([700, 1000, 250], log)), 1000);
      expect(log, ['feed started', 'sending 700', 'sending 1000']);
    });

    test(
      'and running out is a different answer from finding nothing',
      () async {
        final log = <String>[];
        expect(await firstLargeIn(feedOf([700, 250], log)), isNull);
        expect(log.last, 'feed done');
      },
    );
  });
  // #endregion leaving

  // #region once
  group('a stream can be listened to once', () {
    test('the second listener is a StateError', () async {
      final feed = feedOf([100, 200], []);
      expect(await totalOf(feed), 300);
      expect(totalOf(feed), throwsStateError);
    });

    test(
      'and a broadcast stream does not fix what you think it fixes',
      () async {
        final shared = feedOf([100, 200], []).asBroadcastStream();
        expect(await totalOf(shared), 300);
        expect(await totalOf(shared), 0);
      },
    );
  });
  // #endregion once

  // #region trouble
  group('a failure in the middle of a feed', () {
    test('reaches the await for, and study 20 catches it there', () async {
      expect(await totalUntilFault(feedWithFault([700, 250, -1, 1000])), (
        950,
        'a till reported -1',
      ));
    });

    test('and a feed with nothing wrong reports no fault', () async {
      expect(await totalUntilFault(feedWithFault([700, 250])), (950, null));
    });

    test('but uncaught it ends the stream, not just the value', () {
      expect(
        feedWithFault([700, -1, 1000]).toList(),
        throwsA(isA<TillFault>()),
      );
    });
  });
  // #endregion trouble
}
