// #region imports
// Three ways to say which names you want, and where they came from.

// `as` gives the library a prefix. Every name from it now arrives with an
// address, so `math.max` can never be mistaken for a `max` of your own.
import 'dart:math' as math;

// `show` takes one name and leaves the rest. This is the barrel, and `Money`
// is all of it, but saying so keeps the line honest if the barrel grows.
import 'package:ch23_expenses/expenses.dart' show Money;

// `hide` takes everything except. `Backdoor` exists in that file and is not
// something this program should be able to reach for by accident.
import 'package:ch23_expenses/src/crowded.dart' hide Backdoor;

void main() {
  print(Money.fromPence(math.max(1250, 99)).asText);
  print(Amount.fromPence(500).pence);
}
// #endregion imports
