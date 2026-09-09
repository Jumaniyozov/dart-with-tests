// Proves the intermediate stages printed in the study really run — including
// the one that is wrong. The drift is not a claim in the prose; it is asserted.
import 'package:ch04_money/v1.dart' as v1;
import 'package:ch04_money/v2.dart' as v2;
import 'package:test/test.dart';

void main() {
  test('stage 1 drifts away from the answer', () {
    expect(v1.total(0.1, 3), isNot(0.3));
    expect(v1.total(0.1, 3), 0.30000000000000004);
  });

  test('stage 2 counts whole pence and lands exactly', () {
    expect(v2.total(10, 3), 30);
  });
}
