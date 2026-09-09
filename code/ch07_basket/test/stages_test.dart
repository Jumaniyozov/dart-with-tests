// Proves the intermediate stage printed in the study really runs.
import 'package:ch07_basket/v1.dart' as v1;
import 'package:test/test.dart';

void main() {
  test('stage 1 adds up a basket', () {
    expect(v1.totalOf([250, 180, 320]), 750);
    expect(v1.totalOf([]), 0);
  });
}
