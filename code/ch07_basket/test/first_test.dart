import 'package:ch07_basket/basket.dart';
import 'package:test/test.dart';

void main() {
  test('adds up the prices in a basket', () {
    expect(totalOf([250, 180, 320]), 750);
  });
}
