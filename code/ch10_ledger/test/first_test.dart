import 'package:ch10_ledger/ledger.dart';
import 'package:test/test.dart';

void main() {
  test('adds a day of entries up', () {
    expect(total([2500, -900, -150]), 1450);
  });

  test('an empty ledger balances at nothing', () {
    expect(total([]), 0);
  });
}
