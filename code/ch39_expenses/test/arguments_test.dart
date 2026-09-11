import 'package:ch39_expenses/expenses.dart';
import 'package:test/test.dart';

/// What `package:args` does with the arguments, asserted rather than assumed.
///
/// Every claim study 33 makes about the dependency is executed here. That is
/// not ceremony: a dependency is somebody else's code, so the only honest way
/// to say what it does is to run it.
void main() {
  // #region given
  /// Study 27's two seams, unchanged. Nothing about taking a dependency
  /// changed what a test has to hand `run` to make it run.
  final today = Day(2026, 9, 9);
  late Store store;
  setUp(() => store = InMemoryStore());
  // #endregion given

  // #region flags
  group('a flag is a flag wherever it appears', () {
    test(
      'after the words, which is what broke the hand-rolled version',
      () async {
        final outcome = await run(
          ['add', '900.00', 'food', 'a', 'big', 'dinner', '--anyway'],
          store,
          today,
        );
        expect(outcome.code, okay);
        expect(
          (await store.expenses()).single.note,
          'a big dinner',
          reason:
              'study 32 stripped --anyway out by hand because the list '
              'pattern would have put it in the note. The parser knows.',
        );
      },
    );

    test('and before them', () async {
      await run(['add', '--anyway', '900.00', 'food', 'dinner'], store, today);
      expect((await store.expenses()).single.note, 'dinner');
    });

    test('and it belongs to add, not to the program', () async {
      final outcome = await run(['list', '--anyway'], store, today);
      expect(
        outcome.code,
        misuse,
        reason:
            'addCommand gives each command its own parser, so a flag '
            'declared on add is unknown to list',
      );
      expect(outcome.err, 'Could not find an option named "--anyway".');
    });
  });
  // #endregion flags

  // #region help
  group('help', () {
    test('--help prints it, and so does -h', () async {
      final long = await run(['--help'], store, today);
      final short = await run(['-h'], store, today);
      expect(long.code, okay);
      expect(long.out, short.out);
      expect(long.out, contains('--anyway'));
      expect(
        long.out,
        contains('record it even if it breaks a budget'),
        reason: 'the help text for a flag is written once, on the flag',
      );
    });

    test('and the bare word still works, because study 24 taught it', () async {
      expect((await run(['help'], store, today)).out, usage);
      expect((await run([], store, today)).out, usage);
    });

    test('and nothing else abbreviates', () async {
      final outcome = await run(['--hel'], store, today);
      expect(
        outcome.code,
        misuse,
        reason:
            'args gives single-letter abbreviations and not unique '
            'prefixes; --hel is not --help',
      );
      expect(outcome.err, 'Could not find an option named "--hel".');
    });
  });
  // #endregion help

  // #region file
  group('--file says where the tracker lives', () {
    test('separated, joined by =, or by its letter', () {
      expect(fileFrom(['--file', 'a.txt', 'list']), 'a.txt');
      expect(fileFrom(['--file=b.txt', 'list']), 'b.txt');
      expect(fileFrom(['-f', 'c.txt', 'list']), 'c.txt');
      expect(fileFrom(['-fd.txt', 'list']), 'd.txt');
    });

    test('and falls back to the database, not to the file it replaced', () {
      expect(fileFrom(['list']), 'expenses.db');
      expect(fileFrom([]), 'expenses.db');
    });

    test('and says nothing about arguments it cannot read', () {
      expect(
        fileFrom(['--nonsense']),
        'expenses.db',
        reason:
            'run reports the bad argument; reporting it twice would be '
            'worse than not reporting it here',
      );
    });
  });
  // #endregion file
}
