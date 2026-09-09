// #region digits
/// A first attempt at the column width: keep dividing until nothing is left.
int digitsIn(int pence) {
  var left = pence;
  var digits = 0;
  while (left > 0) {
    digits++;
    left ~/= 10;
  }
  return digits;
}
// #endregion digits
