// Study 16 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// No `default` and no `_` anywhere in this file. If a switch seems to need
// one, the family is closed and you have not used every member of it.

/// A message in a support inbox. Three kinds, and never a fourth.
sealed class Message {
  final String from;

  const new(this.from);
}

class const Question(super.from, final String text) extends Message {}

class const Reply(super.from, final String text, final int answers)
    extends Message {}

class const Closed(super.from, final String reason) extends Message {}

/// 1. One line of the inbox listing.
///    A question reads `'ada asks: when?'`, a reply reads
///    `'grace replies to 7'`, and a closed message reads `'alan closed: spam'`.
String line(Message message) {
  throw UnimplementedError('challenge 1');
}

/// 2. How long a message may wait, in hours: a question 24, a reply 72, and
///    a closed message 0. A question from `'vip'` waits only 4, but a reply
///    to one still waits 72.
int slaHours(Message message) {
  throw UnimplementedError('challenge 2');
}

/// 3. Which queue a message joins.
///    The two values already carry their label and their size. Add `of`,
///    which puts a question from `'vip'` and every reply on [urgent] and
///    everything else on [normal]; and `isTight`, true when the queue holds
///    fewer than ten.
enum Priority(final String label, final int maxQueue) {
  urgent('Urgent', 5),
  normal('Normal', 50);

  static Priority of(Message message) =>
      throw UnimplementedError('challenge 3');

  bool get isTight => throw UnimplementedError('challenge 3');
}
