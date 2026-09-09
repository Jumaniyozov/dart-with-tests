// #region formatting
/// Money-shaped questions, attached to the type that holds the money.
///
/// Study 4 wrote this arithmetic as a function taking an `int`. It is the same
/// arithmetic. The difference is where it lives: `1234.asMoney` rather than
/// `format(1234)`, on a type nobody here owns or can open.
extension PenceFormatting on int {
  String get asMoney {
    final amount = abs();
    final sign = isNegative ? '-' : '';
    return '$sign£${amount ~/ 100}.${(amount % 100).toString().padLeft(2, '0')}';
  }

  bool get isDebit => isNegative;
}
// #endregion formatting

// #region pence
/// An amount of money, and never anything else.
///
/// The wrapper belongs to the compiler. At run time this *is* the `int` it was
/// made from — no object, no allocation, nothing to unwrap. 19.4 shows what
/// that costs.
extension type const Pence(int value) {
  /// Pounds and pence written the way a person says them.
  ///
  /// The line above declares the type and its constructor at once and has no
  /// initialiser list, so it cannot check anything — study 15's rule, in a
  /// second declaration form. A named constructor has one, so it can.
  Pence.fromParts(int pounds, int pence)
    : assert(pounds >= 0, 'make a debit by negating, not with a negative part'),
      assert(pence >= 0 && pence < 100, 'pence must be a part of a pound'),
      value = pounds * 100 + pence;

  String get asMoney => value.asMoney;
  bool get isDebit => value.isDebit;

  Pence plus(Pence other) => Pence(value + other.value);
  Pence times(int quantity) => Pence(value * quantity);
}
// #endregion pence

// #region pounds
/// A whole number of pounds. Also an `int`, and never a [Pence].
extension type const Pounds(int value) {
  Pence get inPence => Pence(value * 100);
}
// #endregion pounds

// #region receipt
/// A line a customer reads.
///
/// The parameter is a [Pence], so nothing else can be handed to it. The
/// version in `v1.dart` takes an `int`, and therefore takes anything.
String receiptFor(Pence amount) => 'You paid ${amount.asMoney}';
// #endregion receipt

// #region totals
/// Adding up amounts, without leaving the type.
///
/// The receiver is `Iterable<Pence>`, so this is study 12's `fold` reached
/// through a name that says what is being folded.
extension PenceTotals on Iterable<Pence> {
  Pence get total => Pence(fold(0, (sum, each) => sum + each.value));
}
// #endregion totals

// #region open
/// The same wrapper with the door left open.
///
/// `implements int` hands back every `int` member and makes the type
/// assignable to `int` again. 19.5 measures what it hands away.
extension type const OpenPence(int value) implements int {}
// #endregion open

// #region shadow
/// A type that already has a `name`.
class const Shop(final String name) {}

/// And an extension that also has one.
///
/// Two rules meet here and they disagree. Read 19.1 before guessing what
/// either line answers.
extension ShopNaming on Shop {
  String get name => 'the extension';

  String get sign => 'Welcome to $name';
}
// #endregion shadow
