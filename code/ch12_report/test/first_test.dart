import 'package:ch12_report/report.dart';
import 'package:test/test.dart';

void main() {
  test('the whole of study 10 total, in one line', () {
    expect(total([2500, -900, 0, -150, 400]), 1850);
  });

  test('and it still balances an empty ledger at nothing', () {
    expect(total([]), 0);
  });
}
