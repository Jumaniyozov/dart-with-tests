// Study 7 challenges.
//
// Each function below throws. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.
//
// All prices are whole pence, as in study 4.

/// 1. The lowest price in [prices]. An empty basket costs nothing, so
///    `cheapest([])` is `0`.
int cheapest(List<int> prices) {
  throw UnimplementedError('challenge 1');
}

/// 2. The same prices with every free item removed:
///    `withoutFree([250, 0, 180])` is `[250, 180]`.
///    The list you return must be a new one; do not change the one you were
///    given.
List<int> withoutFree(List<int> prices) {
  throw UnimplementedError('challenge 2');
}

/// 3. Add [deliveryPence] to the end of the basket, unless the basket already
///    totals [freeOver] or more:
///    `withDelivery([250, 180], 1000, 99)` is `[250, 180, 99]`, and
///    `withDelivery([900, 200], 1000, 99)` is `[900, 200]`.
List<int> withDelivery(List<int> prices, int freeOver, int deliveryPence) {
  throw UnimplementedError('challenge 3');
}
