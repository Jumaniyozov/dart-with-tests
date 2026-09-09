import 'package:ch04_money/money.dart';
import 'package:test/test.dart';

void main() {
  test('three items at ten pence cost thirty pence', () {
    expect(total(10, 3), 30);
  });
}
