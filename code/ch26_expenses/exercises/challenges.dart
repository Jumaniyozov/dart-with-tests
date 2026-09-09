// Study 26 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// Each one asks the same question about a different failure: is this the
// world being awkward, or this program being wrong? The first answers with a
// value, the second with an exception, and the third is about what happens
// when you answer with neither.

/// 1. Read a share out of text, and say why when you cannot.
///
///    A share is a whole number from 0 to 100. Every failure here is expected —
///    a person typing into a terminal is not a bug — so none of them throws.
///
///    `readShare('40')` is a [Share] of 40. `readShare('abc')` is a
///    [NotAShare] reading `"abc" is not digits`. `readShare('101')` is a
///    [NotAShare] reading `a share is 0 to 100, not 101`. Empty text reads
///    `a share cannot be empty`.
///
///    `sealed` is doing work here: add a case and every switch in this file
///    stops compiling until it is handled.
sealed class const Reading();

final class const Share(final int percent) extends Reading {}

final class const NotAShare(final String reason) extends Reading {}

Reading readShare(String text) => throw UnimplementedError('challenge 1');

/// 2. The same failure, on the other side of the boundary.
///
///    [meanOf] is asked for the mean of some numbers. An empty list is not a
///    person mistyping — it is a caller that did not check, which is a bug in
///    the program. So this one **throws** a [StateError] saying
///    `no numbers to average`, and does not return a reason.
///
///    [meanOrNull] is the same question asked by code that genuinely does not
///    know yet, and answers `null` for empty.
///
///    Both agree on `[2, 4, 6]`, which is 4.
int meanOf(List<int> numbers) => throw UnimplementedError('challenge 2');

int? meanOrNull(List<int> numbers) => throw UnimplementedError('challenge 2');

/// 3. A catch that keeps the error and lets it go.
///
///    [attempt] runs `work` and must record what went wrong in [noted] before
///    letting the error continue to the caller. Swallowing it — an empty
///    `catch`, or one that only logs — is what `empty_catches` exists to stop,
///    and it is how a program comes to fail silently at three in the morning.
///
///    Use `rethrow`, not `throw error`: `use_rethrow_when_possible` is on in
///    this book's lint set, and rethrowing keeps the original stack trace.
List<String> noted = [];

T attempt<T>(T Function() work) => throw UnimplementedError('challenge 3');
