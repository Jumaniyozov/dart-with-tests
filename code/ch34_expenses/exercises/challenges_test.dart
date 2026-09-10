import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — the next version', () {
    test('above 1.0.0, the rule everybody quotes', () {
      expect(nextVersion('1.4.2', Change.fix), '1.4.3');
      expect(nextVersion('1.4.2', Change.feature), '1.5.0');
      expect(nextVersion('1.4.2', Change.breaking), '2.0.0');
      expect(nextVersion('2.7.9', Change.feature), '2.8.0');
    });

    test('and below it, every rule shifts one place left', () {
      expect(nextVersion('0.4.2', Change.fix), '0.4.3');
      expect(nextVersion('0.4.2', Change.feature), '0.4.3');
      expect(nextVersion('0.4.2', Change.breaking), '0.5.0');
    });

    test('and the numbers are numbers, not text', () {
      expect(nextVersion('1.9.9', Change.feature), '1.10.0');
      expect(nextVersion('0.9.9', Change.breaking), '0.10.0');
    });
  });

  group('challenge 2 — what a caret allows', () {
    test('above 1.0.0 the bound is the next major', () {
      expect(allows('^2.7.0', '2.7.0'), isTrue);
      expect(allows('^2.7.0', '2.99.4'), isTrue);
      expect(allows('^2.7.0', '3.0.0'), isFalse);
      expect(allows('^2.7.0', '2.6.9'), isFalse);
    });

    test('below it the bound is the next minor', () {
      expect(allows('^0.4.2', '0.4.2'), isTrue);
      expect(allows('^0.4.2', '0.4.9'), isTrue);
      expect(allows('^0.4.2', '0.5.0'), isFalse);
      expect(allows('^0.4.2', '0.3.9'), isFalse);
    });

    test('and the comparison is numeric', () {
      expect(
        allows('^1.9.0', '1.10.0'),
        isTrue,
        reason: '1.10.0 is above 1.9.0; as text it is below',
      );
      expect(allows('^0.9.0', '0.10.0'), isFalse);
    });

    test('and anything that is not a version is false, not a throw', () {
      expect(allows('^2.7.0', 'two point seven'), isFalse);
      expect(allows('^2.7.0', '2.7'), isFalse);
      expect(allows('2.7.0', '2.7.0'), isFalse, reason: 'no caret, no match');
      expect(allows('^2.7.0', ''), isFalse);
    });
  });

  group('challenge 3 — what the surface did', () {
    test('anything gone is breaking, whatever came with it', () {
      expect(changeBetween({'Money', 'Day'}, {'Money'}), Change.breaking);
      expect(
        changeBetween({'Money', 'Day'}, {'Money', 'Period'}),
        Change.breaking,
        reason: 'one added and one removed is still a removal',
      );
    });

    test('nothing gone and something new is a feature', () {
      expect(changeBetween({'Money'}, {'Money', 'Day'}), Change.feature);
      expect(changeBetween(<String>{}, {'Money'}), Change.feature);
    });

    test('and two identical surfaces are a fix', () {
      expect(changeBetween({'Money', 'Day'}, {'Day', 'Money'}), Change.fix);
      expect(changeBetween(<String>{}, <String>{}), Change.fix);
    });
  });
}
