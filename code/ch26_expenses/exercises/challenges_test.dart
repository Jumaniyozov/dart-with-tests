import 'package:test/test.dart';

import 'challenges.dart';

String reasonOf(Reading reading) => switch (reading) {
  Share(:final percent) => '$percent',
  NotAShare(:final reason) => reason,
};

void main() {
  group('challenge 1 — an expected failure is a value', () {
    test('reads a share', () {
      expect(readShare('40'), isA<Share>());
      expect(reasonOf(readShare('40')), '40');
      expect(reasonOf(readShare('0')), '0');
      expect(reasonOf(readShare('100')), '100');
    });

    test('and says why when it cannot, without throwing', () {
      expect(reasonOf(readShare('abc')), '"abc" is not digits');
      expect(reasonOf(readShare('101')), 'a share is 0 to 100, not 101');
      expect(reasonOf(readShare('')), 'a share cannot be empty');
    });
  });

  group('challenge 2 — a bug is an exception', () {
    test('both answer the same question the same way', () {
      expect(meanOf([2, 4, 6]), 4);
      expect(meanOrNull([2, 4, 6]), 4);
    });

    test('and part company on nothing at all', () {
      expect(
        () => meanOf([]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'no numbers to average',
          ),
        ),
      );
      expect(meanOrNull([]), isNull);
    });
  });

  group('challenge 3 — a catch that does not swallow', () {
    setUp(() => noted = []);

    test('lets a working call through untouched', () {
      expect(attempt(() => 42), 42);
      expect(noted, isEmpty);
    });

    test('notes the failure and still lets it out', () {
      expect(
        () => attempt<int>(() => throw const FormatException('bad input')),
        throwsFormatException,
      );
      expect(noted, hasLength(1));
      expect(noted.single, contains('bad input'));
    });
  });
}
