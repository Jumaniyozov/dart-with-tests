// Stage 1: the obvious version. A price is a decimal number, so `double`.
// This is wrong, and the test in the study proves it.
// #region total
double total(double price, int quantity) => price * quantity;
// #endregion total
