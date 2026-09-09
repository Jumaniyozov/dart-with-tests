// Stage 1: enough to add up a basket.
// #region total
int totalOf(List<int> prices) {
  var sum = 0;
  for (final price in prices) {
    sum += price;
  }
  return sum;
}
// #endregion total
