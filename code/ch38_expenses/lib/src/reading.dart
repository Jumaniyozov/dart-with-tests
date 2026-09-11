import 'money.dart';

// #region reading
/// What came of trying to read an amount someone typed.
///
/// `sealed` means this file lists every case there will ever be, so a `switch`
/// over a `Reading` is checked for completeness at compile time — study 16's
/// rule, put to work. Add a third case here and every switch that does not
/// handle it stops compiling.
///
/// The base carries a `const` constructor because its subclasses are `const`,
/// and a constant constructor cannot call a non-constant one.
sealed class const Reading();

/// Text that was an amount, and the amount it was.
final class const Understood(final Money money) extends Reading {}

/// Text that was not an amount, and what was wrong with it.
///
/// This is the whole reason the study exists. Study 24's `penceFrom` answered
/// `null`, which says *no* and stops. A reason can be printed.
final class const Unreadable(final String reason) extends Reading {}

/// Text that *was* an amount, and an amount this program will not hold.
///
/// `-5.00` is perfectly readable, and this program will not hold it. That is
/// a fact about the domain rather than about the typing, so it is worth its
/// own case and its own exit code — 24.2 depends on those being different
/// failures.
final class const Refused(final String reason) extends Reading {}
// #endregion reading

// #region read
/// Read pounds and pence from what a person typed.
///
/// Every failure here is **expected**. A person mistyping an amount is not a
/// bug in this program, it is the normal use of a terminal, so it comes back
/// as a value the caller must look at rather than as an exception it might
/// forget to catch.
Reading readMoney(String text) {
  if (text.isEmpty) return const Unreadable('an amount cannot be empty');

  final negative = text.startsWith('-');
  final body = negative ? text.substring(1) : text;
  final parts = body.split('.');

  final pence = switch (parts) {
    [final pounds] when _isDigits(pounds) => int.parse(pounds) * 100,
    [final pounds, final part]
        when _isDigits(pounds) && _isDigits(part) && part.length == 2 =>
      int.parse(pounds) * 100 + int.parse(part),
    [_, final part] when _isDigits(part) && part.length != 2 => null,
    _ => null,
  };

  if (pence == null) {
    return Unreadable(switch (parts) {
      [_, final part] when part.length != 2 =>
        'pence are two digits, and "$part" is ${part.length}',
      [_, _, _, ...] => 'an amount has one dot, not ${parts.length - 1}',
      _ => '"$text" is not digits',
    });
  }
  // Checked here rather than caught from [Money.fromPence]. That constructor
  // throws an `ArgumentError`, and an `Error` means the *program* is wrong —
  // Effective Dart says not to catch one. So the edge asks the question first,
  // and `Money.fromPence` is left to catch programmers rather than typists.
  if (negative && pence != 0) {
    return const Refused('money is never negative');
  }
  return Understood(Money.fromPence(pence));
}

/// Digits and nothing else — not a sign, not a space, not `0x`.
///
/// `int.tryParse` reads `0x10` as 16 and takes a sign wherever it is handed
/// one, so `5.-1` would parse as 5 and -1 and answer 499. Study 24 shipped
/// that bug and an audit found it.
bool _isDigits(String text) =>
    text.isNotEmpty &&
    text.codeUnits.every((unit) => unit >= 0x30 && unit <= 0x39);
// #endregion read
