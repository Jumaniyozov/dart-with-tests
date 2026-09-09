import 'money.dart';

// #region split
/// `Split` again, spelled the way every Dart file written before 3.13 spells
/// it: the class name repeated on each constructor.
class Split {
  final int pounds;
  final int pence;

  const Split(this.pounds, this.pence)
    : assert(pounds >= 0, 'a split describes an amount, not a direction'),
      assert(pence >= 0 && pence < 100, 'pence must be a part of a pound');

  factory Split.fromPence(int total) {
    assert(total >= 0, 'a split describes an amount, not a direction');
    return Split(total ~/ 100, total % 100);
  }

  Money get amount => Money(pounds * 100 + pence);
}
// #endregion split
