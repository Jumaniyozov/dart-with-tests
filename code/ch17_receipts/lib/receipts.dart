// #region signed
/// Anything holding an amount in pence can say which way the money went.
///
/// A mixin cannot have a constructor and cannot hold the amount itself, so it
/// declares what it needs — `pence` — and leaves that to whoever mixes it in.
mixin Signed {
  int get pence;

  bool get isDebit => pence < 0;

  String get sign => isDebit ? '-' : '+';

  /// The amount without its direction, so [sign] is not printed twice.
  int get magnitude => pence.abs();

  String signed() => '$sign$magnitude';
}
// #endregion signed

// #region dated
/// Anything that happened on a day of the week can say which day.
mixin Dated {
  int get day;

  bool get isWeekend => day >= 6;

  String get dayName =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
}
// #endregion dated

// #region users
/// A shop receipt. Money out, on a day.
///
/// `Dated` reads a name out of a seven-element list, so a day outside 1..7
/// would crash it. Something has to promise that, and study 15 settled where:
/// a primary constructor cannot check anything, so a class that must check is
/// written out.
class Receipt with Signed, Dated {
  @override
  final int pence;

  @override
  final int day;

  final String shop;

  const new(this.pence, this.day, this.shop)
    : assert(day >= 1 && day <= 7, 'a day of the week is 1 to 7');
}

/// A payslip. Money in, and nothing to do with a receipt.
class const Payslip(@override final int pence, final String employer)
    with Signed {}
// #endregion users

// #region clash
mixin Titled {
  String get label => 'titled';
}

mixin Numbered {
  String get label => 'numbered';
}

class TitledFirst with Titled, Numbered {}

class NumberedFirst with Numbered, Titled {}
// #endregion clash

// #region chain
/// A line on a bill, before anything is applied to it.
abstract class Line {
  const new();

  int get base;

  int total() => base;
}

/// Takes a pound off. `on Line` says this may only be mixed into a [Line],
/// which is what lets it call `super.total()` at all.
mixin Discounted on Line {
  @override
  int total() => super.total() - 100;
}

/// Adds twenty per cent.
mixin Taxed on Line {
  @override
  int total() => (super.total() * 120) ~/ 100;
}

class const DiscountThenTax(@override final int base)
    extends Line
    with Discounted, Taxed {}

class const TaxThenDiscount(@override final int base)
    extends Line
    with Taxed, Discounted {}
// #endregion chain

// #region both
/// A `mixin class` works either way: mixed into another class, or built and
/// used on its own.
mixin class Rounding {
  int toNearest(int pence, int step) {
    assert(step > 0, 'rounding to a step of nothing is not a question');
    return ((pence + step ~/ 2) ~/ step) * step;
  }
}

class Till with Rounding {}
// #endregion both
