import 'package:ch14_command/command.dart';
import 'package:test/test.dart';

void main() {
  // #region parsing
  group('a list pattern matches a shape and pulls it apart', () {
    test('each command shape parses', () {
      expect(parse('total'), (Verb.total, null));
      expect(parse('add 250'), (Verb.add, 250));
      expect(parse('remove 3'), (Verb.remove, 3));
    });

    test('the pattern counts the words, so a missing one does not match', () {
      expect(parse('add'), isNull);
      expect(parse('add 250 more'), isNull);
      expect(parse(''), isNull);
    });

    test('a word that is not a number parses to a command with no number', () {
      expect(parse('add banana'), (Verb.add, null));
    });

    test('extra spaces are not extra words', () {
      expect(parse('  add   250  '), (Verb.add, 250));
    });
  });
  // #endregion parsing

  // #region running
  group('a record pattern decides and destructures at once', () {
    test('a guard splits one shape into two answers', () {
      expect(run((Verb.add, 250)), 'add 250 pence');
      expect(run((Verb.add, 0)), 'an amount must be more than 0');
      expect(run((Verb.add, -5)), 'an amount must be more than -5');
    });

    test('a typed pattern does the null check for you', () {
      expect(run((Verb.add, null)), 'add needs an amount');
      expect(run((Verb.remove, null)), 'remove needs a position');
      expect(run((Verb.remove, 3)), 'remove entry 3');
    });

    test('a wildcard ignores a field it does not care about', () {
      expect(run((Verb.total, null)), 'the balance');
      expect(run((Verb.total, 99)), 'the balance');
    });
  });
  // #endregion running

  // #region matching
  group('matching without a switch', () {
    test('if-case binds only when the pattern matches', () {
      expect(numberIn('add 250'), 250);
      expect(numberIn('total'), isNull);
      expect(numberIn('fly'), isNull);
    });

    test('a rest element matches whatever is left', () {
      expect(verbOf('remove 3'), 'remove');
      expect(verbOf('  add   250  '), 'add');
      expect(verbOf('fly me to the moon'), 'fly');
      expect(verbOf('   '), isNull);
    });

    test('a case inside a collection keeps only what matched', () {
      expect(runAll(['total', 'fly', 'add 250']), [
        'the balance',
        'add 250 pence',
      ]);
      expect(runAll(['fly']), <String>[]);
    });
  });
  // #endregion matching
}
