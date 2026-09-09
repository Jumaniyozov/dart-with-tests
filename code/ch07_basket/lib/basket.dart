// #region prices
/// The prices this shop always stocks, in pence.
///
/// `const`, so the list is built while the program is compiled and can never
/// be changed afterwards — not by this file and not by anyone it is handed to.
const standardPrices = [250, 180, 320];
// #endregion prices

/// Adds every price in [prices]. Pence in, pence out.
int totalOf(List<int> prices) {
  var sum = 0;
  for (final price in prices) {
    sum += price;
  }
  return sum;
}

// #region build
/// A basket of the standard prices, plus the extras the customer chose.
List<int> basket({bool deluxe = false, int deliveryPence = 0}) => [
  ...standardPrices,
  if (deluxe) 500,
  if (deliveryPence > 0) deliveryPence,
];
// #endregion build

// #region raised
/// Every price in [prices] raised by [percent], rounded down to the penny.
List<int> raisedBy(List<int> prices, int percent) => [
  for (final price in prices) price + (price * percent) ~/ 100,
];
// #endregion raised
