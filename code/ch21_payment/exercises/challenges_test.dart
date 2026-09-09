import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — all the waiting at once', () {
    test('adds up every answer', () async {
      final log = <String>[];
      expect(
        await totalOf([
          () => slow('a', 1, log),
          () => slow('b', 2, log),
          () => slow('c', 3, log),
        ]),
        6,
      );
    });

    test('and every job starts before any of them finishes', () async {
      final log = <String>[];
      await totalOf([
        () => slow('a', 1, log),
        () => slow('b', 2, log),
        () => slow('c', 3, log),
      ]);
      expect(log.sublist(0, 3), ['a start', 'b start', 'c start']);
    });

    test('and no jobs at all add up to nothing', () async {
      expect(await totalOf([]), 0);
    });
  });

  group('challenge 2 — say what happened, either way', () {
    test('when the job answers', () async {
      final log = <String>[];
      expect(await attempt(() async => 7, log), 'ok 7');
      expect(log.last, 'done');
    });

    test('and when it fails', () async {
      final log = <String>[];
      expect(await attempt(failing, log), 'failed: the job could not finish');
      expect(log.last, 'done');
    });
  });

  group('challenge 3 — the one word that is not there', () {
    test('a job that fails is reported as failed', () async {
      expect(await report(failing), 'failed');
    });

    test('and one that does not is still reported as ok', () async {
      expect(await report(() async => 7), 'ok');
    });
  });
}
