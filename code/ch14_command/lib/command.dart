// #region verb
/// The three things this little language can do.
enum Verb { add, remove, total }

/// A command: what to do, and the number it was given, if it was given one.
typedef Command = (Verb verb, int? number);
// #endregion verb

// #region parse
/// Reads a typed line into a [Command], or nothing when it is not one.
Command? parse(String line) {
  final words = line.split(' ').where((word) => word.isNotEmpty).toList();

  return switch (words) {
    ['total'] => (Verb.total, null),
    ['add', final amount] => (Verb.add, int.tryParse(amount)),
    ['remove', final position] => (Verb.remove, int.tryParse(position)),
    _ => null,
  };
}
// #endregion parse

// #region run
/// What the command says it will do.
String run(Command command) => switch (command) {
  (Verb.total, _) => 'the balance',
  (Verb.add, final int amount) when amount > 0 => 'add $amount pence',
  (Verb.add, final int amount) => 'an amount must be more than $amount',
  (Verb.add, null) => 'add needs an amount',
  (Verb.remove, final int position) => 'remove entry $position',
  (Verb.remove, null) => 'remove needs a position',
};
// #endregion run

// #region ifcase
/// The number in [line], when it has one.
int? numberIn(String line) {
  if (parse(line) case (_, final int number)) {
    return number;
  }
  return null;
}
// #endregion ifcase

// #region rest
/// The first word of [line], whatever follows it.
String? verbOf(String line) {
  final words = line.split(' ').where((word) => word.isNotEmpty).toList();

  return switch (words) {
    [final first, ...] => first,
    _ => null,
  };
}
// #endregion rest

// #region every
/// Every line that is a command, run. Lines that are not are left out.
List<String> runAll(List<String> lines) => [
  for (final line in lines)
    if (parse(line) case final Command command) run(command),
];
// #endregion every
