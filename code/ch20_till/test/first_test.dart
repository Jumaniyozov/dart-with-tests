import 'package:ch20_till/till.dart';
import 'package:test/test.dart';

void main() {
  test('reads an amount a person typed', () {
    expect(penceFrom('12.34'), 1234);
    expect(penceFrom('12'), 1200);
    expect(penceFrom('0.05'), 5);
  });

  test('and refuses text that is not one', () {
    expect(() => penceFrom('twelve'), throwsFormatException);
    expect(() => penceFrom('12.345'), throwsFormatException);
    expect(() => penceFrom(''), throwsFormatException);
  });
}
