import 'package:ch08_tally/tally.dart';
import 'package:test/test.dart';

void main() {
  test('counts how often each word appears', () {
    expect(tally(['red', 'blue', 'red']), {'red': 2, 'blue': 1});
  });
}
