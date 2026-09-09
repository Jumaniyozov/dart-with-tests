// #region loose
/// A receipt line from study 4's world, where an amount in pence is an `int`
/// by convention and by nothing else.
///
/// The test beside this passes. That is the problem.
String receiptFor(int pence) =>
    'You paid £${pence ~/ 100}.${(pence % 100).toString().padLeft(2, '0')}';
// #endregion loose
