// Study 33 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are about reading a dependency's documentation by running it. Every
// assertion below was measured against `args` 2.7.0 before it was written, and
// none of them is guessable from the method names.

import 'package:args/args.dart';

/// 1. A parser that constrains what it will accept.
///
///    [sorting] answers an [ArgParser] with two things on it:
///
///    - `--sort`, which takes a value, allows only `day` and `amount`, and
///      defaults to `day`;
///    - `--only`, abbreviated `-o`, which may be given more than once and
///      collects every value into a list.
///
///    `addOption` takes `allowed`, and there is a separate `addMultiOption` for
///    the second. A value outside `allowed` throws rather than being ignored,
///    and the message is the parser's — the test says exactly what it is.
ArgParser sorting() => throw UnimplementedError('1');

/// 2. Telling a default apart from a choice.
///
///    [chosenFile] answers the value of `--file` only when it was actually
///    given, and `null` when the parser supplied the default. `fileFrom` cannot
///    do this: `option` hands back the default and never says where it came
///    from.
///
///    [ArgResults] has one member that answers exactly this question. Find it.
///    The parser you need is [sorting]'s sibling — build a small one here with
///    a single `--file` option defaulting to `expenses.txt`.
String? chosenFile(List<String> args) => throw UnimplementedError('2');

/// 3. Saying what the parser made of a line.
///
///    [describe] answers one of three strings:
///
///    - `'<name>: <words joined by spaces>'` when a command word was found —
///      `add 12.50 food` is `'add: 12.50 food'`, and a command with no words
///      after it is `'add: '` with the space still there;
///    - `'no command'` when the arguments held no command word at all,
///      including when they held nothing;
///    - `'unreadable: <message>'` when the parser threw, where the message is
///      the exception's own.
///
///    Declare the commands `add` and `list`, and one flag `--anyway` on `add`.
///    All three shapes come out of a single `parse` call and the result it
///    returns; only the third needs a `catch`.
String describe(List<String> args) => throw UnimplementedError('3');
