import 'package:args/args.dart';
import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — a parser that constrains', () {
    test('--sort defaults to day and takes amount', () {
      final parser = sorting();
      expect(parser.parse([]).option('sort'), 'day');
      expect(parser.parse(['--sort', 'amount']).option('sort'), 'amount');
      expect(parser.parse(['--sort=amount']).option('sort'), 'amount');
    });

    test('and refuses anything else, in words the parser chose', () {
      expect(
        () => sorting().parse(['--sort', 'colour']),
        throwsA(
          isA<ArgParserException>().having(
            (e) => e.message,
            'message',
            '"colour" is not an allowed value for option "--sort".',
          ),
        ),
      );
    });

    test('--only collects every value it is given', () {
      final parser = sorting();
      expect(parser.parse([]).multiOption('only'), <String>[]);
      expect(
        parser.parse(['-o', 'food', '--only', 'transport']).multiOption('only'),
        ['food', 'transport'],
      );
      expect(parser.parse(['-ofood']).multiOption('only'), ['food']);
    });
  });

  group('challenge 2 — a default is not a choice', () {
    test('answers null when nobody said', () {
      expect(chosenFile([]), isNull);
      expect(chosenFile(['list']), isNull);
    });

    test('and the value when somebody did', () {
      expect(chosenFile(['--file', 'a.txt']), 'a.txt');
      expect(chosenFile(['--file=b.txt']), 'b.txt');
    });

    test('including when they chose the default themselves', () {
      expect(
        chosenFile(['--file', 'expenses.txt']),
        'expenses.txt',
        reason: 'saying the default out loud is still saying it',
      );
    });
  });

  group('challenge 3 — what the parser made of it', () {
    test('a command and the words after it', () {
      expect(describe(['add', '12.50', 'food']), 'add: 12.50 food');
      expect(describe(['list']), 'list: ');
      expect(describe(['add', '--anyway', '1.00']), 'add: 1.00');
    });

    test('no command at all', () {
      expect(describe([]), 'no command');
      expect(describe(['wibble']), 'no command');
    });

    test('and what the parser refused', () {
      expect(
        describe(['--nope']),
        'unreadable: Could not find an option named "--nope".',
      );
      expect(
        describe(['add', '-5']),
        'unreadable: Could not find an option or flag "-5".',
      );
    });
  });
}
