// #region parse
/// The amount [typed] describes, in pence.
///
/// Accepts `'12'` and `'12.34'`. Throws a [FormatException] for anything else
/// — including a negative, which is not an amount a till can take.
int penceFrom(String typed) => switch (typed.split('.')) {
  [final pounds] => 100 * wholeIn(pounds, typed),
  [final pounds, final pence] when pence.length == 2 =>
    100 * wholeIn(pounds, typed) + wholeIn(pence, typed),
  _ => throw FormatException('not an amount', typed),
};

/// The digits of [text] as a whole number, or a refusal.
///
/// `int.tryParse` is not a validator. It trims spaces, takes a leading sign,
/// and reads `'0x10'` as sixteen — so the characters are checked first, and
/// only text that is entirely digits is parsed at all.
int wholeIn(String text, String typed) {
  const digits = '0123456789';
  final allDigits =
      text.isNotEmpty && text.split('').every((each) => digits.contains(each));
  final value = allDigits ? int.tryParse(text) : null;
  return value ?? noAmount(typed);
}

/// Refuses [typed], and never returns.
Never noAmount(String typed) => throw FormatException('not an amount', typed);
// #endregion parse

// #region badline
/// One line of a till roll was not an amount.
///
/// [FormatException] already says "this text is wrong". This says *which
/// line*, and that is the only reason to define an exception type of your own.
class const BadLine(final int number, final String typed) implements Exception {
  @override
  String toString() => 'BadLine: line $number, "$typed" is not an amount';
}
// #endregion badline

// #region total
/// Everything on the roll, added up.
///
/// A single unreadable line refuses the whole roll — a till that guesses at a
/// number is worse than a till that stops.
int totalOf(List<String> lines) {
  var total = 0;
  for (var index = 0; index < lines.length; index++) {
    try {
      total += penceFrom(lines[index]);
    } on FormatException {
      throw BadLine(index + 1, lines[index]);
    }
  }
  return total;
}
// #endregion total

// #region skipping
/// Everything readable, and a count of what was not.
///
/// The same failure, answered the other way. Which of these two is right is a
/// question about the till, not about Dart.
(int total, int skipped) totalIgnoringBad(List<String> lines) {
  var total = 0;
  var skipped = 0;
  for (final line in lines) {
    try {
      total += penceFrom(line);
    } on FormatException {
      skipped++;
    }
  }
  return (total, skipped);
}
// #endregion skipping

// #region logged
/// Reads [typed], writing what happened into [log] either way.
///
/// `rethrow` sends on the exception that arrived, with the trace it arrived
/// with. `finally` runs on both ways out.
int logged(String typed, List<String> log) {
  try {
    final pence = penceFrom(typed);
    log.add('read $typed');
    return pence;
  } on FormatException {
    log.add('refused $typed');
    rethrow;
  } finally {
    log.add('done $typed');
  }
}
// #endregion logged
