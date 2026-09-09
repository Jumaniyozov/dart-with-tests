import 'package:ch13_split/split.dart';
import 'package:test/test.dart';

void main() {
  test('hands back both halves of the amount at once', () {
    expect(splitPence(1234), (12, 34));
  });

  test('an amount under a pound is no pounds and the rest', () {
    expect(splitPence(7), (0, 7));
  });
}
