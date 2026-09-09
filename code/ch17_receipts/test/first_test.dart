import 'package:ch17_receipts/receipts.dart';
import 'package:test/test.dart';

void main() {
  test('a receipt and a payslip share behaviour without sharing a parent', () {
    expect(Receipt(-2500, 6, 'grocer').signed(), '-2500');
    expect(Payslip(180000, 'acme').signed(), '+180000');
  });

  test('and neither is the other', () {
    expect(Receipt(-2500, 6, 'grocer'), isNot(isA<Payslip>()));
  });
}
